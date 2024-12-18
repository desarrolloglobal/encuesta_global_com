import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:universal_html/html.dart' as html;
import 'package:flutter/foundation.dart' show kIsWeb;

class DescargaDetalle extends StatefulWidget {
  @override
  _DescargaDetalleState createState() => _DescargaDetalleState();
}

class _DescargaDetalleState extends State<DescargaDetalle> {
  bool isLoading = false;

  Future<void> exportToCSV() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Obtener datos de la tabla qverespuestas_detail
      final data = await Supabase.instance.client
          .from('qverespuestas_detail')
          .select()
          .then((response) {
        if (response == null) {
          throw Exception('No se obtuvieron datos');
        }
        return response;
      });

      List<dynamic> tableData = data;

      // Convertir los datos a CSV
      String csvData = _convertToCSV(tableData);

      if (kIsWeb) {
        // Código específico para web
        final bytes = utf8.encode(csvData);
        final blob = html.Blob([bytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement()
          ..href = url
          ..style.display = 'none'
          ..download = 'qverespuestas_detail.csv';
        html.document.body!.children.add(anchor);
        anchor.click();
        html.document.body!.children.remove(anchor);
        html.Url.revokeObjectUrl(url);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Archivo CSV descargado correctamente')),
        );
      } else {
        // Código específico para móvil
        // Si necesitas guardar el archivo, este es el momento para hacerlo
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Función de exportación no implementada para móvil.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  String _convertToCSV(List<dynamic> data) {
    List<List<dynamic>> rows = [];

    if (data.isNotEmpty) {
      rows.add(data.first.keys.toList());
    }

    for (var item in data) {
      rows.add(item.values.toList());
    }

    return const ListToCsvConverter().convert(rows);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Descargar Detalle'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: isLoading ? null : exportToCSV,
          child: isLoading ? CircularProgressIndicator() : Text('Exportar'),
        ),
      ),
    );
  }
}
