import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:smart_home_app/core/utils/utils.dart';
import 'package:smart_home_app/presentation/widgets/air_config_creation.dart';
import 'package:smart_home_app/presentation/widgets/device_appbar.dart';
import 'package:smart_home_app/presentation/widgets/modals/eddit_air_config_modal.dart';

class AirConditioningScreen extends StatefulWidget {
  const AirConditioningScreen({super.key});

  @override
  State<AirConditioningScreen> createState() => _AirConditioningScreenState();
}

class _AirConditioningScreenState extends State<AirConditioningScreen> {
  String selectedAirConditioning = 'air';
  bool isairConditioningOn = false;
  String? selectedTime;
  int? timerMinutes;
  int? _visualMode;
  bool _modeSaving = false;
  bool _switchLocked = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: DeviceAppBar(
        type: DeviceType.aire,
        selectedDevice: selectedAirConditioning,
        onDevChanged: (newairConditioning) {
          setState(() {
            selectedAirConditioning = newairConditioning;
          });
        },
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              StreamBuilder<DatabaseEvent>(
                stream: FirebaseDatabase.instance.ref("air/$selectedAirConditioning").onValue,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(height: 260, child: Center(child: CircularProgressIndicator()));
                  }

                  final rawValue = snapshot.hasData ? snapshot.data!.snapshot.value : null;
                  final Map<dynamic, dynamic> data = (rawValue is Map) ? Map<dynamic, dynamic>.from(rawValue) : <dynamic, dynamic>{};

                  final dynamic rawIsOn = data['On'];
                  bool isOn = (rawIsOn == true) || (rawIsOn?.toString().toLowerCase() == 'true');

                  final sensorTempText = (data['SensorTemp'] ?? '--').toString();

                  final acTempText = (data['AcTemp'] ?? '--').toString();
                  final String fan = data['Speed']?.toString() ?? '-';
                  final String mode = data['Mode']?.toString() ?? '-';
                  final String swing = data['Swing']?.toString() ?? '-';
                  final String timeOn = data['TimeOn']?.toString() ?? '';
                  final String timeOff = data['TimeOff']?.toString() ?? '';
                  final String isOnText = isOn ? 'Encendido' : 'Apagado';
                  final Color isOnColor = isOn ? Colors.green : Colors.red;
                  final Color isOnBackgroundColor = isOn ? Colors.green.shade50 : Colors.red.shade50;

                  final modeList = ["Calor", "Frío"];

                  int modeIndex = int.tryParse(mode.toString()) ?? 0;
                  if (modeIndex < 0 || modeIndex >= modeList.length) modeIndex = 0;

                  final noData = data.isEmpty;
                  if (noData) {
                    return Center(
                      child: Card(
                        elevation: 6,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                        color: Colors.blue.shade50,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 28.0, horizontal: 20.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.air_outlined, size: 70, color: Colors.blue.shade400),
                              const SizedBox(height: 16),
                              const Text(
                                "Sin módulos de aire conectados",
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                "No se encontraron lecturas del aire acondicionado.\nVerificá que el dispositivo esté encendido y que pertenezca a la red.",
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 14, color: Colors.black54, height: 1.4),
                              ),
                              const SizedBox(height: 18),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: () async {
                                      try {
                                        await FirebaseDatabase.instance.ref("air/$selectedAirConditioning").get();
                                        setState(() {});
                                      } catch (_) {}
                                    },
                                    icon: const Icon(Icons.refresh),
                                    label: const Text("Reintentar"),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  final int currentModeVal = int.tryParse(mode.toString()) ?? 1; // 1 = Calor, 2 = Frío
                  _visualMode ??= currentModeVal;

                  final MaterialColor coldColor = Colors.lightBlue;
                  final MaterialColor hotColor = Colors.deepOrange;
                  String? _timeOnMode; // 'frio' | 'calor' | null — se usa solo para mostrar en UI

                  // Si llegamos acá hay datos
                  return Column(
                    children: [
                      const SizedBox(height: 20),
                      const Text("Temperatura actual:", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      Text(
                        "$sensorTempText °C",
                        style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
                      ),
                      const SizedBox(height: 8),
                      Chip(
                        label: Text(isOnText, style: TextStyle(color: isOnColor)),
                        backgroundColor: isOnBackgroundColor,
                        avatar: Icon(Icons.power, color: isOnColor),
                      ),
                      const SizedBox(height: 24),

                      Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Encender/Apagar', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500)),
                              Row(
                                children: [
                                  if (_switchLocked) ...[
                                    const SizedBox(width: 8),
                                    SizedBox(height: 18, width: 18, child: const CircularProgressIndicator(strokeWidth: 2)),
                                  ],
                                  const SizedBox(width: 8),
                                  Switch(
                                    value: isOn,
                                    onChanged:
                                        _switchLocked
                                            ? null
                                            : (value) async {
                                              setState(() {
                                                isOn = value;
                                                _switchLocked = true;
                                              });

                                              try {
                                                await FirebaseDatabase.instance.ref("air/$selectedAirConditioning").update({'On': value});
                                              } catch (e) {
                                                if (mounted) {
                                                  setState(() {
                                                    isOn = !value;
                                                    _switchLocked = false;
                                                  });
                                                }
                                                await showAlertDialog(
                                                  context: context,
                                                  title: 'Error actualizando el estado del dispositivo',
                                                  message: 'No se pudo cambiar el estado de encendido de la luz',
                                                );
                                                return;
                                              }

                                              Future.delayed(const Duration(seconds: 3), () {
                                                if (mounted) setState(() => _switchLocked = false);
                                              });
                                            },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Center(
                                      child: const Text(
                                        'Modo',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  ),
                                  if (_modeSaving) const SizedBox(width: 8),
                                  if (_modeSaving) const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                                ],
                              ),

                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: InkWell(
                                      onTap:
                                          _modeSaving
                                              ? null
                                              : () async {
                                                final int newMode = 1;
                                                if (_visualMode == newMode) return;
                                                setState(() => _visualMode = newMode);
                                                setState(() => _modeSaving = true);
                                                try {
                                                  await FirebaseDatabase.instance.ref("air/$selectedAirConditioning").update({
                                                    'Mode': newMode,
                                                  });
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(const SnackBar(content: Text('Modo cambiado a CALOR')));
                                                } catch (e) {
                                                  setState(() => _visualMode = currentModeVal);
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(const SnackBar(content: Text('Error actualizando el modo')));
                                                } finally {
                                                  if (mounted) setState(() => _modeSaving = false);
                                                }
                                              },
                                      borderRadius: BorderRadius.circular(12),
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 220),
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        decoration: BoxDecoration(
                                          color: (_visualMode == 1) ? hotColor.withOpacity(0.12) : Colors.grey.shade50,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: (_visualMode == 1) ? hotColor.withOpacity(0.9) : Colors.grey.shade200,
                                            width: (_visualMode == 1) ? 1.6 : 1,
                                          ),
                                        ),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            CircleAvatar(
                                              radius: 18,
                                              backgroundColor: (_visualMode == 1) ? hotColor : Colors.grey.shade100,
                                              child: Icon(
                                                Icons.local_fire_department,
                                                color: (_visualMode == 1) ? Colors.white : hotColor,
                                                size: 18,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              'Calor',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                color: (_visualMode == 1) ? hotColor.shade700 : Colors.black87,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            if (_visualMode == 1)
                                              Text('Activo', style: TextStyle(fontSize: 12, color: hotColor.shade700))
                                            else
                                              const SizedBox.shrink(),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: InkWell(
                                      onTap:
                                          _modeSaving
                                              ? null
                                              : () async {
                                                final int newMode = 2;
                                                if (_visualMode == newMode) return;
                                                setState(() => _visualMode = newMode);
                                                setState(() => _modeSaving = true);
                                                try {
                                                  await FirebaseDatabase.instance.ref("air/$selectedAirConditioning").update({
                                                    'Mode': newMode,
                                                  });
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(const SnackBar(content: Text('Modo cambiado a FRÍO')));
                                                } catch (e) {
                                                  setState(() => _visualMode = currentModeVal);
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(const SnackBar(content: Text('Error actualizando el modo')));
                                                } finally {
                                                  if (mounted) setState(() => _modeSaving = false);
                                                }
                                              },
                                      borderRadius: BorderRadius.circular(12),
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 220),
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        decoration: BoxDecoration(
                                          color: (_visualMode == 2) ? coldColor.withOpacity(0.12) : Colors.grey.shade50,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: (_visualMode == 2) ? coldColor.withOpacity(0.9) : Colors.grey.shade200,
                                            width: (_visualMode == 2) ? 1.6 : 1,
                                          ),
                                        ),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            CircleAvatar(
                                              radius: 18,
                                              backgroundColor: (_visualMode == 2) ? coldColor : Colors.grey.shade100,
                                              child: Icon(Icons.ac_unit, color: (_visualMode == 2) ? Colors.white : coldColor, size: 18),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              'Frío',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                color: (_visualMode == 2) ? coldColor.shade700 : Colors.black87,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            if (_visualMode == 2)
                                              Text('Activo', style: TextStyle(fontSize: 12, color: coldColor.shade700))
                                            else
                                              const SizedBox.shrink(),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Config card
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Text("Configuración del dispositivo:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                                  IconButton(
                                    onPressed: () {
                                      try {
                                        final String acTempStr = acTempText.toString();
                                        final String fanStr = fan.toString();
                                        final String swingStr = swing.toString();

                                        final int acTempVal = int.tryParse(acTempStr) ?? 24;
                                        final int fanVal = int.tryParse(fanStr) ?? 1;

                                        final bool swingVal = (swing is bool) ? (swing as bool) : (swingStr.toLowerCase() == 'true');

                                        showEditAirConfigModal(context, selectedAirConditioning, acTempVal, fanVal, swingVal);
                                      } catch (e) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(SnackBar(content: Text('Error abriendo configuración: $e')));
                                      }
                                    },
                                    icon: const Icon(Icons.edit),
                                    tooltip: "Editar configuración",
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 12,
                                runSpacing: 8,
                                children: [
                                  Chip(label: Text("T°: $acTempText °C")),
                                  Chip(label: Text("FAN: $fan")),
                                  Chip(
                                    label: Text(
                                      "Swing: ${((swing is bool) ? (swing as bool) : (swing.toString().toLowerCase() == 'true')) ? 'Activado' : 'Desactivado'}",
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Horario On
                      const SizedBox(height: 16),

                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isWide = constraints.maxWidth > 520;

                          // Helpers para parsear time+mode si existe (ej: "20:14:1")
                          String _displayTime(String raw) {
                            if (raw.isEmpty) return '';
                            final parts = raw.split(':');
                            if (parts.length >= 3 && (parts.last == '1' || parts.last == '2')) {
                              return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
                            }
                            // si no tiene sufijo, devolvemos como estaba
                            return raw;
                          }

                          String? _modeLabelFromRaw(String raw) {
                            if (raw.isEmpty) return null;
                            final parts = raw.split(':');
                            if (parts.length >= 3) {
                              final suffix = parts.last;
                              if (suffix == '1') return 'Calor';
                              if (suffix == '2') return 'Frío';
                            }
                            return null;
                          }

                          Widget scheduleCard({
                            required IconData icon,
                            required String title,
                            required String currentValueRaw,
                            required Future<void> Function() onPick,
                            required Future<void> Function() onClear,
                            required Color accent,
                            bool showModeIndicator = false,
                          }) {
                            final display = _displayTime(currentValueRaw);
                            final modeLabel = _modeLabelFromRaw(currentValueRaw);

                            return Card(
                              elevation: 3,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                child: Row(
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(color: accent.withOpacity(0.12), shape: BoxShape.circle),
                                      padding: const EdgeInsets.all(10),
                                      child: Icon(icon, color: accent, size: 22),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                                              ),
                                              if (showModeIndicator && modeLabel != null)
                                                Chip(
                                                  label: Text(modeLabel, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                                  backgroundColor:
                                                      (modeLabel == 'Frío') ? Colors.lightBlue.shade50 : Colors.deepOrange.shade50,
                                                  labelPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            display.isNotEmpty ? '$display hrs' : 'Sin programación',
                                            style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                                          ),
                                          if (showModeIndicator && modeLabel != null)
                                            Padding(
                                              padding: const EdgeInsets.only(top: 6),
                                              child: Text(
                                                'Configurado para modo $modeLabel',
                                                style: const TextStyle(fontSize: 12, color: Colors.black54),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        OutlinedButton.icon(
                                          icon: const Icon(Icons.schedule),
                                          label: const Text('Seleccionar'),
                                          style: OutlinedButton.styleFrom(minimumSize: const Size(140, 44)),
                                          onPressed: onPick,
                                        ),
                                        const SizedBox(height: 6),
                                        TextButton.icon(
                                          onPressed: currentValueRaw.isNotEmpty ? onClear : null,
                                          icon: const Icon(Icons.delete_outline, size: 18),
                                          label: const Text('Borrar'),
                                          style: TextButton.styleFrom(minimumSize: const Size(80, 36)),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          Future<void> _pickTimeAndSave(String field) async {
                            String? chosenModeSuffix;
                            if (field == 'TimeOn') {
                              final chosenMode = await showDialog<String?>(
                                context: context,
                                builder:
                                    (cctx) => SimpleDialog(
                                      title: const Text('Seleccionar modo para horario de encendido'),
                                      children: [
                                        SimpleDialogOption(
                                          onPressed: () => Navigator.pop(cctx, '1'),
                                          child: Row(
                                            children: [
                                              Icon(Icons.local_fire_department, color: Colors.deepOrange),
                                              const SizedBox(width: 8),
                                              const Text('Calor'),
                                            ],
                                          ),
                                        ),
                                        SimpleDialogOption(
                                          onPressed: () => Navigator.pop(cctx, '2'),
                                          child: Row(
                                            children: [
                                              Icon(Icons.ac_unit, color: Colors.lightBlue),
                                              const SizedBox(width: 8),
                                              const Text('Frío'),
                                            ],
                                          ),
                                        ),
                                        SimpleDialogOption(onPressed: () => Navigator.pop(cctx, null), child: const Text('Cancelar')),
                                      ],
                                    ),
                              );

                              if (chosenMode == null) return; // canceló selección de modo
                              chosenModeSuffix = chosenMode;
                            }
                            if (field == 'TimeOff') {
                              chosenModeSuffix = "3";
                            }
                            final TimeOfDay? picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                            if (picked == null) return;

                            final formatted = "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";

                            final toSave = '$formatted:$chosenModeSuffix';

                            try {
                              await FirebaseDatabase.instance.ref("air/$selectedAirConditioning").update({field: toSave});
                              if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Horario guardado')));
                            } catch (e) {
                              await showAlertDialog(
                                context: context,
                                title: 'Error',
                                message: 'No se pudo guardar la programación. Intente nuevamente.',
                              );
                            }
                          }

                          Future<void> _clearTime(String field) async {
                            final confirm =
                                await showDialog<bool>(
                                  context: context,
                                  builder:
                                      (ctx) => AlertDialog(
                                        title: const Text('Borrar programación'),
                                        content: const Text('¿Desea eliminar esta programación?'),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
                                          ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Eliminar')),
                                        ],
                                      ),
                                ) ??
                                false;
                            if (!confirm) return;
                            try {
                              await FirebaseDatabase.instance.ref("air/$selectedAirConditioning").update({field: ''});
                              if (mounted)
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Programación eliminada')));
                            } catch (e) {
                              await showAlertDialog(
                                context: context,
                                title: 'Error',
                                message: 'No se pudo borrar la programación. Intente nuevamente.',
                              );
                            }
                          }

                          final onCard = scheduleCard(
                            icon: Icons.power_settings_new,
                            title: 'Horario de encendido',
                            currentValueRaw: timeOn,
                            onPick: () => _pickTimeAndSave('TimeOn'),
                            onClear: () => _clearTime('TimeOn'),
                            accent: Colors.green,
                            showModeIndicator: true,
                          );

                          final offCard = scheduleCard(
                            icon: Icons.power_off,
                            title: 'Horario de apagado',
                            currentValueRaw: timeOff,
                            onPick: () => _pickTimeAndSave('TimeOff'),
                            onClear: () => _clearTime('TimeOff'),
                            accent: Colors.redAccent,
                            showModeIndicator: false,
                          );

                          if (isWide) {
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [Expanded(child: onCard), const SizedBox(width: 12), Expanded(child: offCard)],
                            );
                          } else {
                            return Column(children: [onCard, const SizedBox(height: 12), offCard]);
                          }
                        },
                      ),

                      const SizedBox(height: 12),

                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isWide = constraints.maxWidth > 520;
                          Future<void> _openTempEditor({
                            required BuildContext ctx,
                            required String fieldKey,
                            required int initialValue,
                            required int minAllowed,
                            required int maxAllowed,
                            required int? otherValue,
                          }) async {
                            int temp = initialValue.clamp(minAllowed, maxAllowed);
                            final controller = TextEditingController(text: temp.toString());

                            await showModalBottomSheet(
                              context: ctx,
                              isScrollControlled: true,
                              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
                              builder: (sheetCtx) {
                                return StatefulBuilder(
                                  builder: (sctx, setS) {
                                    void _setTemp(int v) {
                                      setS(() {
                                        temp = v.clamp(minAllowed, maxAllowed);
                                        controller.text = temp.toString();
                                      });
                                    }

                                    Future<void> _save() async {
                                      final parsed = int.tryParse(controller.text);
                                      if (parsed == null) {
                                        ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Valor inválido')));
                                        return;
                                      }
                                      int toSave = parsed.clamp(minAllowed, maxAllowed);

                                      if (fieldKey == 'TempMin' && otherValue != null && toSave > otherValue) {
                                        await showDialog(
                                          context: sheetCtx,
                                          builder:
                                              (dctx) => AlertDialog(
                                                title: const Text('Valor no válido'),
                                                content: Text('La temperatura mínima no puede ser mayor que la máxima ($otherValue °C).'),
                                                actions: [
                                                  TextButton(onPressed: () => Navigator.of(dctx).pop(), child: const Text('Aceptar')),
                                                ],
                                              ),
                                        );
                                        return;
                                      }
                                      if (fieldKey == 'TempMax' && otherValue != null && toSave < otherValue) {
                                        await showDialog(
                                          context: sheetCtx,
                                          builder:
                                              (dctx) => AlertDialog(
                                                title: const Text('Valor no válido'),
                                                content: Text('La temperatura máxima no puede ser menor que la mínima ($otherValue °C).'),
                                                actions: [
                                                  TextButton(onPressed: () => Navigator.of(dctx).pop(), child: const Text('Aceptar')),
                                                ],
                                              ),
                                        );
                                        return;
                                      }

                                      try {
                                        await FirebaseDatabase.instance.ref("air/$selectedAirConditioning").update({fieldKey: toSave});
                                        if (mounted) ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Guardado')));
                                        Navigator.of(sheetCtx).pop();
                                      } catch (e) {
                                        await showAlertDialog(
                                          context: ctx,
                                          title: 'Error',
                                          message: 'No se pudo guardar la temperatura. Intente nuevamente.',
                                        );
                                      }
                                    }

                                    return Padding(
                                      padding: EdgeInsets.only(bottom: MediaQuery.of(sheetCtx).viewInsets.bottom),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              fieldKey == 'TempMin' ? 'Establecer temperatura mínima' : 'Establecer temperatura máxima',
                                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              'Rango permitido: $minAllowed° - $maxAllowed°',
                                              style: TextStyle(color: Colors.grey.shade700),
                                            ),
                                            const SizedBox(height: 12),

                                            Slider(
                                              min: minAllowed.toDouble(),
                                              max: maxAllowed.toDouble(),
                                              divisions: maxAllowed - minAllowed,
                                              value: temp.toDouble(),
                                              label: '$temp°',
                                              onChanged: (v) => _setTemp(v.round()),
                                            ),

                                            const SizedBox(height: 8),

                                            Row(
                                              children: [
                                                IconButton(onPressed: () => _setTemp(temp - 1), icon: const Icon(Icons.remove)),
                                                Expanded(
                                                  child: TextField(
                                                    controller: controller,
                                                    keyboardType: TextInputType.number,
                                                    textAlign: TextAlign.center,
                                                    decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                                                    onChanged: (v) {
                                                      final p = int.tryParse(v);
                                                      if (p != null) setS(() => temp = p.clamp(minAllowed, maxAllowed));
                                                    },
                                                  ),
                                                ),
                                                IconButton(onPressed: () => _setTemp(temp + 1), icon: const Icon(Icons.add)),
                                              ],
                                            ),

                                            const SizedBox(height: 12),
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: OutlinedButton(
                                                    onPressed: () {
                                                      Navigator.of(sheetCtx).pop();
                                                    },
                                                    child: const Text('Cancelar'),
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(child: ElevatedButton(onPressed: _save, child: const Text('Guardar'))),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            );
                          }

                          Widget tempCard({
                            required String title,
                            required IconData icon,
                            required String fieldKey,
                            required int? currentValue,
                            required int? otherValue,
                            required Color accent,
                          }) {
                            return Card(
                              elevation: 3,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                child: Row(
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(color: accent.withOpacity(0.12), shape: BoxShape.circle),
                                      padding: const EdgeInsets.all(10),
                                      child: Icon(icon, color: accent, size: 22),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                                          const SizedBox(height: 6),
                                          Text(
                                            ((currentValue != null) && currentValue.abs() != 200)
                                                ? 'Actual: $currentValue °C'
                                                : 'Sin configuración',
                                            style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        OutlinedButton.icon(
                                          icon: const Icon(Icons.edit),
                                          label: const Text('Editar'),
                                          style: OutlinedButton.styleFrom(minimumSize: const Size(120, 44)),
                                          onPressed: () {
                                            _openTempEditor(
                                              ctx: context,
                                              fieldKey: fieldKey,
                                              initialValue: currentValue ?? (fieldKey == 'TempMin' ? 18 : 30),
                                              minAllowed: 5,
                                              maxAllowed: 40,
                                              otherValue: otherValue,
                                            );
                                          },
                                        ),
                                        const SizedBox(height: 8),
                                        TextButton.icon(
                                          onPressed:
                                              ((currentValue != null) && currentValue.abs() != 200)
                                                  ? () async {
                                                    final confirm =
                                                        await showDialog<bool>(
                                                          context: context,
                                                          builder:
                                                              (c) => AlertDialog(
                                                                title: const Text('Borrar configuración'),
                                                                content: const Text('¿Desea eliminar esta configuración?'),
                                                                actions: [
                                                                  TextButton(
                                                                    onPressed: () => Navigator.of(c).pop(false),
                                                                    child: const Text('Cancelar'),
                                                                  ),
                                                                  ElevatedButton(
                                                                    onPressed: () => Navigator.of(c).pop(true),
                                                                    child: const Text('Eliminar'),
                                                                  ),
                                                                ],
                                                              ),
                                                        ) ??
                                                        false;
                                                    if (!confirm) return;
                                                    try {
                                                      late int value;
                                                      if (fieldKey == "TempMin") {
                                                        value = -200;
                                                      } else {
                                                        value = 200;
                                                      }
                                                      await FirebaseDatabase.instance.ref("air/$selectedAirConditioning").update({
                                                        fieldKey: value,
                                                      });
                                                      if (mounted) {
                                                        ScaffoldMessenger.of(
                                                          context,
                                                        ).showSnackBar(const SnackBar(content: Text('Configuración eliminada')));
                                                      }
                                                    } catch (e) {
                                                      await showAlertDialog(
                                                        context: context,
                                                        title: 'Error',
                                                        message: 'No se pudo borrar la configuración.',
                                                      );
                                                    }
                                                  }
                                                  : null,
                                          icon: const Icon(Icons.delete_outline, size: 18),
                                          label: const Text('Borrar'),
                                          style: TextButton.styleFrom(minimumSize: const Size(80, 36)),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          final minVal = (data['TempMin'] != null) ? int.tryParse(data['TempMin'].toString()) : null;
                          final maxVal = (data['TempMax'] != null) ? int.tryParse(data['TempMax'].toString()) : null;

                          final minCard = tempCard(
                            title: 'Temperatura mínima permitida',
                            icon: Icons.thermostat,
                            fieldKey: 'TempMin',
                            currentValue: minVal,
                            otherValue: maxVal,
                            accent: Colors.blue,
                          );

                          final maxCard = tempCard(
                            title: 'Temperatura máxima permitida',
                            icon: Icons.thermostat_auto,
                            fieldKey: 'TempMax',
                            currentValue: maxVal,
                            otherValue: minVal,
                            accent: Colors.red,
                          );

                          if (isWide) {
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [Expanded(child: minCard), const SizedBox(width: 12), Expanded(child: maxCard)],
                            );
                          } else {
                            return Column(children: [minCard, const SizedBox(height: 12), maxCard]);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Acciones avanzadas",
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
                        ),
                      ),
                      const SizedBox(height: 12),

                      ConfigureAirButton(deviceId: selectedAirConditioning),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
