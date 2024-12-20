import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'offline_support.dart';
import 'widget_pregunta_tipo.dart';
import 'offline_state_manager.dart';

class UpdateDbFincasPage extends StatefulWidget {
  final int idEncuesta;
  final int idForm;

  const UpdateDbFincasPage({
    Key? key,
    required this.idEncuesta,
    required this.idForm,
  }) : super(key: key);

  @override
  _UpdateDbFincasPageState createState() => _UpdateDbFincasPageState();
}

class _UpdateDbFincasPageState extends State<UpdateDbFincasPage> {
  final _formKey = GlobalKey<FormState>();
  Map<String, TextEditingController> controllers = {};
  bool _isLoading = false;

  // Definición de los campos del formulario
  final List<Map<String, dynamic>> formFields = [
    // {
    //   'key': 'knumero',
    //   'label': 'Código de la finca (knumero)',
    //   'type': 'number',
    //   'required': true,
    //   'errorMessage': 'Por favor ingrese el código de la finca'
    // },
    {
      'key': 'stipo',
      'label': 'Tipo',
      'type': 'text',
      'required': true,
      'errorMessage': 'Por favor ingrese el tipo'
    },
    {
      'key': 'snit',
      'label': 'NIT',
      'type': 'text',
      'required': true,
      'errorMessage': 'Por favor ingrese el NIT'
    },
    {
      'key': 'ntipo_doc',
      'label': 'Tipo de documento',
      'type': 'number',
      'required': true,
      'errorMessage': 'Por favor ingrese el tipo de documento'
    },
  ];

  @override
  void initState() {
    super.initState();
    // Inicializar los controllers para cada campo
    for (var field in formFields) {
      controllers[field['key'] as String] = TextEditingController();
    }
  }

  @override
  void dispose() {
    controllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }

  Future<void> _updateDbFincas() async {
    final idFinca = widget.idForm; // Usar el idForm pasado
    // Continuar con el proceso de actualización...

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Preparar los datos desde los controllers
      final Map<String, dynamic> data = {};
      formFields.forEach((field) {
        final key = field['key'] as String;
        final controller = controllers[key];
        if (controller != null) {
          if (field['type'] == 'number') {
            data[key] = int.parse(controller.text);
          } else {
            data[key] = controller.text;
          }
        }
      });

      await _updateLocally(data);
      await _updateInSupabase(data);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Actualización exitosa')),
      );
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
    List<dynamic> localData = json.decode(prefs.getString('dbfincas') ?? '[]');

    final index =
        localData.indexWhere((item) => item['knumero'] == widget.idForm);
    if (index != -1) {
      localData[index] = {...localData[index] as Map<String, dynamic>, ...data};
    } else {
      localData.add(data);
    }

    await prefs.setString('dbfincas', json.encode(localData));
  }

  Future<void> _updateInSupabase(Map<String, dynamic> data) async {
    try {
      final Map<String, dynamic> updateData = Map<String, dynamic>.from(data);
      updateData.remove('knumero');

      await Supabase.instance.client
          .from('dbfincas')
          .update(updateData)
          .eq('knumero', widget.idForm);
    } catch (e) {
      print('Error updating Supabase: $e');
      await OfflineSupport.saveResponseLocally({
        'table': 'dbfincas',
        'action': 'update',
        'data': data,
      });
    }
  }

  Widget _buildFormField(Map<String, dynamic> field) {
    final key = field['key'] as String;
    return TextFormField(
      controller: controllers[key],
      decoration: InputDecoration(labelText: field['label'] as String),
      keyboardType:
          field['type'] == 'number' ? TextInputType.number : TextInputType.text,
      validator: (value) {
        if (field['required'] == true && (value == null || value.isEmpty)) {
          return field['errorMessage'] as String;
        }
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Actualizar dbfincas')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ...formFields.map((field) => _buildFormField(field)),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _updateDbFincas,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Actualizar dbfincas'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
