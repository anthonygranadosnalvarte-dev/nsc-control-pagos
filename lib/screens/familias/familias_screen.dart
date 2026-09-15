import 'package:flutter/material.dart';
import '../../widgets/catalogo_view.dart';

class FamiliasScreen extends StatelessWidget {
  const FamiliasScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const CatalogoView(table: 'familias', title: 'Familias y apoderados');
}
