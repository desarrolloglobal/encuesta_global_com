import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'offline_state_manager.dart';
import 'preguntas_bloque.dart';

class ListaEncuestasBloque extends StatefulWidget {
  @override
  _ListaEncuestasBloqueState createState() => _ListaEncuestasBloqueState();
}

class _ListaEncuestasBloqueState extends State<ListaEncuestasBloque> {
  List<dynamic> encuestas = [];
  int? idForm;
  String? idUser;
  String userName = '';
  bool isConnected = false;

  @override
  void initState() {
    super.initState();
    _loadStateAndEncuestas();
    OfflineStateManager.connectivityStream.listen((connected) {
      setState(() {
        isConnected = connected;
      });
    });
    OfflineStateManager.checkConnectivity().then((connected) {
      setState(() {
        isConnected = connected;
      });
    });
  }

  Future<void> _checkConnectivity() async {
    bool connected = await OfflineStateManager.checkConnectivity();
    setState(() {
      isConnected = connected;
    });
  }

  Future<void> _loadStateAndEncuestas() async {
    // Carga idForm, idUser y userName
    idForm = await OfflineStateManager.getIdForm();
    idUser = await OfflineStateManager.getIdUser();
    userName = await OfflineStateManager.getUserName() ?? 'Usuario';

    // Carga las encuestas
    await _cargarEncuestas();

    // Actualiza el estado para reflejar los cambios
    setState(() {});
  }

  Future<void> _cargarEncuestas() async {
    final prefs = await SharedPreferences.getInstance();
    final encuestasData = prefs.getString('dbEncuestas');
    if (encuestasData != null) {
      setState(() {
        encuestas = json.decode(encuestasData);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Listado de Encuestas Bloque',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.green,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 600),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$userName - ',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      isConnected ? 'Conectado' : 'Sin conexión',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      'Bienvenidos\n¿Listo para empezar?',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: encuestas.length,
                  itemBuilder: (context, index) {
                    final encuesta = encuestas[index];
                    return Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.green,
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          title:
                              Text(encuesta['nombreencuesta'] ?? 'Sin nombre'),
                          onTap: () async {
                            final prefs = await SharedPreferences.getInstance();
                            final preguntasData =
                                prefs.getString('dbPreguntas');
                            if (preguntasData != null) {
                              final preguntas = json.decode(preguntasData);
                              final totalPreguntas = preguntas
                                  .where((p) => p['nseccion'] == encuesta['id'])
                                  .length;

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PreguntasBloquePage(
                                    idEncuesta: encuesta['id'],
                                    idForm: idForm ?? 0,
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
