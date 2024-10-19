import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'offline_support.dart';
import 'widget_pregunta_tipo.dart';
import 'offline_state_manager.dart';

class PreguntasPage extends StatefulWidget {
  final int idEncuesta;
  final int idForm;
  final int totalPreguntas;

  PreguntasPage({
    required this.idEncuesta,
    required this.idForm,
    required this.totalPreguntas,
  });

  @override
  _PreguntasPageState createState() => _PreguntasPageState();
}

class _PreguntasPageState extends State<PreguntasPage> {
  int _currentPreguntaIndex = 0;
  Map<String, dynamic> respuesta = {};
  bool isSaving = false;
  List<Map<String, dynamic>> preguntas = [];

  @override
  void initState() {
    super.initState();
    _cargarPreguntas();
  }

  Future<void> _cargarPreguntas() async {
    final prefs = await SharedPreferences.getInstance();
    final preguntasData = prefs.getString('dbPreguntas');
    if (preguntasData != null) {
      final allPreguntas = json.decode(preguntasData);
      setState(() {
        preguntas = List<Map<String, dynamic>>.from(
          allPreguntas.where((p) => p['nseccion'] == widget.idEncuesta),
        );
        // Ordenar las preguntas por nsubindex
        preguntas.sort((a, b) => a['nsubindex'].compareTo(b['nsubindex']));
      });
    }
  }

  Future<void> _guardarRespuesta() async {
    if (preguntas.isEmpty) return;

    respuesta['npregunta'] = preguntas[_currentPreguntaIndex]['idpreg'];
    respuesta['nform'] = widget.idForm;

    // Obtener el iduser de OfflineStateManager
    String? idUser = await OfflineStateManager.getIdUser();
    if (idUser != null) {
      respuesta['iduser'] = idUser;
    }

    bool saved = await OfflineSupport.saveResponseLocally(respuesta);
    if (!saved && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar la respuesta')),
      );
    }
  }

  void _actualizarRespuesta(Map<String, dynamic> nuevaRespuesta) {
    setState(() {
      respuesta.addAll(nuevaRespuesta);
    });
  }

  Future<void> _siguientePregunta() async {
    if (isSaving) return;

    setState(() {
      isSaving = true;
    });

    await _guardarRespuesta();

    if (_currentPreguntaIndex < preguntas.length - 1) {
      setState(() {
        _currentPreguntaIndex++;
        respuesta.clear();
        isSaving = false;
      });
    } else {
      await _finalizarEncuesta();
    }
  }

  Future<void> _finalizarEncuesta() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text("Finalizando encuesta..."),
            ],
          ),
        );
      },
    );

    try {
      bool synced = await OfflineSupport.syncOfflineResponses();
      if (mounted) {
        Navigator.of(context).pop(); // Cerrar el diálogo de progreso

        if (!synced) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Algunas respuestas se guardarán localmente')),
          );
        }

        // Navegar de vuelta a la página principal
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Cerrar el diálogo de progreso
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al finalizar la encuesta: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Pregunta ${_currentPreguntaIndex + 1} de ${preguntas.length}',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.green,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: preguntas.isEmpty
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 600),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        WidgetPreguntaTipo(
                          key: ValueKey(_currentPreguntaIndex),
                          pregunta: preguntas[_currentPreguntaIndex],
                          onRespuestaGuardada: _actualizarRespuesta,
                        ),
                        SizedBox(height: 20),
                        ElevatedButton(
                          child: Text(
                              _currentPreguntaIndex < preguntas.length - 1
                                  ? 'Siguiente'
                                  : 'Finalizar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                                horizontal: 50, vertical: 15),
                          ),
                          onPressed: isSaving ? null : _siguientePregunta,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
