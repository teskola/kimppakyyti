import 'package:flutter/material.dart' hide DateUtils;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class DateSelector extends StatelessWidget {
  final TextEditingController dateController;
  final String? labelText;
  final String? hintText;
  final bool enabled;
  final void Function() onTap;
  const DateSelector(
      {super.key,
      required this.dateController,
      this.labelText,
      this.hintText,
      this.enabled = true,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    String label = labelText ?? AppLocalizations.of(context).choose_date;
    String hint = hintText ?? AppLocalizations.of(context).when;
    return TextField(
      enabled: enabled,
      controller: dateController,
      readOnly: true,
      decoration: InputDecoration(
          filled: enabled,
          fillColor: Colors.white,
          labelText: label,
          hintText: hint,
          floatingLabelBehavior: FloatingLabelBehavior.always,
          border: const OutlineInputBorder(),
          prefixIcon: const Icon(Icons.calendar_today)),
      onTap: onTap,
    );
  }
}
