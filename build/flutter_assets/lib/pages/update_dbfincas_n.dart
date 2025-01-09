import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'offline_support.dart';
import 'offline_state_manager.dart';
import 'widget_pregunta_tipo.dart';

class UpdateDbFincasPage extends StatefulWidget {
  final int knumero;

  UpdateDbFincasPage({required this.knumero});

  @override
  _UpdateDbFincasPageState createState() => _UpdateDbFincasPageState();
}

class _UpdateDbFincasPageState extends State<UpdateDbFincasPage> {
  List<Map<String, dynamic>> preguntas = [];
  Map<int, Map<String, dynamic>> respuestas = {};
  Map<String, dynamic> fincaData = {};
  bool _isLoading = false;

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
          allPreguntas.where((p) => p['smodulo'] == 'dbfincas'),
        );
        preguntas.sort((a, b) => a['nsubindex'].compareTo(b['nsubindex']));
      });
    }
    await _cargarDatosFinca();
  }

  Future<void> _cargarDatosFinca() async {
    final prefs = await SharedPreferences.getInstance();
    final fincasData = prefs.getString('dbfincas');
    if (fincasData != null) {
      final allFincas = json.decode(fincasData);
      final finca = allFincas.firstWhere(
        (f) => f['knumero'] == widget.knumero,
        orElse: () => null,
      );
      if (finca != null) {
        setState(() {
          fincaData = Map<String, dynamic>.from(finca);
        });
      }
    }
  }

  void _actualizarRespuesta(int index, Map<String, dynamic> nuevaRespuesta) {
    setState(() {
      respuestas[index] = nuevaRespuesta;

      // Actualizar también fincaData usando el scampo de la pregunta
      String campoFinca = preguntas[index]['scampo'].toString().toLowerCase();

      // Determinar el valor a guardar según el tipo de respuesta
      dynamic valorFinca;
      if (nuevaRespuesta.containsKey('nnumero')) {
        valorFinca = nuevaRespuesta['nnumero'];
      } else if (nuevaRespuesta.containsKey('strespuesta')) {
        valorFinca = nuevaRespuesta['strespuesta'];
      } else if (nuevaRespuesta.containsKey('bsino')) {
        valorFinca = nuevaRespuesta['bsino'];
      } else {
        valorFinca = nuevaRespuesta.values.first;
      }

      fincaData[campoFinca] = valorFinca;
    });
  }

  Future<void> _guardarRespuestas() async {
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      String? idUser = await OfflineStateManager.getIdUser();

      // Preparar datos para dbfincas
      await _updateLocally(fincaData);
      await _updateInSupabase(fincaData);

      // Guardar respuestas en dbRespuestas
      for (int i = 0; i < preguntas.length; i++) {
        if (respuestas.containsKey(i)) {
          Map<String, dynamic> respuesta = respuestas[i]!;
          respuesta['npregunta'] = preguntas[i]['idpreg'];
          respuesta['nform'] = widget.knumero;
          if (idUser != null) {
            respuesta['iduser'] = idUser;
          }

          bool saved = await OfflineSupport.saveResponseLocally(respuesta);
          if (!saved) {
            throw Exception('Error al guardar la respuesta ${i + 1}');
          }
        }
      }

      // Intentar sincronizar las respuestas
      bool synced = await OfflineSupport.syncOfflineResponses();
      if (!synced) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Algunas respuestas se guardarán localmente')),
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Actualización exitosa')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateLocally(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final localData = json.decode(prefs.getString('dbfincas') ?? '[]');

    final index =
        localData.indexWhere((item) => item['knumero'] == widget.knumero);
    if (index != -1) {
      localData[index] = {...localData[index], ...data};
    } else {
      localData.add(data);
    }

    await prefs.setString('dbfincas', json.encode(localData));
  }

  Future<void> _updateInSupabase(Map<String, dynamic> data) async {
    try {
      await Supabase.instance.client
          .from('dbfincas')
          .update(data)
          .eq('knumero', widget.knumero);
    } catch (e) {
      print('Error updating Supabase: $e');
      await OfflineSupport.saveResponseLocally({
        'table': 'dbfincas',
        'action': 'update',
        'data': data,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Actualizar Finca'),
        backgroundColor: Colors.green,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 600),
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
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
                                child: WidgetPreguntaTipo(
                                  pregunta: pregunta,
                                  onRespuestaGuardada: (respuesta) =>
                                      _actualizarRespuesta(index, respuesta),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                        SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _guardarRespuestas,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                                horizontal: 50, vertical: 15),
                          ),
                          child: Text('Guardar Cambios'),
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
