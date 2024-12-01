import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/patient_app_state.dart';
import '../models/posology.dart';
import '../services/api_service.dart';
import 'all_medications_view.dart';
import 'active_medications_view.dart';
import '../components/medication_card.dart';
import 'package:src/models/medication.dart';

class TodaysMedicationsView extends StatefulWidget {
  const TodaysMedicationsView({Key? key}) : super(key: key);

  @override
  _TodaysMedicationsViewState createState() => _TodaysMedicationsViewState();
}

class _TodaysMedicationsViewState extends State<TodaysMedicationsView> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, List<Posology>> _medicationPosologies = {};

  @override
  void initState() {
    super.initState();
    _loadTodaysMedications();
  }

  Future<void> _loadTodaysMedications() async {
    final appState = Provider.of<PatientAppState>(context, listen: false);
    final patient = appState.currentPatient;
    if (patient == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = "No patient data available.";
      });
      return;
    }

    try {
      final activeMedications = appState.activeMedications;
      final todaysMedications = <Medication>[];
      final medicationPosologies = <String, List<Posology>>{};  // Usamos el nombre como `String` para las posologías

      for (final medication in activeMedications) {
        try {
          final posologies = await _apiService.fetchPosologies(patient.id, medication.name);  // Usamos `medication.name` como `String`
          final todayPosologies = posologies.where((posology) => _isPosologyForToday(posology)).toList();
          if (todayPosologies.isNotEmpty) {
            todaysMedications.add(medication);
            medicationPosologies[medication.name] = todayPosologies;  // Guardamos las posologías con el nombre
          }
        } catch (e) {
          print('Error fetching posologies for medication ${medication.name}: $e');
        }
      }

      appState.setTodaysMedications(todaysMedications);
      setState(() {
        _isLoading = false;
        _medicationPosologies = medicationPosologies;
      });
    } catch (e) {
      print('Error loading today\'s medications: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = "Failed to load today's medications. Please try again later.";
      });
    }
  }

  bool _isPosologyForToday(Posology posology) {
    final now = DateTime.now();
    return now.hour <= posology.hour;
  }

  void _changeView(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('Today\'s Medications'),
                onTap: () => Navigator.of(context).pop(),
              ),
              ListTile(
                leading: const Icon(Icons.list),
                title: const Text('All Medications'),
                onTap: () {
                  Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const AllMedicationsView()));
                },
              ),
              ListTile(
                leading: const Icon(Icons.check_circle),
                title: const Text('Active Medications'),
                onTap: () {
                  Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const ActiveMedicationsView()));
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _markPosologyAsTaken(Medication medication, Posology posology) async {
    final appState = Provider.of<PatientAppState>(context, listen: false);
    final patient = appState.currentPatient;
    if (patient == null) return;

    try {
      final now = DateTime.now();
      final intakeDate = DateTime(now.year, now.month, now.day, posology.hour, posology.minute);
      final success = await _apiService.postIntake(patient.id, medication.name, intakeDate);  // Usamos `medication.name` como `String`

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Intake recorded for ${medication.name}')),
        );
        setState(() {
          _medicationPosologies[medication.name]?.remove(posology);
          if (_medicationPosologies[medication.name]?.isEmpty ?? true) {
            _medicationPosologies.remove(medication.name);
          }
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to record intake.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error marking medication as taken.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<PatientAppState>(context);
    final activeMedications = appState.activeMedications;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Today's Medications"),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => _changeView(context),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : ListView.builder(
                  itemCount: activeMedications.length,
                  itemBuilder: (context, index) {
                    final medication = activeMedications[index];
                    final posologies = _medicationPosologies[medication.name] ?? [];
                    return MedicationCard(
                      medication: medication,
                      posologies: posologies,
                      onPosologyTaken: (posology) => _markPosologyAsTaken(medication, posology),
                    );
                  },
                ),
    );
  }
}
