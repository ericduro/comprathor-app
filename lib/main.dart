import 'dart:html';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:keycloak_flutter/keycloak_flutter.dart';

import 'auth_helper.dart';
import 'custom_list.dart';
import 'product.dart';
import 'comparative.dart';
import 'variables.dart';


late KeycloakService keycloakService;

Future<void> main() async {
  keycloakService = KeycloakService(KeycloakConfig(
      url: Variables.keycloakUrl, // Keycloak auth base url
      realm: 'SpringBootKeycloak',
      clientId: 'login-app'));
  keycloakService.init(
    initOptions: KeycloakInitOptions(
      onLoad: 'login-required',
      checkLoginIframe: true,
      pkceMethod: 'S256',
    ),
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Comprathor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
      ),
      routerConfig: _router,
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, this.title}) : super(key: key);
  final String? title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class PerfilPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Perfil'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Bienvenido a tu perfil',
              style: Theme.of(context).textTheme.headline4,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Lógica para obtener el código
              },
              child: Text('Get Code'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Lógica para refrescar el token
              },
              child: Text('Refresh Token'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MyHomePageState extends State<MyHomePage> {
  KeycloakProfile? _keycloakProfile;

  void _login() {
    keycloakService.login(KeycloakLoginOptions(
      redirectUri: '${window.location.origin}',
    ));
  }

  void _refreshToken() async {
    print('refrescando token');
    await keycloakService.updateToken(1000).then((value) async {
      String token = await keycloakService.getToken(false);
      AuthHelper.setAuthToken(token);
    }).catchError((onError) {
      print(onError);
    });
  }

  void _getCode() async {
    print('consiguiendo token');
    // Llama al método para obtener el código del token
    // Asegúrate de que KeycloakService tenga un método para obtener el código del token
    // por ejemplo: await keycloakService.getCode();
    String token = await keycloakService.getToken(false);
    print(token);
    AuthHelper.setAuthToken(token);
  }

  @override
  void initState() {
    super.initState();
    try {
      WidgetsBinding.instance!.addPostFrameCallback((timeStamp) async {
        keycloakService.keycloakEventsStream.listen((event) async {
          if (event.type == KeycloakEventType.onAuthSuccess) {
            _keycloakProfile = await keycloakService.loadUserProfile();
            _getCode();
          } else {
            _keycloakProfile = null;
          }
          setState(() {});
        });
        if (keycloakService.authenticated) {
          _keycloakProfile = await keycloakService.loadUserProfile(false);
          _getCode(); // Llama automáticamente al obtener el token al iniciar sesión
        }
        setState(() {});
      });
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: Builder(
          builder: (context) => AppBar(
            title: Image.asset(
              'assets/LOGO_BLANCO_SIN_FONDO.png',
              height: 40,
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: Icon(Icons.logout),
                onPressed: () async {
                  await keycloakService.logout();
                },
              ),
            ],
            backgroundColor: Colors.black, // Fondo negro para la AppBar
            foregroundColor: Colors.white, // Textos en blanco en la AppBar
          ),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SizedBox(height: 30),
            Text(
              'Bienvenid@ ${_keycloakProfile?.username ?? 'Usuari@ sin identificar'}',
              style: Theme.of(context).textTheme.headline4,
            ),
            SizedBox(height: 20),
            if (_keycloakProfile?.username == null)
              ElevatedButton(
                onPressed: _login,
                child: Text(
                  'Login',
                  style: Theme.of(context).textTheme.headline4,
                ),
              ),
            SizedBox(height: 20),
            if (_keycloakProfile?.username != null)
              Column(
                children: [
                  ElevatedButton(
                    onPressed: _refreshToken,
                    child: Text(
                      'Refrescar token',
                      style: Theme.of(context).textTheme.headline4,
                    ),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _getCode,
                    child: Text(
                      'Conseguir token',
                      style: Theme.of(context).textTheme.headline4,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
      /*floatingActionButton: FloatingActionButton(
        onPressed: _login,
        tooltip: 'Login',
        child: Icon(Icons.login),
      ),*/
      drawer: Drawer(
        child: Container(
          color: Colors.black,
          child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              ListTile( // Elemento vacío para crear espacio negro en la parte superior
                title: SizedBox.shrink(),
              ),
              CustomListTile(
                title: 'Productos',
                icon: Icons.shopping_cart, // Icono para productos
                route: '/products',
              ),
              CustomListTile(
                title: 'Comparativas',
                icon: Icons.compare, // Icono para comparativas
                route: '/comparative',
              ),
              CustomListTile(
                title: 'Perfil',
                icon: Icons.person, // Icono para perfil
                route: '/',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final _router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => MyHomePage(),
    ),
    GoRoute(
      path: '/perfil', // Ruta para la página de perfil
      builder: (context, state) => PerfilPage(), // Reemplaza PerfilPage con la página que deseas mostrar en el perfil del usuario
    ),
    GoRoute(
      path: '/products',
      builder: (context, state) => ProductList(),
    ),
    GoRoute( // Ruta para comparativas
      path: '/comparative',
      builder: (context, state) => ComparativePage(),
    ),
  ],
  errorPageBuilder: (context, state) {
    // Redirige a la página principal en caso de error
    return MaterialPage(
      child: MyHomePage(),
    );
  },
);
