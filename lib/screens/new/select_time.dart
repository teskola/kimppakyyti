import 'package:flutter/material.dart' hide Route, DateUtils;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../models/route.dart';
import 'confirm.dart';
import '../../widgets/date_selector.dart';
import '../../utilities/date_utils.dart';
import '../../widgets/time_selector.dart';

class SelectTimePage extends StatefulWidget {
  final CustomRoute route;
  const SelectTimePage({super.key, required this.route});

  @override
  State<SelectTimePage> createState() => _SelectTimePageState();
}

class _SelectTimePageState extends State<SelectTimePage> {
  final TextEditingController _minDateController = TextEditingController();
  final TextEditingController _minTimeController = TextEditingController();
  final TextEditingController _maxDateController = TextEditingController();
  final TextEditingController _maxTimeController = TextEditingController();
  final TextEditingController _additionalInfoController =
      TextEditingController();

  DateTime? _minDate;
  DateTime? _maxDate;
  TimeOfDay? _minTime;
  TimeOfDay? _maxTime;
  int _capacity = 4;

  DateTime? get minDateTime {
    if (_minDate == null || _minTime == null) return null;
    return _minDate!
        .add(Duration(hours: _minTime!.hour, minutes: _minTime!.minute));
  }

  DateTime? get maxDateTime {
    if (_maxDate == null || _maxTime == null) return null;
    return _maxDate!
        .add(Duration(hours: _maxTime!.hour, minutes: _maxTime!.minute));
  }

  bool get invalidInput {
    final DateTime now = DateTime.now();
    if (minDateTime != null && now.compareTo(minDateTime!) > 0) return true;

    return (minDateTime != null &&
        maxDateTime != null &&
        minDateTime!.compareTo(maxDateTime!) > 0);
  }

  /// Checks if selected date or time resulted in [minDateTime] being greater than [maxDateTime] when [_minDate] and [_maxDate] are equal.
  /// If so, sets [_maxTime] equal to [_minTime] and updates TextField.
  void _timeCheck() {
    if (minDateTime != null &&
        maxDateTime != null &&
        minDateTime!.compareTo(maxDateTime!) > 0) {
      _maxTime = _minTime;
      _maxTimeController.text = _minTime!.format(context);
    }
  }

  void _reset() {
    _minTime = null;
    _maxDate = null;
    _maxTime = null;
    _minTimeController.text = "";
    _maxDateController.text = "";
    _maxTimeController.text = "";
  }

  Future<void> _navigateToConfirmPage(BuildContext context) async {
    final String? result =
        await Navigator.push(context, MaterialPageRoute(builder: (context) {
      return ConfirmPage(
        route: widget.route,
        min: minDateTime!,
        max: maxDateTime!,
        capacity: _capacity,
        info: _additionalInfoController.text.isNotEmpty
            ? _additionalInfoController.text
            : null,
      );
    }));
    if (!mounted) {
      return;
    }
    if (result == null) {
      return;
    } else {
      Navigator.pop(context, result);
    }
  }

  @override
  void dispose() {
    _additionalInfoController.dispose();
    _minDateController.dispose();
    _minTimeController.dispose();
    _maxDateController.dispose();
    _maxTimeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const List<int> capacityList = [1, 2, 3, 4, 5, 6, 7, 8];
    return Scaffold(
        appBar: AppBar(title: Text(AppLocalizations.of(context).app_name)),
        body: SafeArea(
            child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Text(
                                  "${AppLocalizations.of(context).route}:")),
                          Expanded(child: Text(widget.route.toString()))
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                            flex: 2,

                            // https://levelup.gitconnected.com/date-picker-in-flutter-ec6080f3508a

                            child: Padding(
                              padding: const EdgeInsets.only(
                                  top: 8.0, bottom: 8.0, right: 2.0),
                              child: DateSelector(
                                dateController: _minDateController,
                                labelText:
                                    AppLocalizations.of(context).departure_min,
                                hintText:
                                    AppLocalizations.of(context).choose_date,
                                onTap: () async {
                                  DateTime? pickedDate = await showDatePicker(
                                      context: context,
                                      initialEntryMode:
                                          DatePickerEntryMode.calendarOnly,
                                      initialDate: DateTime.now(),
                                      firstDate: DateTime.now(),
                                      lastDate: DateUtils.lastDate);

                                  if (pickedDate != null) {
                                    _minDateController.text =
                                        DateUtils.format(pickedDate);
                                    setState(() {
                                      _minDate = pickedDate;
                                    });

                                    // If selected date results to a datetime in the past, or minDate > maxDate,
                                    // reset all other fields.

                                    if (minDateTime != null &&
                                        DateTime.now().compareTo(minDateTime!) >
                                            0) {
                                      _reset();
                                      return;
                                    }

                                    if (_maxDate != null &&
                                        _minDate!.compareTo(_maxDate!) > 0) {
                                      _reset();
                                      return;
                                    }

                                    if (_maxDate != null &&
                                        _maxDate!.difference(_minDate!).inDays >
                                            2) {
                                      _reset();
                                      return;
                                    }

                                    _timeCheck();

                                    if (!mounted) return;

                                    if (_minTime != null &&
                                        _maxDate == null &&
                                        _maxTime == null) {
                                      _maxDateController.text =
                                          DateUtils.format(pickedDate);
                                      _maxTimeController.text =
                                          _minTime!.format(context);
                                      setState(() {
                                        _maxDate = pickedDate;
                                        _maxTime = _minTime;
                                      });
                                    }
                                  }
                                },
                              ),
                            )),
                        Expanded(
                            flex: 1,
                            child: Padding(
                              padding: const EdgeInsets.only(
                                  top: 8.0, bottom: 8.0, left: 2.0),
                              child: TimeSelector(
                                controller: _minTimeController,
                                hintText:
                                    AppLocalizations.of(context).choose_time,
                                onTap: () async {
                                  TimeOfDay? pickedTime = await showTimePicker(
                                      context: context,
                                      initialTime: TimeOfDay.now());

                                  if (!mounted) return;

                                  if (pickedTime != null) {
                                    if (_minDate != null &&
                                        DateTime.now().compareTo(_minDate!.add(
                                                Duration(
                                                    hours: pickedTime.hour,
                                                    minutes: pickedTime.minute +
                                                        2))) >
                                            0) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(SnackBar(
                                              content: Text(
                                                  AppLocalizations.of(context)
                                                      .time_input_error)));
                                      return;
                                    }
                                    _minTimeController.text =
                                        pickedTime.format(context);
                                    setState(() {
                                      _minTime = pickedTime;
                                    });

                                    _timeCheck();

                                    if (_minDate != null &&
                                        _maxDate == null &&
                                        _maxTime == null) {
                                      _maxDateController.text =
                                          DateUtils.format(_minDate!);
                                      _maxTimeController.text =
                                          pickedTime.format(context);
                                      setState(() {
                                        _maxDate = _minDate;
                                        _maxTime = _minTime;
                                      });
                                    }
                                  }
                                },
                              ),
                            )),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                            flex: 2,
                            child: Padding(
                              padding: const EdgeInsets.only(
                                  top: 8.0, bottom: 8.0, right: 2.0),
                              child: DateSelector(
                                enabled: _maxDate != null,
                                dateController: _maxDateController,
                                labelText:
                                    AppLocalizations.of(context).departure_max,
                                onTap: () async {
                                  DateTime? pickedDate = await showDatePicker(
                                      context: context,
                                      initialEntryMode:
                                          DatePickerEntryMode.calendarOnly,
                                      initialDate: _minDate ?? DateTime.now(),
                                      firstDate: _minDate ?? DateTime.now(),
                                      lastDate: _minDate != null
                                          ? _minDate!
                                              .add(const Duration(days: 2))
                                          : DateTime.now());

                                  if (pickedDate != null) {
                                    _maxDateController.text =
                                        DateUtils.format(pickedDate);
                                    setState(() {
                                      _maxDate = pickedDate;
                                    });
                                    _timeCheck();
                                  }
                                },
                              ),
                            )),
                        Expanded(
                            flex: 1,
                            child: Padding(
                              padding: const EdgeInsets.only(
                                  top: 8.0, bottom: 8.0, left: 2.0),
                              child: TimeSelector(
                                enabled: _maxTime != null,
                                controller: _maxTimeController,
                                onTap: () async {
                                  TimeOfDay? pickedTime = await showTimePicker(
                                      context: context, initialTime: _minTime!);
                                  if (!mounted) return;
                                  if (pickedTime != null) {
                                    _maxTimeController.text =
                                        pickedTime.format(context);

                                    setState(() {
                                      _maxTime = pickedTime;
                                    });
                                    _timeCheck();
                                  }
                                },
                              ),
                            ))
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                              AppLocalizations.of(context).passenger_capacity),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: DropdownButtonHideUnderline(
                              child: DropdownButton(
                                  value: _capacity,
                                  items: capacityList.map((value) {
                                    return DropdownMenuItem(
                                        value: value,
                                        child: Text(value.toString()));
                                  }).toList(),
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() {
                                        _capacity = value;
                                      });
                                    }
                                  })),
                        )
                      ],
                    ),
                    Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextField(
                          maxLength: 200,
                          minLines: 5,
                          maxLines: 5,
                          controller: _additionalInfoController,
                          decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              border: const OutlineInputBorder(),
                              floatingLabelBehavior:
                                  FloatingLabelBehavior.always,
                              labelText:
                                  AppLocalizations.of(context).additional_info,
                              hintText: AppLocalizations.of(context)
                                  .write_additional_info),
                        )),
                  ],
                ),
              ),
            ),
            Container(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: minDateTime != null
                      ? FloatingActionButton(
                          onPressed: () => _navigateToConfirmPage(context),
                          child: const Icon(Icons.arrow_forward),
                        )
                      : null,
                ))
          ],
        )));
  }
}
