import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../lib/services/api_service.dart';

import 'api_service_test.mocks.dart';

void main() {
  late ApiService apiService;
  late MockClient mockClient;

  setUp(() {
    mockClient = MockClient();
    apiService = ApiService();
  });

  group('ApiService', () {
    test('fetchPatientByCode returns a patient when the response is successful', () async {
      final uri = Uri.http('127.0.0.1:8000', '/patients', {'code': '12345'});
      final mockResponse = jsonEncode({
        "id": 1,
        "name": "John Doe",
        "age": 30,
        "gender": "male",
      });

      when(mockClient.get(uri)).thenAnswer(
        (_) async => http.Response(mockResponse, 200),
      );

      final patient = await apiService.fetchPatientByCode('12345');
      expect(patient, isNotNull);
      expect(patient!.name, 'John Doe');
    });

    test('fetchMedications returns a list of medications', () async {
      final patientId = 1;
      final uri = Uri.http('127.0.0.1:8000', '/patients/$patientId/medications');
      final mockResponse = jsonEncode([
        {"id": 1, "name": "Aspirin", "dosage": "100mg"},
        {"id": 2, "name": "Ibuprofen", "dosage": "200mg"},
      ]);

      when(mockClient.get(uri)).thenAnswer(
        (_) async => http.Response(mockResponse, 200),
      );

      final medications = await apiService.fetchMedications(patientId);
      expect(medications, isNotEmpty);
      expect(medications[0].name, 'Aspirin');
    });

    test('fetchPosologies returns a list of posologies with hours and minutes', () async {
      final patientId = 1;
      final medicationName = "Aspirin"; // Usando nombre en lugar de ID
      final uri = Uri.http(
        '127.0.0.1:8000',
        '/patients/$patientId/medications/$medicationName/posologies',
      );
      final mockResponse = jsonEncode([
        {"id": 1, "hours": 8, "minutes": 30},
        {"id": 2, "hours": 14, "minutes": 0},
      ]);

      when(mockClient.get(uri)).thenAnswer(
        (_) async => http.Response(mockResponse, 200),
      );

      final posologies = await apiService.fetchPosologies(patientId, medicationName);
      expect(posologies, isNotEmpty);
      expect(posologies[0].hour, 8);
      expect(posologies[0].minute, 30);
    });

    test('postIntake returns true when the response is successful', () async {
      final patientId = 1;
      final medicationName = "Ibuprofen"; // Usando nombre en lugar de ID
      final intakeDate = DateTime.now();
      final uri = Uri.http(
        '127.0.0.1:8000',
        '/patients/$patientId/medications/$medicationName/intakes',
      );

      when(mockClient.post(
        uri,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer(
        (_) async => http.Response('', 201),
      );

      final result = await apiService.postIntake(patientId, medicationName, intakeDate);
      expect(result, isTrue);
    });
  });
}
