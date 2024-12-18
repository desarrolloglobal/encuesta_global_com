import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

class WidgetPreguntaTipo extends StatefulWidget {
  final Map<String, dynamic> pregunta;
  final Function(Map<String, dynamic>) onRespuestaGuardada;

  WidgetPreguntaTipo({
    Key? key,
    required this.pregunta,
    required this.onRespuestaGuardada,
  }) : super(key: key);

  @override
  _WidgetPreguntaTipoState createState() => _WidgetPreguntaTipoState();
}

class _WidgetPreguntaTipoState extends State<WidgetPreguntaTipo> {
  late TextEditingController _respuestaController;
  late TextEditingController _respuestaSecundariaController;
  bool _respuestaBooleana = false;
  String? _respuestaOpcion;
  String? _respuestaOpcionSecundaria;
  List<String> _opciones = [];
  List<bool> _opcionesSeleccionadas = [];
  List<bool> _opcionesSecundariasSeleccionadas = [];
  DateTime _fechaSeleccionada = DateTime.now();
  DateTime _fechaSecundariaSeleccionada = DateTime.now();

  @override
  void initState() {
    super.initState();
    _respuestaController = TextEditingController();
    _respuestaSecundariaController = TextEditingController();
    _cargarOpciones();
    _initializeControllers();
    // Removemos _initializeDates() de aquí
  }

  void _initializeControllers() {
    if (widget.pregunta['ntipo'] == 2) {
      _respuestaController.text = '0';
    }
    if (widget.pregunta['ntipo2'] == 2) {
      _respuestaSecundariaController.text = '0';
    }
  }

  void _initializeDates() {
    if (widget.pregunta['ntipo'] == 5) {
      widget.onRespuestaGuardada(
          {'ffecha': _fechaSeleccionada.toIso8601String()});
    }
    if (widget.pregunta['ntipo2'] == 5) {
      widget.onRespuestaGuardada(
          {'ffecha2': _fechaSecundariaSeleccionada.toIso8601String()});
    }
  }

  @override
  void dispose() {
    _respuestaController.dispose();
    _respuestaSecundariaController.dispose();
    super.dispose();
  }

  void _cargarOpciones() {
    if (widget.pregunta['sOpciones'] != null) {
      if (widget.pregunta['sOpciones'] is List) {
        _opciones = List<String>.from(widget.pregunta['sOpciones']);
      } else if (widget.pregunta['sOpciones'] is String) {
        _opciones = widget.pregunta['sOpciones'].split(',');
      }
      _opcionesSeleccionadas = List.generate(_opciones.length, (_) => false);
      _opcionesSecundariasSeleccionadas =
          List.generate(_opciones.length, (_) => false);
      print('Opciones cargadas: $_opciones');
    }
  }

  void _actualizarRespuestaMultiple(bool esSecundaria) {
    List<String> seleccionadas = [];
    for (int i = 0; i < _opciones.length; i++) {
      if (esSecundaria
          ? _opcionesSecundariasSeleccionadas[i]
          : _opcionesSeleccionadas[i]) {
        seleccionadas.add(_opciones[i]);
      }
    }
    widget.onRespuestaGuardada(
        {esSecundaria ? 'stlargo2' : 'stlargo': seleccionadas});
  }

  Future<void> _seleccionarFecha(
      BuildContext context, bool esSecundaria) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          esSecundaria ? _fechaSecundariaSeleccionada : _fechaSeleccionada,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (esSecundaria) {
          _fechaSecundariaSeleccionada = picked;
        } else {
          _fechaSeleccionada = picked;
        }
      });
      widget.onRespuestaGuardada({
        esSecundaria ? 'ffecha2' : 'ffecha': picked.toIso8601String(),
      });
    }
  }

  Widget _buildRespuestaPrincipal() {
    print(
        'Construyendo respuesta principal para tipo: ${widget.pregunta['ntipo']}');
    switch (widget.pregunta['ntipo']) {
      case 1:
        return TextField(
          controller: _respuestaController,
          decoration: InputDecoration(
            labelText: 'Respuesta (texto corto)',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {
            widget.onRespuestaGuardada({'stcorto': value});
          },
        );
      case 2:
        return TextField(
          controller: _respuestaController,
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Respuesta (número)',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {
            if (value.isEmpty) {
              _respuestaController.text = '0';
              _respuestaController.selection = TextSelection.fromPosition(
                TextPosition(offset: _respuestaController.text.length),
              );
            }
            widget
                .onRespuestaGuardada({'nnumero': double.tryParse(value) ?? 0});
          },
        );
      case 3:
        return SwitchListTile(
          title: Text('Respuesta: ${_respuestaBooleana ? 'Sí' : 'No'}'),
          value: _respuestaBooleana,
          onChanged: (bool value) {
            setState(() {
              _respuestaBooleana = value;
            });
            widget.onRespuestaGuardada({'bsino': value});
          },
        );
      case 4:
        return Column(
          children: [
            ..._opciones.map((opcion) => RadioListTile<String>(
                  title: Text(opcion),
                  value: opcion,
                  groupValue: _respuestaOpcion,
                  onChanged: (value) {
                    setState(() {
                      _respuestaOpcion = value;
                    });
                    widget.onRespuestaGuardada({'soption': value});
                  },
                )),
            if (_respuestaOpcion != null)
              Text('Respuesta seleccionada: $_respuestaOpcion'),
          ],
        );
      case 5:
        return Column(
          children: [
            Text(
              'Fecha seleccionada: ${DateFormat('dd/MM/yyyy').format(_fechaSeleccionada)}',
            ),
            ElevatedButton(
              child: Text('Cambiar fecha'),
              onPressed: () => _seleccionarFecha(context, false),
            ),
          ],
        );
      case 6:
        return Column(
          children: [
            ..._opciones.asMap().entries.map((entry) {
              int idx = entry.key;
              String opcion = entry.value;
              return CheckboxListTile(
                title: Text(opcion),
                value: _opcionesSeleccionadas[idx],
                onChanged: (bool? value) {
                  setState(() {
                    _opcionesSeleccionadas[idx] = value!;
                  });
                  _actualizarRespuestaMultiple(false);
                },
              );
            }),
            Text(
                'Respuestas seleccionadas: ${_opcionesSeleccionadas.where((e) => e).length}'),
          ],
        );
      default:
        return TextField(
          controller: _respuestaController,
          decoration: InputDecoration(
            labelText: 'Respuesta',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {
            widget.onRespuestaGuardada({'stcorto': value});
          },
        );
    }
  }

  Widget _buildRespuestaSecundaria() {
    if (widget.pregunta['ssubtitulo'] == null ||
        widget.pregunta['ssubtitulo'].isEmpty) {
      return SizedBox.shrink();
    }

    print(
        'Construyendo respuesta secundaria para tipo: ${widget.pregunta['ntipo2']}');
    switch (widget.pregunta['ntipo2']) {
      case 1:
        return TextField(
          controller: _respuestaSecundariaController,
          decoration: InputDecoration(
            labelText: 'Respuesta secundaria (texto corto)',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {
            widget.onRespuestaGuardada({'stcorto2': value});
          },
        );
      case 2:
        return TextField(
          controller: _respuestaSecundariaController,
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Respuesta secundaria (número)',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {
            if (value.isEmpty) {
              _respuestaSecundariaController.text = '0';
              _respuestaSecundariaController.selection =
                  TextSelection.fromPosition(
                TextPosition(
                    offset: _respuestaSecundariaController.text.length),
              );
            }
            widget
                .onRespuestaGuardada({'nnumero2': double.tryParse(value) ?? 0});
          },
        );
      case 4:
        return Column(
          children: [
            ..._opciones.map((opcion) => RadioListTile<String>(
                  title: Text(opcion),
                  value: opcion,
                  groupValue: _respuestaOpcionSecundaria,
                  onChanged: (value) {
                    setState(() {
                      _respuestaOpcionSecundaria = value;
                    });
                    widget.onRespuestaGuardada({'soption2': value});
                  },
                )),
            if (_respuestaOpcionSecundaria != null)
              Text(
                  'Respuesta secundaria seleccionada: $_respuestaOpcionSecundaria'),
          ],
        );
      case 5:
        return Column(
          children: [
            Text(
              'Fecha secundaria seleccionada: ${DateFormat('dd/MM/yyyy').format(_fechaSecundariaSeleccionada)}',
            ),
            ElevatedButton(
              child: Text('Cambiar fecha secundaria'),
              onPressed: () => _seleccionarFecha(context, true),
            ),
          ],
        );
      case 6:
        return Column(
          children: [
            ..._opciones.asMap().entries.map((entry) {
              int idx = entry.key;
              String opcion = entry.value;
              return CheckboxListTile(
                title: Text(opcion),
                value: _opcionesSecundariasSeleccionadas[idx],
                onChanged: (bool? value) {
                  setState(() {
                    _opcionesSecundariasSeleccionadas[idx] = value!;
                  });
                  _actualizarRespuestaMultiple(true);
                },
              );
            }),
            Text(
                'Respuestas secundarias seleccionadas: ${_opcionesSecundariasSeleccionadas.where((e) => e).length}'),
          ],
        );
      default:
        return TextField(
          controller: _respuestaSecundariaController,
          decoration: InputDecoration(
            labelText: 'Respuesta secundaria',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {
            widget.onRespuestaGuardada({'stcorto2': value});
          },
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Llamamos a _initializeDates aquí para asegurarnos de que se ejecute después de que el widget esté completamente construido
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeDates();
    });
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.pregunta['stitulo'] != null &&
            widget.pregunta['stitulo'].isNotEmpty)
          Text(
            widget.pregunta['stitulo'],
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        SizedBox(height: 8),
        Text(widget.pregunta['stexto']),
        SizedBox(height: 16),
        _buildRespuestaPrincipal(),
        SizedBox(height: 16),
        if (widget.pregunta['ssubtitulo'] != null &&
            widget.pregunta['ssubtitulo'].isNotEmpty) ...[
          Text(widget.pregunta['ssubtitulo']),
          SizedBox(height: 8),
          _buildRespuestaSecundaria(),
        ],
      ],
    );
  }
}
