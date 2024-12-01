import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/patient_app_state.dart';
import '../components/medication_card.dart';
import 'all_medications_view.dart';
import 'todays_medications_view.dart';
import 'package:src/models/posology.dart';

class ActiveMedicationsView extends StatelessWidget {
  const ActiveMedicationsView({Key? key}) : super(key: key);

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
                onTap: () {
                  Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const TodaysMedicationsView()));
                },
              ),
              ListTile(
                leading: const Icon(Icons.list),
                title: const Text('All Medications'),
                onTap: () {
                  Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const AllMedicationsView()));
                },
              ),
              ListTile(
                leading: const Icon(Icons.check_circle),
                title: const Text('Active Medications'),
                onTap: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<PatientAppState>(context);
    final activeMedications = appState.activeMedications;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Active Medications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => _changeView(context),
          ),
        ],
      ),
      body: activeMedications.isEmpty
          ? Center(
              child: Text(
                'No active medications',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            )
          : ListView.builder(
              itemCount: activeMedications.length,
              itemBuilder: (context, index) {
                final medication = activeMedications[index];
                return MedicationCard(
                  medication: medication,
                  showActiveChip: false, 
                  posologies: [], 
                  onPosologyTaken: (Posology posology) {},
                );
              },
            ),
    );
  }
}
