// ignore_for_file: deprecated_member_use

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeBottomBar extends StatelessWidget {
  final int currentIndex;
  final bool modoDemo;
  final Function(int) onTap;

  const HomeBottomBar({
    super.key,
    required this.currentIndex,
    required this.modoDemo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              color: isDarkMode
                  ? Colors.black.withOpacity(0.4)
                  : Colors.white.withOpacity(0.7),
              border: Border.all(
                color: isDarkMode
                    ? Colors.white.withOpacity(0.1)
                    : Colors.black.withOpacity(0.1),
                width: 0.5,
              ),
            ),
            child: NavigationBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              height: 80,
              indicatorColor: const Color(0xFFE8CB0C).withOpacity(0.15),
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              destinations: [
                NavigationDestination(
                  icon: Icon(
                    FontAwesomeIcons.home,
                    color: modoDemo
                        ? (isDarkMode ? Colors.white24 : Colors.black26)
                        : currentIndex == 0
                            ? const Color(0xFFE8CB0C)
                            : (isDarkMode ? Colors.white70 : Colors.black54),
                    size: 20,
                  ),
                  label: 'Inicio',
                ),
                NavigationDestination(
                  icon: Icon(
                    FontAwesomeIcons.wrench,
                    color: currentIndex == 1
                        ? const Color(0xFFE8CB0C)
                        : (isDarkMode ? Colors.white70 : Colors.black54),
                    size: 20,
                  ),
                  label: 'Servicios',
                ),
                NavigationDestination(
                  icon: Icon(
                    FontAwesomeIcons.download,
                    color: modoDemo
                        ? (isDarkMode ? Colors.white24 : Colors.black26)
                        : currentIndex == 2
                            ? const Color(0xFFE8CB0C)
                            : (isDarkMode ? Colors.white70 : Colors.black54),
                    size: 20,
                  ),
                  label: 'Precarga',
                ),
              ],
              selectedIndex: currentIndex,
              onDestinationSelected: (index) {
                // En modo DEMO solo permitir acceso a Servicios (index 1)
                if (modoDemo && index != 1) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.lock_outline,
                              color: Colors.white, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'En modo DESCONECTADO solo puedes acceder a Servicios',
                              style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: const Color(0xFFFF9800),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      margin: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                    ),
                  );
                  return;
                }
                onTap(index);
              },
            ),
          ),
        ),
      ),
    );
  }
}
