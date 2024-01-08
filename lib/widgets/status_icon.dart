import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../providers/status.dart';

class StatusIcon extends StatelessWidget {
  final Status? status;
  const StatusIcon(this.status, {super.key});

  List<Widget> statusList(IconData icon, String text) {
    return [
      Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Icon(icon),
      ),
      Text(text)
    ];
  }

  List<Widget> children(BuildContext context) {
    switch (status) {
      case Status.cancelled:
        return statusList(
            Icons.cancel_outlined, AppLocalizations.of(context).cancelled);
      case Status.driving:
        return statusList(
            Icons.directions_car, AppLocalizations.of(context).driving);
      case Status.waiting:
        return statusList(
            Icons.access_time, AppLocalizations.of(context).waiting);
      case Status.late:
        return statusList(Icons.access_time, AppLocalizations.of(context).late);
      case Status.finished:
        return statusList(Icons.done, AppLocalizations.of(context).finished);
      case Status.declined:
        return statusList(Icons.block, AppLocalizations.of(context).declined);
      case Status.full:
        return statusList(
            Icons.error_outline, AppLocalizations.of(context).full);
      default:
        return [const Icon(Icons.question_mark)];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: children(context),
    );
  }
}
