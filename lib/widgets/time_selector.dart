import 'package:flutter/material.dart' hide DateUtils;

class TimeSelector extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final String? hintText;
  final void Function() onTap;
  const TimeSelector(
      {super.key,
      required this.controller,
      this.enabled = true,
      required this.onTap, 
      this.hintText});

  @override
  Widget build(BuildContext context) {
    return TextField(
      enabled: enabled,
      controller: controller,
      readOnly: true,
      decoration: InputDecoration(
          filled: enabled,
          fillColor: Colors.white,
          border: const OutlineInputBorder(),
          hintText: hintText,
          prefixIcon: const Icon(Icons.access_time)),
      onTap: onTap,
    );
  }
}
