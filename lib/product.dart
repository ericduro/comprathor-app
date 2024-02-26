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

class ProductList extends StatefulWidget {
  @override
  _ProductListState createState() => _ProductListState();
}

class _ProductListState extends State<ProductList> {
  List<dynamic> products = [];
  List<dynamic> categories = [];
  String? selectedCategory;
  TextEditingController searchController = TextEditingController();
  List<dynamic> filteredProducts = [];

  @override
  void initState() {
    super.initState();
    fetchProducts();
    fetchCategories();
  }

  Future<void> fetchProducts() async {
    try {
      String endpoint = 'product/all';

      final response = await ApiService.fetchData(endpoint);

      if (response.statusCode == 200) {
        final List<dynamic> productsData = jsonDecode(utf8.decode(response.bodyBytes));
        setState(() {
          products = productsData;
          filteredProducts = productsData;
        });
      } else {
        print('Failed to fetch products: ${response.statusCode}');
      }
    } catch (error) {
      print('Error fetching products: $error');
    }
  }

  Future<void> fetchCategories() async {
    try {
      final response = await ApiService.fetchData('category/all');

      if (response.statusCode == 200) {
        final List<dynamic> categoriesData = jsonDecode(utf8.decode(response.bodyBytes));

        Set<int> uniqueCategoryIds = {};
        List<dynamic> uniqueCategories = [];

        for (var category in categoriesData) {
          if (!uniqueCategoryIds.contains(category['id_category'])) {
            uniqueCategoryIds.add(category['id_category']);
            uniqueCategories.add(category);
          }
        }

        setState(() {
          categories = uniqueCategories;
        });
      } else {
        print('Failed to fetch categories: ${response.statusCode}');
      }
    } catch (error) {
      print('Error fetching categories: $error');
    }
  }

  Future<void> addProduct(String name, String description, String image, String categoryId) async {
    try {
      final data = {
        'name': name,
        'description': description,
        'image': image,
        'id_category': {'id_category': categoryId}
      };

      final response = await ApiService.postData('product/save', data);

      if (response.statusCode == 200) {
        fetchProducts();
      } else {
        print('Failed to add product: ${response.statusCode}');
      }
    } catch (error) {
      print('Error adding product: $error');
    }
  }

  void handleCategoryChange(String? categoryId) {
    setState(() {
      selectedCategory = categoryId;
      if (selectedCategory == null || selectedCategory == '') {
        fetchProducts();
      } else {
        fetchProductsByCategory(selectedCategory!);
      }
    });
  }

  Future<void> fetchProductsByCategory(String categoryId) async {
    String endpoint = 'product/category/$categoryId';
    final response = await ApiService.fetchData(endpoint);

    if (response.statusCode == 200) {
      final List<dynamic> productsData = jsonDecode(utf8.decode(response.bodyBytes));
      setState(() {
        products = productsData;
        filteredProducts = productsData;
      });
    } else {
      print('Failed to fetch products: ${response.statusCode}');
    }
  }

  void searchProducts(String query) {
    setState(() {
      filteredProducts = products.where((product) {
        final productName = product['name'].toString().toLowerCase();
        final productDescription = product['description'].toString().toLowerCase();
        final searchLower = query.toLowerCase();
        return productName.contains(searchLower) || productDescription.contains(searchLower);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(kToolbarHeight),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: searchController,
              onChanged: searchProducts,
              decoration: InputDecoration(
                hintText: 'Buscar productos...',
                filled: true,
                fillColor: Colors.white,
                suffixIcon: IconButton(
                  icon: Icon(Icons.clear),
                  onPressed: () {
                    searchController.clear();
                    searchProducts('');
                  },
                ),
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          DropdownButton<String>(
            value: selectedCategory ?? '',
            hint: Text('Select a category'),
            onChanged: (String? newValue) {
              final categoryId = newValue == '' ? '' : newValue!;
              handleCategoryChange(categoryId);
            },
            items: <DropdownMenuItem<String>>[
              DropdownMenuItem<String>(
                value: '',
                child: Text('Todas las categorías'),
              ),
              ...categories.map<DropdownMenuItem<String>>((category) {
                return DropdownMenuItem<String>(
                  value: category['id_category'].toString(),
                  child: Text(category['name'].toString()),
                );
              }).toList(),
            ],
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredProducts.length,
              itemBuilder: (BuildContext context, int index) {
                return Card(
                  elevation: 4,
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    leading: Container(
                      width: 125,
                      height: 250,
                      child: Padding(
                        padding: EdgeInsets.only(right: 16),
                        child: filteredProducts[index]['image'] != null
                            ? FittedBox(
                          fit: BoxFit.cover,
                          child: Image.network(
                            filteredProducts[index]['image'].toString(),
                          ),
                        )
                            : Placeholder(
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    title: Text(
                      filteredProducts[index]['name'].toString() ?? '',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    subtitle: Text(
                      filteredProducts[index]['description'].toString() ?? '',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddProductDialog(context);
        },
        child: Icon(Icons.add, color: Colors.white),
        backgroundColor: Colors.black,
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

  void _showAddProductDialog(BuildContext context) {
    String name = '';
    String description = '';
    String image = '';
    String? selectedCategory;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Text('Añadir producto'),
              content: SingleChildScrollView(
                child: Column(
                  children: <Widget>[
                    TextField(
                      onChanged: (value) {
                        name = value;
                      },
                      decoration: InputDecoration(
                        labelText: 'Nombre',
                      ),
                    ),
                    TextField(
                      onChanged: (value) {
                        description = value;
                      },
                      decoration: InputDecoration(
                        labelText: 'Descripción',
                      ),
                    ),
                    TextField(
                      onChanged: (value) {
                        image = value;
                      },
                      decoration: InputDecoration(
                        labelText: 'URL de la imagen',
                      ),
                    ),
                    DropdownButton<String>(
                      value: selectedCategory,
                      hint: Text('Seleccione una categoría'),
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedCategory = newValue;
                        });
                      },
                      items: categories.map<DropdownMenuItem<String>>((category) {
                        return DropdownMenuItem<String>(
                          value: category['id_category'].toString(),
                          child: Text(category['name'].toString()),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text('Cancelar'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: Text('Guardar'),
                  onPressed: () {
                    addProduct(name, description, image, selectedCategory ?? '');
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }
}
