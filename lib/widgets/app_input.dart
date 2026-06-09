import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import '../theme/app_theme.dart';

class AppInput extends StatefulWidget {
  final String hint;
  final IconData icon;
  final bool obscure;
  final bool valid;
  final TextEditingController? controller;
  const AppInput({
    super.key,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.valid = false,
    this.controller,
  });

  @override
  State<AppInput> createState() => _AppInputState();
}

class _AppInputState extends State<AppInput> {
  late bool _hide = widget.obscure;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      obscureText: _hide,
      style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: widget.hint,
        hintStyle: AppTextStyles.body.copyWith(color: const Color(0xFFB5B6C9)),
        prefixIcon: Icon(widget.icon, color: AppColors.mute, size: 18),
        suffixIcon: widget.obscure
            ? IconButton(
                icon: Icon(
                    _hide
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: AppColors.mute,
                    size: 18),
                onPressed: () => setState(() => _hide = !_hide),
              )
            : widget.valid
                ? const Padding(
                    padding: EdgeInsets.only(right: 12),
                    child: CircleAvatar(
                      radius: 10,
                      backgroundColor: AppColors.matcha,
                      child: Icon(Icons.check, color: Colors.white, size: 12),
                    ),
                  )
                : null,
      ),
    );
  }
}
