import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'offline_support.dart';

class UpdateDbFincasPage extends StatefulWidget {
  @override
  _UpdateDbFincasPageState createState() => _UpdateDbFincasPageState();
}

class _UpdateDbFincasPageState extends State<UpdateDbFincasPage> {
  final _formKey = GlobalKey<FormState>();
  final _knumeroController = TextEditingController();
  final _tipoController = TextEditingController();
  final _nitController = TextEditingController();
  final _tipoDocController = TextEditingController();

  bool _isLoading = false;

  Future<void> _updateDbFincas() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Prepare the data
      final data = {
        'knumero': int.parse(_knumeroController.text),
        'stipo': _tipoController.text,
        'snit': _nitController.text,
        'ntipo_doc': int.parse(_tipoDocController.text),
      };

      // Update locally first
      await _updateLocally(data);

      // Try to update in Supabase
      await _updateInSupabase(data);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Actualización exitosa')),
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
    final localData = json.decode(prefs.getString('dbfincas') ?? '[]');
    
    final index = localData.indexWhere((item) => item['knumero'] == data['knumero']);
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
          .update({
            'stipo': data['stipo'],
            'snit': data['snit'],
            'ntipo_doc': data['ntipo_doc'],
          })
          .eq('knumero', data['knumero']);
    } catch (e) {
      print('Error updating Supabase: $e');
      // Save the update for later synchronization
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
      appBar: AppBar(title: Text('Actualizar dbfincas')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _knumeroController,
                decoration: InputDecoration(labelText: 'Código de la finca (knumero)'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese el código de la finca';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _tipoController,
                decoration: InputDecoration(labelText: 'Tipo'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese el tipo';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _nitController,
                decoration: InputDecoration(labelText: 'NIT'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese el NIT';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _tipoDocController,
                decoration: InputDecoration(labelText: 'Tipo de documento'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese el tipo de documento';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _updateDbFincas,
                child: _isLoading
                    ? CircularProgressIndicator()
                    : Text('Actualizar dbfincas'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
