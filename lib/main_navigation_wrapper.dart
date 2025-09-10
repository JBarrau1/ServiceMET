import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:service_met/home/configuracion_screen.dart';
import 'package:service_met/home/otros_apartados_screen.dart';
import 'package:service_met/home/servicios_screen.dart';

import 'home_screen.dart';

class MainNavigationWrapper extends StatefulWidget {
  const MainNavigationWrapper({super.key});

  @override
  State<MainNavigationWrapper> createState() => _MainNavigationWrapperState();
}

class _MainNavigationWrapperState extends State<MainNavigationWrapper> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  // Lista de pantallas para cada tab
  final List<Widget> _screens = [
    const HomeScreen(),
    ServiciosScreen(userName: "Usuario"), // Ajusta según necesites
    OtrosApartadosScreen(userName: "Usuario"), // Ajusta según necesites
    ConfiguracionScreen(),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(), // Deshabilita swipe
        children: _screens,
      ),
      bottomNavigationBar: _buildBottomNavigationBar(context),
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        color: isDarkMode
            ? Colors.black.withOpacity(0.5)
            : Colors.white.withOpacity(0.7),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
          child: NavigationBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            height: 60,
            indicatorColor: isDarkMode
                ? Colors.white.withOpacity(0.2)
                : Colors.black.withOpacity(0.1),
            labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
            destinations: const [
              NavigationDestination(
                icon: Icon(FontAwesomeIcons.home),
                selectedIcon: IconTheme(
                  data: IconThemeData(color: Color(0xFFE8CB0C)),
                  child: Icon(FontAwesomeIcons.home)
                ),
                label: 'Inicio',
              ),
              NavigationDestination(
                icon: Icon(FontAwesomeIcons.wrench),
                selectedIcon: IconTheme(
                  data: IconThemeData(color: Color(0xFFE8CB0C)),
                  child: Icon(FontAwesomeIcons.wrench),
                ),
                label: 'Servicios',
              ),
              NavigationDestination(
                  icon: Icon(FontAwesomeIcons.solidFolder),
                selectedIcon: IconTheme(
                  data: IconThemeData(color: Color(0xFFE8CB0C)),
                  child: Icon(FontAwesomeIcons.solidFolder),
                ),
                label: 'Otros',
              ),
              NavigationDestination(
                icon: Icon(FontAwesomeIcons.cog),
                selectedIcon: IconTheme(
                  data: IconThemeData(color: Color(0xFFE8CB0C)),
                  child: Icon(FontAwesomeIcons.cog),
                ),
                label: 'Ajustes',
              ),
            ],
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) {
              setState(() {
                _currentIndex = index;
                _pageController.jumpToPage(index);
              });
            },
          ),
        ),
      ),
    );
  }
}