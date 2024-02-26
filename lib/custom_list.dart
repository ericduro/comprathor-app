import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CustomListTile extends StatefulWidget {
  final String title;
  final String route;
  final IconData icon;

  const CustomListTile({
    required this.title,
    required this.route,
    required this.icon,
    Key? key,
  }) : super(key: key);

  @override
  _CustomListTileState createState() => _CustomListTileState();
}

class _CustomListTileState extends State<CustomListTile> {
  Color _textColor = Colors.white;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: InkWell(
        onTap: () {
          GoRouter.of(context).go(widget.route);
        },
        onHover: (value) {
          setState(() {
            _textColor = value ? Colors.grey : Colors.white;
          });
        },
        child: Container(
          color: Colors.black,
          child: ListTile(
            leading: Icon(
              widget.icon, // Usamos el icono proporcionado
              color: _textColor, // Color del icono
            ),
            title: Text(
              widget.title,
              style: TextStyle(
                color: _textColor, // Texto blanco o gris al pasar el cursor
              ),
            ),
          ),
        ),
      ),
    );
  }
}
