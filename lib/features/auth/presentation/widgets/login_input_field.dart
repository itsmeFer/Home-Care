import 'package:flutter/material.dart';

/// Input field dengan latar putih terangkat (soft card), border halus, dan font Plus Jakarta Sans.
class LoginInputField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final TextInputType keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;
  final EdgeInsetsGeometry? contentPadding;
  final String? Function(String?)? validator;

  const LoginInputField({
    super.key,
    required this.controller,
    required this.hintText,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.suffixIcon,
    this.contentPadding,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: const TextStyle(
          fontFamily: 'Plus Jakarta Sans',
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: Color(0xFF0F172A),
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            color: Color(0xFF94A3B8),
            fontSize: 15,
            fontWeight: FontWeight.w400,
          ),
          contentPadding:
              contentPadding ??
              const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 16,
              ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.6),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.2),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.6),
          ),
          suffixIcon: suffixIcon,
        ),
        validator: validator,
      ),
    );
  }
}

/// Checkbox kustom kotak melengkung dengan label 'Remember me'
class RememberMeCheckbox extends StatelessWidget {
  final bool isChecked;
  final ValueChanged<bool> onChanged;

  const RememberMeCheckbox({
    super.key,
    required this.isChecked,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!isChecked),
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 19,
            height: 19,
            decoration: BoxDecoration(
              color: isChecked ? const Color(0xFF2563EB) : Colors.white,
              borderRadius: BorderRadius.circular(5),
              border: Border.all(
                color: isChecked
                    ? const Color(0xFF2563EB)
                    : const Color(0xFFCBD5E1),
                width: 1.5,
              ),
            ),
            child: isChecked
                ? const Icon(Icons.check, size: 13, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 8),
          const Text(
            'Remember me',
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}
