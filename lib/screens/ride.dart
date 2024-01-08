import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:kimppakyyti/models/id.dart';
import 'package:kimppakyyti/providers/user.dart';
import 'package:kimppakyyti/widgets/profile_image.dart';
import 'package:provider/provider.dart';

class RouteScreen extends StatelessWidget {
  const RouteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    throw UnimplementedError();
  }
}

class Driver extends StatelessWidget {
  final Id id;
  const Driver(this.id, {super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: context.read<UserProvider>().get(id.driver),
      builder: (_, snapshot) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              ProfileImage(snapshot.data?.image, radius: 36),
              Expanded(
                  child: Align(
                      child: Text(snapshot.hasData ? snapshot.data!.name : '')))
            ],
          ),
        );
      },
    );
  }
}

class RidePage extends StatelessWidget {
  final Id id;
  const RidePage(this.id, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).app_name),
      ),
      body: SafeArea(
          child: SingleChildScrollView(
        child: Column(children: [Driver(id)]),
      )),
    );
  }
}
