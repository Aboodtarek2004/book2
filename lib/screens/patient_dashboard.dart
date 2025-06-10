import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:table_calendar/table_calendar.dart';

class PatientDashboard extends StatefulWidget {
  const PatientDashboard({super.key});

  @override
  State<PatientDashboard> createState() => _PatientDashboardState();
}

class _PatientDashboardState extends State<PatientDashboard> {
  DateTime _selectedDate = DateTime.now();
  String? _service;
  String? _doctorId;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text('Patient Dashboard')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome, ${user?.email ?? ''}',
                style: Theme.of(context).textTheme.headline6,
              ),
              const SizedBox(height: 16),
              Text('Available Doctors',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('doctors')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final docs = snapshot.data!.docs;
                  return Column(
                    children: docs.map((d) {
                      final data = d.data() as Map<String, dynamic>;
                      return RadioListTile<String>(
                        value: d.id,
                        groupValue: _doctorId,
                        onChanged: (value) {
                          setState(() {
                            _doctorId = value;
                          });
                        },
                        title: Text(data['name'] ?? ''),
                        subtitle: Text(data['specialization'] ?? ''),
                      );
                    }).toList(),
                  );
                },
              ),

              const SizedBox(height: 16),
              TableCalendar(
                focusedDay: _selectedDate,
                firstDay: DateTime.now(),
                lastDay: DateTime.now().add(const Duration(days: 365)),
                selectedDayPredicate: (day) => isSameDay(day, _selectedDate),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDate = selectedDay;
                  });
                },
              ),
              const SizedBox(height: 16),
              DropdownButton<String>(
                value: _service,
                hint: const Text('Select service'),
                items: const [
                  DropdownMenuItem(value: 'consultation', child: Text('Consultation')),
                  DropdownMenuItem(value: 'checkup', child: Text('Checkup')),
                ],
                onChanged: (value) {
                  setState(() {
                    _service = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: (_doctorId != null && _service != null)
                    ? () async {
                        await FirebaseFirestore.instance
                            .collection('appointments')
                            .add({
                          'date': _selectedDate,
                          'service': _service,
                          'patientId': user?.uid,
                          'doctorId': _doctorId,
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Appointment booked')),
                        );
                      }
                    : null,
                child: const Text('Book Appointment'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
