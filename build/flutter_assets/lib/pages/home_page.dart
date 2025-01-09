import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
<<<<<<< HEAD
import 'offline_support.dart';
import 'lista_encuestas.dart';
import 'lista_encuestas_bloque.dart';
import 'lista_encuestas_dbfincas.dart';
import 'offline_state_manager.dart';
import 'descargadetalle.dart';
import 'vista_respuestas.dart';
=======
import 'offline_state_manager.dart';
import 'crear_fincas.dart';
import 'lista_aforos.dart';
>>>>>>> 0f5210f5847071cc155d66aa2117f7a0eba6918b

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String userName = '';
<<<<<<< HEAD
  String userEmail = '';
  List<Map<String, dynamic>> dbFormsList = [];
  String? selectedDbForm;
  bool isConnected = false;
=======
  List<Map<String, dynamic>> fincas = [];
  int authorizedFarms = 0;
  final stateManager = OfflineStateManager();
>>>>>>> 0f5210f5847071cc155d66aa2117f7a0eba6918b

  @override
  void initState() {
    super.initState();
<<<<<<< HEAD
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
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        print('ID del usuario actual: ${user.id}'); // Debug

        // Intentamos obtener los datos
        final response = await Supabase.instance.client
            .from('users')
            .select('id, name, email')
            .eq('id', user.id)
            .maybeSingle();

        print('Respuesta de Supabase: $response'); // Debug

        setState(() {
          if (response != null) {
            userName = response['name'] ?? 'Usuario';
            userEmail = response['email'] ?? user.email ?? 'No disponible';
            print(
                'Datos encontrados - Nombre: $userName, Email: $userEmail'); // Debug
          } else {
            userName = 'Usuario';
            userEmail = user.email ?? 'No disponible';
            print('No se encontraron datos para el usuario'); // Debug
          }
        });

        await OfflineStateManager.saveIdUser(user.id);
      } else {
        print('No hay usuario autenticado'); // Debug
      }
    } catch (e) {
      print('Error al cargar datos del usuario: $e');
      setState(() {
        userName = 'Usuario';
        userEmail = 'No disponible';
      });
    }
  }

  Future<void> _loadDbForms() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final response = await Supabase.instance.client
            .from('dbForms')
            .select('id, sLegal')
            .eq('iduser', user.id) // Filtrar por el ID del usuario actual
            .order('sLegal');

        setState(() {
          dbFormsList = response;
        });
      }
    } catch (e) {
      print('Error al cargar las fincas: $e');
      setState(() {
        dbFormsList = [];
      });
    }
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
=======
    _initializeUser();
  }

  Future<void> _initializeUser() async {
    final user = Supabase.instance.client.auth.currentUser;
    stateManager.setUserId(user!.id);
    await _loadUserData();
    await _loadFincas();
  }

  Future<void> _loadUserData() async {
    final user = Supabase.instance.client.auth.currentUser!;
    final response = await Supabase.instance.client
        .from('users')
        .select('name, nofincas')
        .eq('id', user.id)
        .single();

    setState(() {
      userName = response['name'] ?? 'Usuario';
      authorizedFarms = response['nofincas'] ?? 0;
    });
  }

  Future<void> _loadFincas() async {
    final user = Supabase.instance.client.auth.currentUser!;
    final response = await Supabase.instance.client
        .from('dbfincas')
        .select('id, s_nombrefinca, s_legal')
        .eq('iduser', user.id);

    setState(() {
      fincas = List<Map<String, dynamic>>.from(response);
    });
  }

  void _navigateToListaAforos(Map<String, dynamic> finca) {
    final userId = Supabase.instance.client.auth.currentUser!.id;
    stateManager.setUserId(userId);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ListaAforos(
          fincaId: finca['id'],
          userId: userId,
>>>>>>> 0f5210f5847071cc155d66aa2117f7a0eba6918b
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
<<<<<<< HEAD
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
=======
    final currentFarms = fincas.length;
    final canCreateFarm = currentFarms < authorizedFarms;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF1B4D3E),
        title: Text('FINCAS',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 700),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Column(
                    children: [
                      Image.asset('assets/images/afagro_logo.png', height: 70),
                      SizedBox(width: 8),
                      Text(
                        'Bienvenido: $userName',
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.w500),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Fincas permitidas: $authorizedFarms',
                        style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                      ),
                      Text(
                        'Fincas actuales: $currentFarms',
                        style: TextStyle(fontSize: 16, color: Colors.grey[700]),
>>>>>>> 0f5210f5847071cc155d66aa2117f7a0eba6918b
                      ),
                    ],
                  ),
                ),
<<<<<<< HEAD
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
                _buildButton('Actualizar Finca test dbfica', Icons.edit, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => ListaEncuestasFinca()),
                  );
                }),
                SizedBox(height: 16),
                _buildButton('Crear Entrevistados', Icons.person_add, () {}),
                SizedBox(height: 16),
                _buildButton('Ver respuestas New', Icons.list, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => VistaRespuestas(
                        idForm: int.parse(selectedDbForm ?? '0'),
                        idUser:
                            Supabase.instance.client.auth.currentUser?.id ?? '',
                        userName: userName,
                      ),
                    ),
                  );
                }),
                SizedBox(height: 16),
                _buildButton('Ver reportes', Icons.bar_chart, () {}),
                SizedBox(height: 16),
                _buildButton('Descargar Detalle', Icons.download, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => DescargaDetalle()),
                  );
                }),
                SizedBox(height: 16),
                _buildButton(
                    'Salir', Icons.exit_to_app, () => _signOut(context)),
=======
                SizedBox(height: 30),
                Row(
                  children: [
                    Expanded(
                      child: Text('ID finca',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w500)),
                    ),
                    Expanded(
                      child: Text('Nombre de la finca',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w500)),
                    ),
                    Expanded(
                      child: Text('Propietario',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w500)),
                    ),
                    SizedBox(width: 40),
                  ],
                ),
                SizedBox(height: 10),
                Expanded(
                  child: ListView.builder(
                    itemCount: fincas.length,
                    itemBuilder: (context, index) {
                      return Card(
                        margin: EdgeInsets.only(bottom: 8),
                        color: Color(0xFF1B4D3E),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: InkWell(
                          onTap: () => _navigateToListaAforos(fincas[index]),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    fincas[index]['id'].toString() ?? '',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    fincas[index]['s_nombrefinca'] ?? '',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    fincas[index]['s_legal'] ?? '',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20.0),
                    child: ElevatedButton(
                      onPressed: canCreateFarm
                          ? () async {
                              final stateManager = OfflineStateManager();
                              final user =
                                  Supabase.instance.client.auth.currentUser;
                              if (user != null) {
                                stateManager.setUserId(user.id);
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CrearFincasPage(),
                                  ),
                                );
                                if (result == true) {
                                  _loadFincas();
                                }
                              }
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: canCreateFarm
                            ? Color(0xFF34A853)
                            : Colors.grey[350],
                        padding:
                            EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Agregar una Finca ',
                              style: TextStyle(
                                  color: canCreateFarm
                                      ? Colors.white
                                      : Colors.grey)),
                          Icon(Icons.add,
                              color:
                                  canCreateFarm ? Colors.white : Colors.grey),
                        ],
                      ),
                    ),
                  ),
                ),
>>>>>>> 0f5210f5847071cc155d66aa2117f7a0eba6918b
              ],
            ),
          ),
        ),
      ),
    );
  }
}
