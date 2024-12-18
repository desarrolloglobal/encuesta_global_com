import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'offline_support.dart';
import 'widget_pregunta_tipo.dart';
import 'offline_state_manager.dart';

class PreguntasBloquePage extends StatefulWidget {
  final int idEncuesta;
  final int idForm;

  PreguntasBloquePage({
    required this.idEncuesta,
    required this.idForm,
  });

  @override
  _PreguntasBloquePageState createState() => _PreguntasBloquePageState();
}

class _PreguntasBloquePageState extends State<PreguntasBloquePage> {
  List<Map<String, dynamic>> preguntas = [];
  Map<int, Map<String, dynamic>> respuestas = {};
  bool isSaving = false;

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
        preguntas.sort((a, b) => a['nsubindex'].compareTo(b['nsubindex']));
      });
    }
  }

  void _actualizarRespuesta(int index, Map<String, dynamic> nuevaRespuesta) {
    setState(() {
      respuestas[index] = nuevaRespuesta;
    });
  }

  Future<void> _guardarRespuestas() async {
    if (isSaving) return;

    setState(() {
      isSaving = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      String? idUser = await OfflineStateManager.getIdUser();

      for (int i = 0; i < preguntas.length; i++) {
        if (respuestas.containsKey(i)) {
          Map<String, dynamic> respuesta = respuestas[i]!;
          respuesta['npregunta'] = preguntas[i]['idpreg'];
          respuesta['nform'] = widget.idForm;
          if (idUser != null) {
            respuesta['iduser'] = idUser;
          }

          bool saved = await OfflineSupport.saveResponseLocally(respuesta);
          if (!saved) {
            throw Exception('Error al guardar la respuesta ${i + 1}');
          }
        }
      }

      bool synced = await OfflineSupport.syncOfflineResponses();
      if (!synced) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Algunas respuestas se guardarán localmente')),
        );
      }

      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar las respuestas: $e')),
      );
    } finally {
      setState(() {
        isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Preguntas de la Encuesta',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.green,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 600),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ...preguntas.asMap().entries.map((entry) {
                    int index = entry.key;
                    Map<String, dynamic> pregunta = entry.value;
                    return Padding(
                      padding: EdgeInsets.only(bottom: 20),
                      child: Card(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pregunta ${index + 1}',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 10),
                              WidgetPreguntaTipo(
                                pregunta: pregunta,
                                onRespuestaGuardada: (respuesta) =>
                                    _actualizarRespuesta(index, respuesta),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                  SizedBox(height: 20),
                  ElevatedButton(
                    child: Text('Guardar Respuestas'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                    ),
                    onPressed: isSaving ? null : _guardarRespuestas,
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
