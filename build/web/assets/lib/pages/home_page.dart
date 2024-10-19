import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'offline_support.dart';
import 'lista_encuestas.dart';
import 'lista_encuestas_bloque.dart';
import 'update_dbfincas.dart';
import 'offline_state_manager.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String userName = '';
  String userEmail = '';
  List<Map<String, dynamic>> dbFormsList = [];
  String? selectedDbForm;
  bool isConnected = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadDbForms();
    OfflineStateManager.startMonitoringConnectivity();
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

  @override
  void dispose() {
    OfflineStateManager.stopMonitoringConnectivity();
    super.dispose();
  }

  Future<void> _checkConnectivity() async {
    bool connected = await OfflineStateManager.checkConnectivity();
    setState(() {
      isConnected = connected;
    });
  }

  Future<void> _loadUserData() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final response = await Supabase.instance.client
          .from('users')
          .select('name, email')
          .eq('id', user.id)
          .single();

      setState(() {
        userName = response['name'] ?? 'Usuario';
        userEmail = response['email'] ?? user.email ?? 'No disponible';
      });
      // Guarda el idUser
      await OfflineStateManager.saveIdUser(user.id);
    }
  }

  Future<void> _loadDbForms() async {
    final response = await Supabase.instance.client
        .from('dbForms')
        .select('id, sLegal')
        .order('sLegal');

    setState(() {
      dbFormsList = response;
    });
  }

  Future<void> _signOut(BuildContext context) async {
    await Supabase.instance.client.auth.signOut();
    Navigator.of(context).pushReplacementNamed('/');
  }

  Future<void> _saveTablesLocally() async {
    final result = await OfflineSupport.saveTablesLocally();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result['message'])),
    );
  }

  Widget _buildButton(String label, IconData icon, VoidCallback onPressed) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(maxWidth: 600),
      child: ElevatedButton.icon(
        icon: Icon(icon, color: Colors.white),
        label: Text(label, style: TextStyle(color: Colors.white)),
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Encuestas Caracterizaciones',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.green,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(16),
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
                SizedBox(height: 20),
                Container(
                  constraints: BoxConstraints(maxWidth: 600),
                  child: DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Escoge una Finca',
                      border: OutlineInputBorder(),
                    ),
                    value: selectedDbForm,
                    items: dbFormsList.map((item) {
                      return DropdownMenuItem(
                        value: item['id'].toString(),
                        child: Text(item['sLegal']),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedDbForm = value;
                      });
                      // Guarda el idForm seleccionado
                      if (value != null) {
                        OfflineStateManager.saveIdForm(int.parse(value));
                      }
                    },
                  ),
                ),
                SizedBox(height: 20),
                _buildButton(
                    'Cargar al teléfono', Icons.download, _saveTablesLocally),
                SizedBox(height: 16),
                _buildButton('Llenar encuesta', Icons.edit, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ListaEncuestas()),
                  );
                }),
                SizedBox(height: 16),
                _buildButton('Llenar Bloque encuesta', Icons.edit, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => ListaEncuestasBloque()),
                  );
                }),
                SizedBox(height: 16),
                _buildButton('Actualizar Finca test', Icons.edit, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => UpdateDbFincasPage()),
                  );
                }),
                SizedBox(height: 16),
                _buildButton('Crear Entrevistados', Icons.person_add, () {}),
                SizedBox(height: 16),
                _buildButton('Ver respuestas', Icons.list, () {}),
                SizedBox(height: 16),
                _buildButton('Ver reportes', Icons.bar_chart, () {}),
                SizedBox(height: 16),
                _buildButton(
                    'Salir', Icons.exit_to_app, () => _signOut(context)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
