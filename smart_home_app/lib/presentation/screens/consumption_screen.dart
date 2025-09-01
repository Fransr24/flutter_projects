import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smart_home_app/presentation/widgets/consumption_chart.dart';

class ConsumptionScreen extends StatefulWidget {
  const ConsumptionScreen({super.key});

  @override
  State<ConsumptionScreen> createState() => _ConsumptionScreenState();
}

class _ConsumptionScreenState extends State<ConsumptionScreen> {
  List<dynamic> consumption = [];

  @override
  void initState() {
    super.initState();
    _fetchConsumption();
  }

  Future<void> _fetchConsumption() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('consumo')
              .doc(FirebaseAuth.instance.currentUser!.uid)
              .collection('registros')
              .orderBy(FieldPath.documentId)
              .get();

      final deviceNames =
          snapshot.docs
              .map((doc) => {'fecha': doc.id, 'potencia': doc['potencia']})
              .toList();

      setState(() {
        consumption = deviceNames;
      });
    } catch (error) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error obteniendo data")));
    }
  }

  Future<void> _addConsumption() async {
    final dateController = TextEditingController();
    final potenciaController = TextEditingController();

    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Agregar consumo"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () async {
                    final now = DateTime.now();
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: now,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) {
                      setState(() {
                        dateController.text =
                            "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                      });
                    }
                  },
                  child: AbsorbPointer(
                    child: TextField(
                      controller: dateController,
                      decoration: const InputDecoration(
                        labelText: "Seleccionar fecha",
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                    ),
                  ),
                ),
                TextField(
                  controller: potenciaController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "Potencia consumida en kWh",
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancelar"),
              ),
              ElevatedButton(
                onPressed: () async {
                  final fecha = dateController.text;
                  final potencia = potenciaController.text;

                  if (fecha.isEmpty || potencia.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Ingresar fecha y potencia consumida"),
                      ),
                    );
                  }
                  final potuint = double.tryParse(potencia);
                  if (potuint == null || potuint <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Ingresar solamente numeros positivos"),
                      ),
                    );
                  }
                  try {
                    final docRef = FirebaseFirestore.instance
                        .collection('consumo')
                        .doc(FirebaseAuth.instance.currentUser!.uid)
                        .collection('registros')
                        .doc(fecha);

                    final docSnapshot = await docRef.get();

                    if (docSnapshot.exists) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            "El consumo de potencia para esa fecha ya fue establecido",
                          ),
                        ),
                      );
                    } else {
                      docRef.set({'potencia': potencia});

                      Navigator.pop(context);
                      _fetchConsumption();
                    }
                  } catch (error) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Error agregando registro")),
                    );
                  }
                },
                child: const Text("Guardar"),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Consumo Diario")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ConsumptionChart(consumptions: consumption),
          ),
          const SizedBox(height: 10),
          Expanded(
            child:
                consumption.isEmpty
                    ? const Center(child: Text("Agregue sus consumos"))
                    : ListView.builder(
                      itemCount: consumption.length,
                      itemBuilder: (context, index) {
                        final consumo = consumption[index];

                        return ListTile(
                          title: Text("Fecha: ${consumo['fecha']}"),
                          subtitle: Text(
                            "Potencia: ${consumo['potencia']} kWh",
                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () async {
                              final uid =
                                  FirebaseAuth.instance.currentUser!.uid;
                              showDialog(
                                context: context,
                                builder:
                                    (context) => AlertDialog(
                                      title: Text("Eliminando modulo elemento"),
                                      content: Text(
                                        "¿Estas seguro que quieres eliminar este elemento?",
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed:
                                              () => Navigator.of(context).pop(),
                                          child: Text("No"),
                                        ),
                                        TextButton(
                                          onPressed: () async {
                                            await FirebaseFirestore.instance
                                                .collection('consumo')
                                                .doc(uid)
                                                .collection('registros')
                                                .doc(consumo['fecha'])
                                                .delete();

                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  "Elemento eliminado",
                                                ),
                                              ),
                                            );
                                            setState(() {});
                                            _fetchConsumption();
                                            Navigator.of(context).pop();
                                          },
                                          child: Text("Si"),
                                        ),
                                      ],
                                    ),
                              );
                            },
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addConsumption,
        backgroundColor: Colors.yellow,
        tooltip: 'Agregar nuevo consumo',
        child: const Icon(Icons.add),
      ),
    );
  }
}
