import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class VistaRespuestas extends StatefulWidget {
  final int idForm;
  final String idUser;
  final String userName;

  const VistaRespuestas({
    Key? key,
    required this.idForm,
    required this.idUser,
    required this.userName,
  }) : super(key: key);

  @override
  _VistaRespuestasState createState() => _VistaRespuestasState();
}

class _VistaRespuestasState extends State<VistaRespuestas> {
  List<Map<String, dynamic>> respuestas = [];
  bool isLoading = true;
  String error = '';

  @override
  void initState() {
    super.initState();
    _cargarRespuestas();
  }

  Future<void> _cargarRespuestas() async {
    try {
      final response = await Supabase.instance.client
          .from('vista_respuestas_1')
          .select()
          .eq('nform', widget.idForm)
          .order('nombreencuesta');

      setState(() {
        respuestas = List<Map<String, dynamic>>.from(response);
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = 'Error al cargar las respuestas: $e';
        isLoading = false;
      });
    }
  }

  Widget _buildRespuestasGrouped() {
    // Agrupar respuestas por nombreencuesta
    Map<String, List<Map<String, dynamic>>> respuestasAgrupadas = {};

    for (var respuesta in respuestas) {
      String nombreEncuesta = respuesta['nombreencuesta'] ?? 'Sin nombre';
      respuestasAgrupadas.putIfAbsent(nombreEncuesta, () => []);
      respuestasAgrupadas[nombreEncuesta]!.add(respuesta);
    }

    return ListView.builder(
      itemCount: respuestasAgrupadas.length,
      itemBuilder: (context, index) {
        String nombreEncuesta = respuestasAgrupadas.keys.elementAt(index);
        List<Map<String, dynamic>> respuestasGrupo =
            respuestasAgrupadas[nombreEncuesta]!;

        return Card(
          margin: EdgeInsets.all(8),
          child: ExpansionTile(
            title: Text(
              nombreEncuesta,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            children: [
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: respuestasGrupo.length,
                itemBuilder: (context, i) {
                  var respuesta = respuestasGrupo[i];
                  return Padding(
                    padding: EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Mostrar el nombre de la pregunta (stexto)
                        Text(
                          respuesta['stexto'] ?? 'Sin pregunta',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        // Mostrar la respuesta (soption)
                        Text(
                          'Respuesta: ${respuesta['soption'] ?? 'Sin respuesta'}',
                        ),
                        Divider(),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Respuestas de la Encuesta',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.green,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : error.isNotEmpty
              ? Center(child: Text(error))
              : respuestas.isEmpty
                  ? Center(child: Text('No hay respuestas disponibles'))
                  : _buildRespuestasGrouped(),
    );
  }
}
