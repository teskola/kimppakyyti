import 'package:flutter/material.dart' hide DateUtils;
import 'package:flutter/scheduler.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:kimppakyyti/providers/location.dart';
import 'package:kimppakyyti/screens/search/results.dart';
import 'package:provider/provider.dart';
import '../map.dart';
import '../../widgets/date_selector.dart';
import '../../widgets/locations_textfield.dart';
import '../../models/location.dart';
import '../../utilities/date_utils.dart';

class SearchInputPage extends StatefulWidget {
  const SearchInputPage({super.key});

  @override
  State<SearchInputPage> createState() => _SearchInputPageState();
}

class _SearchInputPageState extends State<SearchInputPage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _startController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  final GlobalKey<LocationsTextFieldState> _startTextField = GlobalKey();
  final GlobalKey<LocationsTextFieldState> _destinationTextField = GlobalKey();
  double? _textfieldHeight;
  DateTime? _date;

  double _getTextFieldHeight() {
    final RenderBox renderBox =
        _destinationTextField.currentContext?.findRenderObject() as RenderBox;
    return renderBox.size.height;
  }

  Future<void> _navigateToMap(BuildContext context) async {
    final List<Point?>? result =
        await Navigator.push(context, MaterialPageRoute(builder: ((context) {
      return MapPage(
        start: _startTextField.currentState?.selectedLocation,
        destination: _destinationTextField.currentState?.selectedLocation,
        mode: MapMode.endPointsOnly,
      );
    })));
    if (!mounted) return;
    if (result == null) return;
    setState(() {
      _startTextField.currentState!.updateTextField(result[0]);
      _destinationTextField.currentState!.updateTextField(result[1]);
    });
  }

  Future<void> _navigateToResults(BuildContext context) async {
    await Navigator.push(context, MaterialPageRoute(builder: ((context) {
      return SearchResultsPage(
          date: _date!,
          start: _startTextField.currentState!.selectedLocation!,
          destination: _destinationTextField.currentState!.selectedLocation!);
    })));
  }

  @override
  initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _textfieldHeight = _getTextFieldHeight();
      });
    });
  }

  @override
  dispose() {
    _scrollController.dispose();
    _dateController.dispose();
    _startController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<LocationProvider>();
    return Column(
      children: [
        Expanded(child: LayoutBuilder(builder: (context, constraints) {
          return SizedBox(
            height: constraints.maxHeight,
            child: SingleChildScrollView(
              controller: _scrollController,
              // Padding to keep last widget on top of screen, when scrolled down.
              padding: EdgeInsets.only(
                  top: 8.0,
                  bottom: (_textfieldHeight != null &&
                          constraints.maxHeight > _textfieldHeight!)
                      ? constraints.maxHeight - _textfieldHeight!
                      : 0),
              child: Column(
                children: [
                  ListTile(
                    title: DateSelector(
                      dateController: _dateController,
                      onTap: () async {
                        DateTime? pickedDate = await showDatePicker(
                            context: context,
                            initialEntryMode: DatePickerEntryMode.calendarOnly,
                            initialDate: DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateUtils.lastDate);
                        if (pickedDate != null) {
                          setState(() {
                            _date = pickedDate;
                            _dateController.text = DateUtils.format(pickedDate);
                          });
                        }
                      },
                    ),
                  ),
                  LocationsTextFieldListItem(
                    controller: _startController,
                    onLocationSelected: ((_) {
                      setState(() {});
                    }),
                    onFocusLost: () {
                      _scrollController.jumpTo(0);
                    },
                    stage: 0,
                    textfieldKey: _startTextField,
                  ),
                  LocationsTextFieldListItem(
                    stage: 1,
                    controller: _destinationController,
                    onLocationSelected: ((_) {
                      setState(() {});
                    }),
                    onFocusLost: () {
                      _scrollController.jumpTo(0);
                    },
                    textfieldKey: _destinationTextField,
                  ),
                ],
              ),
            ),
          );
        })),
        Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                    onPressed: () => _navigateToMap(context),
                    icon: const Icon(Icons.location_on),
                    label: Text(AppLocalizations.of(context).choose_from_map)),
                Visibility(
                    visible: _startTextField.currentState?.selectedLocation !=
                            null &&
                        _destinationTextField.currentState?.selectedLocation !=
                            null &&
                        _date != null,
                    child: FloatingActionButton(
                      onPressed: () => _navigateToResults(context),
                      child: const Icon(Icons.arrow_forward),
                    ))
              ],
            )),
      ],
    );
  }
}
