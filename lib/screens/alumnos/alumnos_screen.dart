import 'package:flutter/material.dart';
import '../../widgets/catalogo_view.dart';

class AlumnosScreen extends StatelessWidget {
  const AlumnosScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const CatalogoView(table: 'alumnos', title: 'Alumnos');
}
