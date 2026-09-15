import 'package:flutter/material.dart';
import '../../widgets/catalogo_view.dart';

class DeudasScreen extends StatelessWidget {
  const DeudasScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const CatalogoView(table: 'deudas', title: 'Deudas y vencimientos');
}
