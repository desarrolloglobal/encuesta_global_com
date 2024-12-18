import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // Añade esta línea
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:universal_html/html.dart' as html;

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
        return respuesta['ffecha']?.toString() ?? 'Sin respuesta';
      case 6:
        return respuesta['stlargo']?.toString() ?? 'Sin respuesta';
      default:
        return 'Tipo de respuesta no reconocido';
    }
  }

  Future<void> _generarPDF(
      String nombreEncuesta, List<Map<String, dynamic>> respuestasGrupo) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text(
                  nombreEncuesta,
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Text('ID de Finca: ${widget.idForm}'),
              pw.SizedBox(height: 20),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: respuestasGrupo.map((respuesta) {
                  return pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        respuesta['stexto'] ?? 'Sin pregunta',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text('Respuesta: ${_obtenerRespuesta(respuesta)}'),
                      pw.SizedBox(height: 10),
                      pw.Divider(),
                    ],
                  );
                }).toList(),
              ),
            ],
          );
        },
      ),
    );

    // Manejo diferenciado según la plataforma
    if (kIsWeb) {
      // Para web
      final bytes = await pdf.save();
      final blob = html.Blob([bytes], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.document.createElement('a') as html.AnchorElement
        ..href = url
        ..style.display = 'none'
        ..download = '${nombreEncuesta.replaceAll(' ', '_')}.pdf';
      html.document.body?.children.add(anchor);
      anchor.click();
      html.document.body?.children.remove(anchor);
      html.Url.revokeObjectUrl(url);
    } else {
      // Para Android y otras plataformas
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );
    }
  }

  Widget _buildPrintButton(
      String nombreEncuesta, List<Map<String, dynamic>> respuestasGrupo) {
    return ElevatedButton.icon(
      onPressed: () => _generarPDF(nombreEncuesta, respuestasGrupo),
      icon: Icon(Icons.print),
      label: Text('Imprimir Respuestas'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
    );
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
          child: Column(
            children: [
              ExpansionTile(
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
              Padding(
                padding: EdgeInsets.all(8.0),
                child: ElevatedButton.icon(
                  onPressed: () => _generarPDF(nombreEncuesta, respuestasGrupo),
                  icon: Icon(Icons.print),
                  label: Text('Imprimir Respuestas'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
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
