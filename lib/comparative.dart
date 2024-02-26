import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'auth_helper.dart';
import 'custom_list.dart';
import 'main.dart';
import 'variables.dart';

class ApiService {

  static Future<http.Response> fetchData(String endpoint) async {
    final url = Uri.parse('${Variables.baseUrl}/$endpoint');
    final headers = {'Authorization': 'Bearer ${AuthHelper.authToken}'};
    return http.get(url, headers: headers);
  }

  static Future<http.Response> postData(String endpoint, dynamic data) async {
    final url = Uri.parse('${Variables.baseUrl}/$endpoint');
    final headers = {
      'Authorization': 'Bearer ${AuthHelper.authToken}',
      'Content-Type': 'application/json'
    };
    return http.post(url, headers: headers, body: jsonEncode(data));
  }
}

class ComparativePage extends StatefulWidget {
  @override
  _ComparativePageState createState() => _ComparativePageState();
}

class _ComparativePageState extends State<ComparativePage> {
  String? selectedCategory;
  String? selectedProductLeft;
  String? selectedProductRight;
  List<dynamic> categories = [];
  List<dynamic> productsLeft = [];
  List<dynamic> productsRight = [];

  @override
  void initState() {
    super.initState();
    fetchCategories();
  }

  Future<void> fetchCategories() async {
    try {
      final response = await ApiService.fetchData('category/all');

      if (response.statusCode == 200) {
        final List<dynamic> categoriesData = jsonDecode(utf8.decode(response.bodyBytes));
        setState(() {
          categories = categoriesData;
        });
      } else {
        print('Failed to fetch categories: ${response.statusCode}');
      }
    } catch (error) {
      print('Error fetching categories: $error');
    }
  }

  Future<void> fetchProductsByCategory(String categoryId) async {
    try {
      final response = await ApiService.fetchData('product/category/$categoryId');

      if (response.statusCode == 200) {
        final List<dynamic> productsData = jsonDecode(utf8.decode(response.bodyBytes));
        setState(() {
          productsLeft = List.from(productsData);
          productsRight = List.from(productsData);
        });
      } else {
        print('Failed to fetch products: ${response.statusCode}');
      }
    } catch (error) {
      print('Error fetching products: $error');
    }
  }

  void handleProductLeftChange(String? productId) {
    setState(() {
      selectedProductLeft = productId;
    });
  }

  void handleProductRightChange(String? productId) {
    setState(() {
      selectedProductRight = productId;
    });
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
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
          ),
        ),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          DropdownButton<String>(
            value: selectedCategory,
            hint: Text('Seleccione una categoría'),
            onChanged: (String? newValue) {
              setState(() {
                selectedCategory = newValue;
                selectedProductLeft = null;
                selectedProductRight = null;
                fetchProductsByCategory(newValue!);
              });
            },
            items: categories.map<DropdownMenuItem<String>>((dynamic category) {
              return DropdownMenuItem<String>(
                value: category['id_category'].toString(),
                child: Text(category['name'].toString()),
              );
            }).toList(),
          ),
          SizedBox(height: 20),
          Column(
            children: [
              Container(
                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width),
                child: DropdownButton<String>(
                  value: selectedProductLeft,
                  hint: Text('Producto izquierdo'),
                  onChanged: (String? newValue) {
                    handleProductLeftChange(newValue);
                  },
                  items: [
                    if (selectedProductLeft == null)
                      DropdownMenuItem<String>(value: null, child: Text('')),
                    ...productsLeft.map<DropdownMenuItem<String>>((dynamic product) {
                      return DropdownMenuItem<String>(
                        value: product['id_product'].toString(),
                        child: Text(product['name'].toString()),
                      );
                    }),
                  ],
                ),
              ),
              SizedBox(height: 20),
              Container(
                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width),
                child: DropdownButton<String>(
                  value: selectedProductRight,
                  hint: Text('Producto derecho'),
                  onChanged: (String? newValue) {
                    handleProductRightChange(newValue);
                  },
                  items: [
                    if (selectedProductRight == null)
                      DropdownMenuItem<String>(value: null, child: Text('')),
                    ...productsRight.map<DropdownMenuItem<String>>((dynamic product) {
                      return DropdownMenuItem<String>(
                        value: product['id_product'].toString(),
                        child: Text(product['name'].toString()),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),




          SizedBox(height: 20),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Card para el producto izquierdo seleccionado
                Expanded(
                  child: Card(
                    margin: EdgeInsets.all(8),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Imagen del producto arriba
                          Container(
                            height: 200, // Altura máxima del contenedor de la imagen
                            child: selectedProductLeft != null && selectedProductLeft!.isNotEmpty && productsLeft.isNotEmpty
                                ? ClipRRect(
                              borderRadius: BorderRadius.circular(8), // Establece el radio de borde para limitar el tamaño de la imagen
                              child: FittedBox(
                                fit: BoxFit.contain,
                                child: Image.network(
                                  productsLeft.firstWhere((product) => product['id_product'].toString() == selectedProductLeft)['image'].toString(),
                                ),
                              ),
                            )
                                : Placeholder(color: Colors.grey),
                          ),
                          SizedBox(height: 8), // Separación entre la imagen y el texto
                          // Nombre del producto y descripción abajo
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  selectedProductLeft != null && selectedProductLeft!.isNotEmpty && productsLeft.isNotEmpty
                                      ? productsLeft.firstWhere((product) => product['id_product'].toString() == selectedProductLeft)['name'].toString()
                                      : '',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                SizedBox(height: 4), // Separación entre el nombre y la descripción
                                Text(
                                  selectedProductLeft != null && selectedProductLeft!.isNotEmpty && productsLeft.isNotEmpty
                                      ? productsLeft.firstWhere((product) => product['id_product'].toString() == selectedProductLeft)['description'].toString()
                                      : '',
                                  style: TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Card para el producto derecho seleccionado
                Expanded(
                  child: Card(
                    margin: EdgeInsets.all(8),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Imagen del producto arriba
                          Container(
                            height: 200, // Altura máxima del contenedor de la imagen
                            child: selectedProductRight != null && selectedProductRight!.isNotEmpty && productsRight.isNotEmpty
                                ? ClipRRect(
                              borderRadius: BorderRadius.circular(8), // Establece el radio de borde para limitar el tamaño de la imagen
                              child: FittedBox(
                                fit: BoxFit.contain,
                                child: Image.network(
                                  productsRight.firstWhere((product) => product['id_product'].toString() == selectedProductRight)['image'].toString(),
                                ),
                              ),
                            )
                                : Placeholder(color: Colors.grey),
                          ),

                          SizedBox(height: 8), // Separación entre la imagen y el texto
                          // Nombre del producto y descripción abajo
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  selectedProductRight != null && selectedProductRight!.isNotEmpty && productsRight.isNotEmpty
                                      ? productsRight.firstWhere((product) => product['id_product'].toString() == selectedProductRight)['name'].toString()
                                      : '',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                SizedBox(height: 4), // Separación entre el nombre y la descripción
                                Text(
                                  selectedProductRight != null && selectedProductRight!.isNotEmpty && productsRight.isNotEmpty
                                      ? productsRight.firstWhere((product) => product['id_product'].toString() == selectedProductRight)['description'].toString()
                                      : '',
                                  style: TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),





        ],
      ),
      drawer: Drawer(
        child: Container(
          color: Colors.black,
          child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              ListTile(
                title: SizedBox.shrink(),
              ),
              CustomListTile(
                title: 'Productos',
                icon: Icons.shopping_cart,
                route: '/products',
              ),
              CustomListTile(
                title: 'Comparativas',
                icon: Icons.compare,
                route: '/comparative',
              ),
              CustomListTile(
                title: 'Perfil',
                icon: Icons.person,
                route: '/',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
