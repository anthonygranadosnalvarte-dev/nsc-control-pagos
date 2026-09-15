import 'package:flutter/material.dart';

import '../core/constants/app_routes.dart';
import 'app_drawer.dart';

class AppShell extends StatelessWidget {
  final String title;
  final String route;
  final Widget body;
  final Widget? floatingActionButton;

  const AppShell({
    super.key,
    required this.title,
    required this.route,
    required this.body,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    final desktop = MediaQuery.sizeOf(context).width >= 900;
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        automaticallyImplyLeading: !desktop,
      ),
      drawer: desktop ? null : AppDrawer(selectedRoute: route),
      floatingActionButton: floatingActionButton,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (desktop)
            SizedBox(
              width: 260,
              child: AppDrawer(selectedRoute: route, embedded: true),
            ),
          Expanded(child: body),
        ],
      ),
    );
  }

  static const homeRoute = AppRoutes.home;
}
