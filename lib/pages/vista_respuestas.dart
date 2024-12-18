import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
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

  Future<void> _editarRespuesta(Map<String, dynamic> respuesta) async {
    String? nuevoValor = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return _buildEditDialog(respuesta);
      },
    );

    if (nuevoValor != null) {
      try {
        // Determinar qué campo actualizar basado en ntipo
        String campoActualizar;
        dynamic valorActualizar;

        switch (respuesta['ntipo']) {
          case 1:
            campoActualizar = 'stcorto';
            valorActualizar = nuevoValor;
            break;
          case 2:
            campoActualizar = 'nnumero';
            valorActualizar = double.tryParse(nuevoValor);
            break;
          case 3:
            campoActualizar = 'bsino';
            valorActualizar = nuevoValor.toLowerCase() == 'sí';
            break;
          case 4:
            campoActualizar = 'soption';
            valorActualizar = nuevoValor;
            break;
          case 5:
            campoActualizar = 'ffecha';
            valorActualizar = nuevoValor;
            break;
          case 6:
            campoActualizar = 'stlargo';
            valorActualizar = nuevoValor;
            break;
          default:
            throw Exception('Tipo de respuesta no válido');
        }

        // Actualizar en la base de datos
        await Supabase.instance.client
            .from('dbRespuestas')
            .update({campoActualizar: valorActualizar}).eq(
                'id', respuesta['id_respuesta']);

        // Recargar las respuestas
        await _cargarRespuestas();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Respuesta actualizada correctamente')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al actualizar la respuesta: $e')),
          );
        }
      }
    }
  }

  Widget _buildEditDialog(Map<String, dynamic> respuesta) {
    final TextEditingController controller = TextEditingController(
      text: _obtenerRespuesta(respuesta),
    );

    String titulo = 'Editar Respuesta';
    Widget campoEdicion;

    switch (respuesta['ntipo']) {
      case 3: // Para respuestas Sí/No
        return AlertDialog(
          title: Text(titulo),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(respuesta['stexto'] ?? 'Sin pregunta'),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop('Sí'),
                    child: Text('Sí'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop('No'),
                    child: Text('No'),
                  ),
                ],
              ),
            ],
          ),
        );
      case 5: // Para fechas
        return AlertDialog(
          title: Text(titulo),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(respuesta['stexto'] ?? 'Sin pregunta'),
              TextButton(
                onPressed: () async {
                  DateTime? fecha = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (fecha != null) {
                    Navigator.of(context).pop(fecha.toIso8601String());
                  }
                },
                child: Text('Seleccionar Fecha'),
              ),
            ],
          ),
        );
      default:
        return AlertDialog(
          title: Text(titulo),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(respuesta['stexto'] ?? 'Sin pregunta'),
              TextField(
                controller: controller,
                decoration: InputDecoration(labelText: 'Nueva respuesta'),
                maxLines: respuesta['ntipo'] == 6 ? 4 : 1,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: Text('Guardar'),
            ),
          ],
        );
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
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Respuesta: ${_obtenerRespuesta(respuesta)}',
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.edit, color: Colors.green),
                                  onPressed: () => _editarRespuesta(respuesta),
                                ),
                              ],
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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () =>
                          _generarPDF(nombreEncuesta, respuestasGrupo),
                      icon: Icon(Icons.print),
                      label: Text('Imprimir Respuestas'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
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
