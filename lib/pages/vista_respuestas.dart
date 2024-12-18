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
          .from('vista_respuestas_2')
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

  String _obtenerRespuesta(Map<String, dynamic> respuesta) {
    final int ntipo = respuesta['ntipo'] ?? 0;

    switch (ntipo) {
      case 1:
        return respuesta['stcorto']?.toString() ?? 'Sin respuesta';
      case 2:
        return respuesta['nnumero']?.toString() ?? 'Sin respuesta';
      case 3:
        return respuesta['bsino'] == true ? 'Sí' : 'No';
      case 4:
        return respuesta['soption']?.toString() ?? 'Sin respuesta';
      case 5:
        // Puedes formatear la fecha si lo deseas
        return respuesta['ffecha']?.toString() ?? 'Sin respuesta';
      case 6:
        return respuesta['stlargo']?.toString() ?? 'Sin respuesta';
      default:
        return 'Tipo de respuesta no reconocido';
    }
  }

  Widget _buildRespuestasGrouped() {
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
                        Text(
                          respuesta['stexto'] ?? 'Sin pregunta',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Respuesta: ${_obtenerRespuesta(respuesta)}',
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
