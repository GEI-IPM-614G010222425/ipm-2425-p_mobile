import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/posology.dart';
import '../models/patient.dart';
import '../models/medication.dart';

class ApiService {
  final String serverUrl = Platform.isAndroid ? "192.168.0.33" : "127.0.0.1";
  final String serverPort = "8000";

  Future<Patient?> fetchPatientByCode(String code) async {
    final uri = Uri.http("$serverUrl:$serverPort", "/patients", {"code": code});
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data.isNotEmpty ? Patient.fromJson(data) : null;
    }
    throw Exception("Error fetching patient by code");
  }

  Future<List<Medication>> fetchMedications(int patientId, {int? count}) async {
    final uri = Uri.http("$serverUrl:$serverPort", "/patients/$patientId/medications",
        count != null ? {'count': "$count"} : null);
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      final data = json.decode(response.body) as List;
      return data.map((item) => Medication.fromJson(item)).toList();
    }
    throw Exception("Error fetching medications");
  }

  Future<Map<String, List<Posology>>> fetchPosologiesForMedications(int patientId) async {
    // Obtenemos todos los medicamentos del paciente
    final medications = await fetchMedications(patientId);

    final Map<String, List<Posology>> medicationPosologies = {};

    // Recorremos los medicamentos y obtenemos las posologías
    for (var medication in medications) {
      final posologies = await fetchPosologies(patientId, medication.name);  // Cambié `medication.id` por `medication.name`
      medicationPosologies[medication.name] = posologies;  // Usamos el nombre de la medicación como key
    }

    return medicationPosologies;
  }

  Future<List<Posology>> fetchPosologies(int patientId, String medicationName) async {  // Cambié el tipo de `medicationId` a `String`
    final uri = Uri.http("$serverUrl:$serverPort", "/patients/$patientId/medications/$medicationName/posologies");
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List && data.isNotEmpty) {
          return List<Posology>.from(data.map((item) => Posology.fromJson(item)));
        } else {
          throw Exception("No posologies found for the given parameters.");
        }
      } else {
        throw Exception("Error fetching posologies: HTTP ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Failed to fetch posologies: $e");
    }
  }

  Future<bool> postIntake(int patientId, String medicationName, DateTime intakeDate) async {  // Cambié el tipo de `medicationId` a `String`
    final uri = Uri.http("$serverUrl:$serverPort", "/patients/$patientId/medications/$medicationName/intakes");
    final formattedDate = "${intakeDate.year}-${intakeDate.month.toString().padLeft(2, '0')}-${intakeDate.day.toString().padLeft(2, '0')}T${intakeDate.hour.toString().padLeft(2, '0')}:${intakeDate.minute.toString().padLeft(2, '0')}";
    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'date': intakeDate.toIso8601String(),
        'medication_name': medicationName,  // Cambié `medicationId` por `medicationName`
      }),
    );

    if (response.statusCode == 201) {
      return true;
    } else {
      throw Exception('Failed to post intake: ${response.body}');
    }
  }
}
