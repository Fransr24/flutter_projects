import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:smart_home_app/core/utils/utils.dart';

class ConfigureAirButton extends StatelessWidget {
  final String deviceId;
  final DatabaseReference? baseRef;

  const ConfigureAirButton({Key? key, required this.deviceId, this.baseRef}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      icon: const Icon(Icons.settings),
      label: const Text('Configurar aire acondicionado'),
      onPressed: () => _showModeSelector(context),
      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16)),
    );
  }

  Future<void> _showModeSelector(BuildContext context) async {
    final ref = FirebaseDatabase.instance.ref('air/$deviceId');

    String? selectedMode;

    int valorFrio = 0, valorCaliente = 0, valorApagado = 0;
    try {
      final snapFrio = await ref.child('ConfigOnCold').get();
      final snapCal = await ref.child('ConfigOnHot').get();
      final snapApag = await ref.child('ConfigOff').get();

      valorFrio = (snapFrio.exists && snapFrio.value != null) ? int.tryParse(snapFrio.value.toString()) ?? 0 : 0;
      valorCaliente = (snapCal.exists && snapCal.value != null) ? int.tryParse(snapCal.value.toString()) ?? 0 : 0;
      valorApagado = (snapApag.exists && snapApag.value != null) ? int.tryParse(snapApag.value.toString()) ?? 0 : 0;
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Error leyendo estado de configuración. Intente nuevamente.')));
      return;
    }

    final chosen = await showDialog<String?>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            String _labelFor(int val) {
              if (val == 0) return 'No configurado';
              if (val == 1) return 'Configurando (en curso)';
              return 'Configurado';
            }

            Color _colorFor(int val) {
              if (val == 0) return Colors.red;
              if (val == 1) return const Color.fromARGB(255, 131, 118, 0);
              return Colors.green;
            }

            Widget? _secondaryFor(String modeKey, int modeVal) {
              if (modeVal == 2) {
                return TextButton(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    minimumSize: const Size(0, 0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () async {
                    final confirm =
                        await showDialog<bool>(
                          context: ctx,
                          builder:
                              (c) => AlertDialog(
                                title: const Text('Reconfigurar'),
                                content: const Text(
                                  'La opción ya está configurada. ¿Desea borrar la configuración actual y reconfigurar desde cero?',
                                ),
                                actions: [
                                  TextButton(onPressed: () => Navigator.of(c).pop(false), child: const Text('Volver')),
                                  ElevatedButton(onPressed: () => Navigator.of(c).pop(true), child: const Text('Reconfigurar')),
                                ],
                              ),
                        ) ??
                        false;

                    if (!confirm) return;
                    Navigator.of(ctx).pop(modeKey);
                  },
                  child: const Text('Reconfigurar', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
                );
              }
              return null;
            }

            final dialogContent = ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.65, maxWidth: 560),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RadioListTile<String>(
                      value: 'frio',
                      groupValue: selectedMode,
                      title: const Text('Encendido Frío'),
                      subtitle: Text(_labelFor(valorFrio), style: TextStyle(color: _colorFor(valorFrio))),
                      secondary: _secondaryFor('frio', valorFrio),
                      onChanged:
                          valorFrio == 2
                              ? null
                              : (v) async {
                                if (valorFrio == 1) {
                                  final overwrite =
                                      await showDialog<bool>(
                                        context: ctx,
                                        builder:
                                            (c) => AlertDialog(
                                              title: const Text('Sobrescribir configuración'),
                                              content: const Text(
                                                'Actualmente esta opción se está configurando por otro proceso. ¿Desea sobrescribirlo y comenzar una nueva configuración?',
                                              ),
                                              actions: [
                                                TextButton(onPressed: () => Navigator.of(c).pop(false), child: const Text('Cancelar')),
                                                ElevatedButton(
                                                  onPressed: () => Navigator.of(c).pop(true),
                                                  child: const Text('Sobrescribir'),
                                                ),
                                              ],
                                            ),
                                      ) ??
                                      false;
                                  if (!overwrite) return;
                                }
                                setState(() => selectedMode = v);
                              },
                    ),
                    RadioListTile<String>(
                      value: 'caliente',
                      groupValue: selectedMode,
                      title: const Text('Encendido Calor'),
                      subtitle: Text(_labelFor(valorCaliente), style: TextStyle(color: _colorFor(valorCaliente))),
                      secondary: _secondaryFor('caliente', valorCaliente),
                      onChanged:
                          valorCaliente == 2
                              ? null
                              : (v) async {
                                if (valorCaliente == 1) {
                                  final overwrite =
                                      await showDialog<bool>(
                                        context: ctx,
                                        builder:
                                            (c) => AlertDialog(
                                              title: const Text('Sobrescribir configuración'),
                                              content: const Text(
                                                'Actualmente esta opción se está configurando por otro proceso. ¿Desea sobrescribirlo y comenzar una nueva configuración?',
                                              ),
                                              actions: [
                                                TextButton(onPressed: () => Navigator.of(c).pop(false), child: const Text('Cancelar')),
                                                ElevatedButton(
                                                  onPressed: () => Navigator.of(c).pop(true),
                                                  child: const Text('Sobrescribir'),
                                                ),
                                              ],
                                            ),
                                      ) ??
                                      false;
                                  if (!overwrite) return;
                                }
                                setState(() => selectedMode = v);
                              },
                    ),
                    RadioListTile<String>(
                      value: 'apagado',
                      groupValue: selectedMode,
                      title: const Text('Apagado'),
                      subtitle: Text(_labelFor(valorApagado), style: TextStyle(color: _colorFor(valorApagado))),
                      secondary: _secondaryFor('apagado', valorApagado),
                      onChanged:
                          valorApagado == 2
                              ? null
                              : (v) async {
                                if (valorApagado == 1) {
                                  final overwrite =
                                      await showDialog<bool>(
                                        context: ctx,
                                        builder:
                                            (c) => AlertDialog(
                                              title: const Text('Sobrescribir configuración'),
                                              content: const Text(
                                                'Actualmente esta opción se está configurando por otro proceso. ¿Desea sobrescribirlo y comenzar una nueva configuración?',
                                              ),
                                              actions: [
                                                TextButton(onPressed: () => Navigator.of(c).pop(false), child: const Text('Cancelar')),
                                                ElevatedButton(
                                                  onPressed: () => Navigator.of(c).pop(true),
                                                  child: const Text('Sobrescribir'),
                                                ),
                                              ],
                                            ),
                                      ) ??
                                      false;
                                  if (!overwrite) return;
                                }
                                setState(() => selectedMode = v);
                              },
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Seleccioná la opción que querés configurar y luego presioná "Iniciar configuración".',
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ],
                ),
              ),
            );

            return AlertDialog(
              title: const Text('Seleccionar configuración'),
              content: dialogContent,
              actions: [
                TextButton(onPressed: () => Navigator.of(ctx).pop(null), child: const Text('Cancelar')),
                ElevatedButton(
                  onPressed: selectedMode == null ? null : () => Navigator.of(ctx).pop(selectedMode),
                  child: const Text('Iniciar configuración'),
                ),
              ],
            );
          },
        );
      },
    );

    if (chosen == null) return;

    try {
      final Map<String, Object?> updates = {'configStep': 1};

      if (chosen == 'frio') {
        updates['ConfigOnCold'] = 1;
      } else if (chosen == 'caliente') {
        updates['ConfigOnHot'] = 1;
      } else {
        updates['ConfigOff'] = 1;
      }

      await ref.update(updates);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo iniciar la configuración. Intente nuevamente')));
      return;
    }

    try {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(fullscreenDialog: true, builder: (_) => AirConfigWizardDBFields(deviceId: deviceId, initialMode: chosen)));
    } catch (e) {
      try {
        await ref.update({
          if (chosen == 'frio') 'ConfigOnCold': 0,
          if (chosen == 'caliente') 'ConfigOnHot': 0,
          if (chosen == 'apagado') 'ConfigOff': 0,
        });
      } catch (_) {}
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error abriendo el asistente')));
    }
  }
}

/// Wizard que actualiza los campos concretos en la DB.
/// En finalizar con éxito: pone el campo correspondiente en 2.
/// En cancelar: pone el campo en 0
class AirConfigWizardDBFields extends StatefulWidget {
  final String deviceId;
  final String initialMode; // 'frio'|'caliente'|'apagado'
  final DatabaseReference? baseRef;

  const AirConfigWizardDBFields({Key? key, required this.deviceId, required this.initialMode, this.baseRef}) : super(key: key);

  @override
  State<AirConfigWizardDBFields> createState() => _AirConfigWizardDBFieldsState();
}

class _AirConfigWizardDBFieldsState extends State<AirConfigWizardDBFields> {
  late final DatabaseReference _ref;
  late final List<List<String>> _groupedSteps;
  int _pageIndex = 0;
  bool _isLoading = false;
  bool _isDisposed = false;
  Timer? _pollTimer;
  int _pollSeconds = 0;
  final int _pollTimeoutSeconds = 60;
  int? _remoteConfigStep; // último valor leído de la DB (configStep)
  bool _polling = false;

  @override
  void initState() {
    super.initState();
    _ref = widget.baseRef ?? FirebaseDatabase.instance.ref('air/${widget.deviceId}');
    _groupedSteps = _buildGroupedSteps(widget.initialMode);
  }

  @override
  void dispose() {
    _isDisposed = true;
    _stopPolling();
    super.dispose();
  }

  List<List<String>> _buildGroupedSteps(String mode) {
    final frio = [
      'Encienda el aire acondicionado',
      'Ponga la configuración deseada en estado FRIO (temperatura, fan, mode).',
      'Apague el aire.',
      'Espere a que se encienda la luz roja del dispositivo.',
      'Una vez se encienda la luz roja presione y mantenga el botón del dispositivo hasta ver la luz amarilla.',
      'Con luz amarilla, presione el botón de encendido del aire mientras apunta al dispositivo.',
      'Si el led cambia a verde: la configuración fue exitosa',
      '',
    ];

    final caliente = [
      'Encienda el aire acondicionado',
      'Ponga la configuración deseada en estado CALIENTE (temperatura, fan, mode).',
      'Apague el aire.',
      'Espere a que se encienda la luz roja del dispositivo.',
      'Una vez se encienda la luz roja presione y mantenga el botón del dispositivo hasta ver la luz amarilla.',
      'Con luz amarilla, presione el botón de encendido del aire mientras apunta al dispositivo.',
      'Si el led cambia a verde: la configuración fue exitosa',
      '',
    ];

    final apagado = [
      'Encienda el aire acondicionado',
      'No es necesario que lo configure ya que solamente se necesita tomar la señal de apagado',
      'Verifique que este encendido correctamente',
      'Espere a que se encienda la luz roja del dispositivo.',
      'Una vez se encienda la luz roja presione y mantenga el botón del dispositivo hasta ver la luz amarilla.',
      'Con luz amarilla, presione el botón de apagado del aire mientras apunta al dispositivo.',
      'Si el led cambia a verde: la configuración fue exitosa',
      '',
    ];

    final chosen =
        (mode == 'frio')
            ? frio
            : (mode == 'caliente')
            ? caliente
            : apagado;

    // Agrupo algunos pasos en la misma página)
    const chunkSizes = [3, 4, 1];
    List<List<String>> groups = [];
    int i = 0, chunkIndex = 0;
    while (i < chosen.length) {
      final size = (chunkIndex < chunkSizes.length) ? chunkSizes[chunkIndex] : 2;
      final end = (i + size < chosen.length) ? i + size : chosen.length;
      groups.add(chosen.sublist(i, end));
      i = end;
      chunkIndex++;
    }
    return groups;
  }

  Future<void> _setStepOnDb(int step) async {
    setState(() => _isLoading = true);
    try {
      await _ref.update({'configStep': step});
    } catch (e) {
      if (!_isDisposed) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al guardar el paso en DB')));
      }
    } finally {
      if (!_isDisposed) setState(() => _isLoading = false);
    }
  }

  Future<void> _finishConfiguration({required bool success}) async {
    setState(() => _isLoading = true);
    try {
      final Map<String, Object?> updates = {};

      if (widget.initialMode == 'frio') {
        updates['ConfigOnCold'] = success ? 2 : 0;
      } else if (widget.initialMode == 'caliente') {
        updates['ConfigOnHot'] = success ? 2 : 0;
      } else {
        updates['ConfigOff'] = success ? 2 : 0;
      }
      updates['configStep'] = 0;

      await _ref.update(updates);

      if (!_isDisposed) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(success ? 'Configuración finalizada' : 'Configuración no finalizada')));
      }
    } catch (e) {
      if (!_isDisposed) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al finalizar configuración en DB')));
      }
    } finally {
      if (!_isDisposed) setState(() => _isLoading = false);
      if (mounted) Navigator.of(context).pop();
    }
  }

  void _onNext() async {
    final lastIndex = _groupedSteps.length - 1;

    if (_pageIndex < lastIndex) {
      final newIndex = _pageIndex + 1;
      setState(() => _pageIndex = newIndex);

      // Ultima pagina -> El configStep lo recibo de la database
      if (newIndex == lastIndex) {
        _startPolling();
      } else {
        await _setStepOnDb(newIndex + 1);
      }
      return;
    }

    final confirmed =
        await showDialog<bool>(
          context: context,
          builder:
              (ctx) => AlertDialog(
                title: const Text('Finalizar configuración'),
                content: const Text('¿Confirmás que seguiste todos los pasos y querés finalizar el proceso?'),
                actions: [
                  TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Volver')),
                  ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Finalizar')),
                ],
              ),
        ) ??
        false;

    if (confirmed) {
      await _finishConfiguration(success: true);
    }
  }

  void _onPrev() async {
    final lastIndex = _groupedSteps.length - 1;

    if (_pageIndex > 0) {
      if (_pageIndex == lastIndex) {
        _stopPolling();
      }

      final newIndex = _pageIndex - 1;
      setState(() => _pageIndex = newIndex);

      await _setStepOnDb(newIndex + 1);
    }
  }

  Future<void> _onCancel() async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder:
              (ctx) => AlertDialog(
                title: const Text('Cancelar configuración'),
                content: const Text('¿Desea cancelar la configuración actual?'),
                actions: [
                  TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('No')),
                  ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Si')),
                ],
              ),
        ) ??
        false;
    if (confirmed) {
      final Map<String, Object?> updates = {'configStep': 0};
      if (widget.initialMode == 'frio') {
        updates['ConfigOnCold'] = 0;
      } else if (widget.initialMode == 'caliente') {
        updates['ConfigOnHot'] = 0;
      } else {
        updates['ConfigOff'] = 0;
      }
      try {
        await _ref.update(updates);
      } catch (e) {
        showAlertDialog(context: context, title: "Error", message: "Error actualizando datos $e");
      }
      if (mounted) Navigator.of(context).pop();
    }
  }

  void _startPolling() {
    _stopPolling();
    _pollSeconds = 0;
    _polling = true;

    // Cada 3 segundos me fijo el valor de configStep
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      _pollSeconds += 3;
      try {
        final snap = await _ref.child('configStep').get();
        final val = (snap.exists && snap.value != null) ? int.tryParse(snap.value.toString()) ?? 0 : 0;
        if (mounted) setState(() => _remoteConfigStep = val);

        if (val == 3) {
          _stopPolling();
          return;
        }

        if (_pollSeconds >= _pollTimeoutSeconds) {
          if (val == 2 || val == 1) {
            await _handlePollingTimeout();
          } else {
            _stopPolling();
          }
        }
      } catch (e) {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error leyendo estado remoto. Reintentando...')));
      }
    });
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _polling = false;
    _pollSeconds = 0;
    //setState(() {});
  }

  Future<void> _handlePollingTimeout() async {
    _stopPolling();

    if (mounted) {
      final retry =
          await showDialog<bool>(
            context: context,
            builder:
                (ctx) => AlertDialog(
                  title: const Text('Tiempo excedido'),
                  content: const Text(
                    'No se recibió confirmación del dispositivo en 60s. Se reiniciará el intento. ¿Desea reintentar automáticamente?',
                  ),
                  actions: [
                    TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
                    ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Reintentar')),
                  ],
                ),
          ) ??
          false;

      if (!retry) {
        try {
          final Map<String, Object?> updates = {'configStep': 0};
          if (widget.initialMode == 'frio')
            updates['ConfigOnCold'] = 0;
          else if (widget.initialMode == 'caliente')
            updates['ConfigOnHot'] = 0;
          else
            updates['ConfigOff'] = 0;
          await _ref.update(updates);
        } catch (_) {}
        return;
      }
    }

    // Reintentar automáticamente: limpiar y volver a iniciar
    try {
      final Map<String, Object?> clear = {'configStep': 0};
      if (widget.initialMode == 'frio') {
        clear['ConfigOnCold'] = 0;
      } else if (widget.initialMode == 'caliente') {
        clear['ConfigOnHot'] = 0;
      } else {
        clear['ConfigOff'] = 0;
      }
      await _ref.update(clear);

      await Future.delayed(const Duration(milliseconds: 500));

      final Map<String, Object?> restart = {'configStep': 1};
      if (widget.initialMode == 'frio')
        restart['ConfigOnCold'] = 1;
      else if (widget.initialMode == 'caliente')
        restart['ConfigOnHot'] = 1;
      else
        restart['ConfigOff'] = 1;

      await _ref.update(restart);

      if (mounted) {
        setState(() {
          _remoteConfigStep = 1;
        });
        _startPolling();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reintentando configuración...')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error reintentando la configuración')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = _groupedSteps.length;
    final current = _pageIndex + 1;
    final modeLabel = _modeLabel(widget.initialMode);
    return Scaffold(
      appBar: AppBar(
        title: Text('Configurando: $modeLabel'),
        automaticallyImplyLeading: false,
        //  actions: [IconButton(onPressed: _isLoading ? null : _onCancel, icon: const Icon(Icons.cancel))],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Paso $current de $total', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 8),
              LinearProgressIndicator(value: current / total),
              const SizedBox(height: 18),
              Expanded(
                child: Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Instrucciones', style: Theme.of(context).textTheme.headlineMedium),
                        const SizedBox(height: 12),

                        Expanded(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child:
                                _pageIndex == _groupedSteps.length - 1
                                    ? Align(
                                      alignment: Alignment.topCenter,
                                      child: ConstrainedBox(
                                        constraints: BoxConstraints(maxWidth: 640, maxHeight: MediaQuery.of(context).size.height * 0.72),
                                        child: SingleChildScrollView(
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 6.0),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const SizedBox(height: 5),
                                                Text(
                                                  'Espera a que el dispositivo confirme que el proceso a finalizado correctamente',
                                                  textAlign: TextAlign.center,
                                                  style: const TextStyle(fontSize: 16),
                                                ),
                                                const SizedBox(height: 16),
                                                Card(
                                                  color: Theme.of(context).cardColor,
                                                  elevation: 4,
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                  child: Padding(
                                                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 28),
                                                    child: Column(
                                                      children: [
                                                        Text(
                                                          'Esperando confirmación del dispositivo',
                                                          textAlign: TextAlign.center,
                                                          style: Theme.of(
                                                            context,
                                                          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                                                        ),
                                                        const SizedBox(height: 18),

                                                        AnimatedSwitcher(
                                                          duration: const Duration(milliseconds: 350),
                                                          child:
                                                              _remoteConfigStep == 3
                                                                  ? Column(
                                                                    key: const ValueKey('success'),
                                                                    children: [
                                                                      Container(
                                                                        decoration: BoxDecoration(
                                                                          color: Colors.green.shade50,
                                                                          shape: BoxShape.circle,
                                                                        ),
                                                                        padding: const EdgeInsets.all(12),
                                                                        child: const Icon(
                                                                          Icons.check_circle,
                                                                          color: Colors.green,
                                                                          size: 86,
                                                                        ),
                                                                      ),
                                                                      const SizedBox(height: 12),
                                                                      Text(
                                                                        'Configuración exitosa',
                                                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                                          color: Colors.green,
                                                                          fontWeight: FontWeight.w700,
                                                                        ),
                                                                      ),
                                                                      const SizedBox(height: 8),
                                                                      Text(
                                                                        'El dispositivo confirmó correctamente la configuración.',
                                                                        textAlign: TextAlign.center,
                                                                        style: Theme.of(context).textTheme.bodySmall,
                                                                      ),
                                                                    ],
                                                                  )
                                                                  : Column(
                                                                    key: const ValueKey('waiting'),
                                                                    children: [
                                                                      SizedBox(
                                                                        height: 120,
                                                                        width: 120,
                                                                        child: Stack(
                                                                          alignment: Alignment.center,
                                                                          children: [
                                                                            SizedBox(
                                                                              height: 120,
                                                                              width: 120,
                                                                              child: CircularProgressIndicator(
                                                                                strokeWidth: 8,
                                                                                value:
                                                                                    (_pollTimeoutSeconds > 0)
                                                                                        ? ((_pollSeconds / _pollTimeoutSeconds).clamp(
                                                                                          0.0,
                                                                                          1.0,
                                                                                        ))
                                                                                        : null,
                                                                              ),
                                                                            ),
                                                                            if (_polling)
                                                                              const Padding(
                                                                                padding: EdgeInsets.all(8.0),
                                                                                child: Icon(Icons.hourglass_empty, size: 36),
                                                                              )
                                                                            else
                                                                              const Padding(
                                                                                padding: EdgeInsets.all(8.0),
                                                                                child: Icon(Icons.play_circle_outline, size: 36),
                                                                              ),
                                                                          ],
                                                                        ),
                                                                      ),
                                                                      const SizedBox(height: 14),
                                                                      Text(
                                                                        _polling
                                                                            ? 'Esperando confirmación...'
                                                                            : 'Listo para iniciar la espera de configuración',
                                                                        style: Theme.of(
                                                                          context,
                                                                        ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                                                                        textAlign: TextAlign.center,
                                                                      ),
                                                                      const SizedBox(height: 8),
                                                                      Text(
                                                                        _polling
                                                                            ? 'Tiempo transcurrido: ${_pollSeconds}s / ${_pollTimeoutSeconds}s'
                                                                            : 'Al llegar a este paso el dispositivo debe confirmar la configuración.',
                                                                        textAlign: TextAlign.center,
                                                                        style: Theme.of(
                                                                          context,
                                                                        ).textTheme.bodySmall?.copyWith(color: Colors.black54),
                                                                      ),
                                                                      const SizedBox(height: 12),

                                                                      Wrap(
                                                                        alignment: WrapAlignment.center,
                                                                        spacing: 8,
                                                                        runSpacing: 8,
                                                                        children: [
                                                                          SizedBox(
                                                                            height: 44,
                                                                            child: OutlinedButton.icon(
                                                                              onPressed: _polling ? null : () => _startPolling(),
                                                                              icon: const Icon(Icons.refresh),
                                                                              label: const Text('Reintentar'),
                                                                              style: OutlinedButton.styleFrom(
                                                                                minimumSize: const Size(120, 44),
                                                                              ),
                                                                            ),
                                                                          ),
                                                                        ],
                                                                      ),
                                                                    ],
                                                                  ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(height: 16),
                                                Text(
                                                  'Sigue las instrucciones anteriores y espera a que el equipo confirme. Si pasado 1 minuto no hay confirmación, se ofrecerá reintentar automáticamente.',
                                                  textAlign: TextAlign.center,
                                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black54),
                                                ),
                                                const SizedBox(height: 8),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    )
                                    : ListView.separated(
                                      padding: const EdgeInsets.only(top: 4),
                                      itemCount: _groupedSteps[_pageIndex].length,
                                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                                      itemBuilder: (ctx, i) {
                                        final stepText = _groupedSteps[_pageIndex][i];
                                        return Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            CircleAvatar(radius: 14, child: Text('${i + 1}', style: const TextStyle(fontSize: 12))),
                                            const SizedBox(width: 12),
                                            Expanded(child: Text(stepText, style: const TextStyle(fontSize: 16))),
                                          ],
                                        );
                                      },
                                    ),
                          ),
                        ),

                        const SizedBox(height: 12),
                        Text(
                          'Consejo: seguir los pasos con luz directa al dispositivo. Si algo falla, volvé al paso anterior y reintentá.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              Row(
                children: [
                  /* Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Anterior'),
                      onPressed: _pageIndex == 0 || _isLoading ? null : _onPrev,
                    ),
                  ),
                  const SizedBox(width: 12), */
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: Icon(_pageIndex == _groupedSteps.length - 1 ? Icons.check : Icons.arrow_forward),
                      label: Text(_pageIndex == _groupedSteps.length - 1 ? 'Finalizar' : 'Siguiente'),
                      onPressed:
                          _isLoading
                              ? null
                              : (_pageIndex == _groupedSteps.length - 1
                                  ? (_remoteConfigStep == 3 ? () => _finishConfiguration(success: true) : null)
                                  : _onNext),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  String _modeLabel(String key) {
    return (key == 'frio')
        ? 'Encendido Frío'
        : (key == 'caliente')
        ? 'Encendido Caliente'
        : 'Apagado';
  }
}
