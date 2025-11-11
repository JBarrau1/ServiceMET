// lib/login/widgets/setup/config_field.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ConfigField extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final bool isDark;
  final bool isPassword;
  final bool isNumber;
  final String? Function(String?)? validator;

  const ConfigField({
    super.key,
    required this.label,
    required this.controller,
    required this.icon,
    required this.isDark,
    this.isPassword = false,
    this.isNumber = false,
    this.validator,
  });

  @override
  State<ConfigField> createState() => _ConfigFieldState();
}

class _ConfigFieldState extends State<ConfigField> {
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: widget.isDark ? Colors.white70 : Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: widget.controller,
          obscureText: widget.isPassword && _obscurePassword,
          keyboardType: widget.isNumber
              ? TextInputType.number
              : TextInputType.text,
          style: GoogleFonts.inter(
            fontSize: 15,
            color: widget.isDark ? Colors.white : Colors.black87,
          ),
          decoration: InputDecoration(
            hintText: 'Ingresa ${widget.label}',
            hintStyle: GoogleFonts.inter(
              color: widget.isDark ? Colors.white30 : Colors.black26,
            ),
            filled: true,
            fillColor: widget.isDark
                ? const Color(0xFF1a1a1a)
                : const Color(0xFFF5F7FA),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 18,
            ),
            prefixIcon: Icon(
              widget.icon,
              color: widget.isDark ? Colors.white70 : Colors.black38,
              size: 22,
            ),
            suffixIcon: widget.isPassword
                ? IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: widget.isDark ? Colors.white70 : Colors.black38,
                size: 22,
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            )
                : null,
          ),
          validator: widget.validator,
        ),
      ],
    );
  }
}