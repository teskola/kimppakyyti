import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:kimppakyyti/screens/locations.dart';
import 'package:provider/provider.dart';

import '../models/id.dart';
import '../widgets/profile_image.dart';
import '../providers/auth.dart';
import 'my_rides.dart';
import 'new/new_route.dart';
import 'ride.dart';
import 'search/input.dart';

class NavigationPage extends StatefulWidget {
  const NavigationPage({super.key});

  @override
  State<NavigationPage> createState() => _NavigationPageState();
}

class _NavigationPageState extends State<NavigationPage> {
  /// Navigation index:
  /// 0 = New ride
  /// 1 = Search
  /// 2 = My rides
  /// 3 = Profile
  /// 4 = Saved locations
  /// 5 = Saved routes

  int _selectedIndex = 2;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  Widget _selectPage() {
    switch (_selectedIndex) {
      case 0:
        return NewRoutePage(onRouteAdded: (id) {
          setState(() {
            _selectedIndex = 2;
          });
          Navigator.push(context, MaterialPageRoute(
        builder: (context) {
          return RidePage(Id(driver: FirebaseAuth.instance.currentUser!.uid, ride: id));
        },
      ));
        });
      case 1:
        return const SearchInputPage();
      case 2:
        return const MyRidesPage();        
      case 4:
        return const MyLocationsPage();
      default:
        throw UnimplementedError();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      resizeToAvoidBottomInset: _selectedIndex == 4 ? true : false,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).app_name),
      ),
      drawer: Drawer(
        child: Column(
          children: [
            DrawerHeader(
                child: ListTile(
              leading:
                  ProfileImage(FirebaseAuth.instance.currentUser?.photoURL),
              title: Text(FirebaseAuth.instance.currentUser!.displayName!),
            )),
            Expanded(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.person),
                    title: Text(AppLocalizations.of(context).my_profile),
                    onTap: () {
                      setState(() {
                        _selectedIndex = 3;
                      });
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.location_on),
                    title: Text(AppLocalizations.of(context).saved_locations),
                    onTap: () {
                      setState(() {
                        _selectedIndex = 4;
                        _scaffoldKey.currentState!.closeDrawer();
                      });
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.route),
                    title: Text(AppLocalizations.of(context).saved_routes),
                    onTap: () {
                      setState(() {
                        _selectedIndex = 5;
                      });
                    },
                  )
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: Text(AppLocalizations.of(context).sign_out),
              onTap: () => context.read<AuthProvider>().signOut(),
            )
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
              icon: const Icon(Icons.add),
              label: AppLocalizations.of(context).add_ride),
          BottomNavigationBarItem(
              icon: const Icon(Icons.search),
              label: AppLocalizations.of(context).search_ride),
          BottomNavigationBarItem(
              icon: const Icon(Icons.directions_car),
              label: AppLocalizations.of(context).my_rides)
        ],
        currentIndex: _selectedIndex < 3 ? _selectedIndex : 0,
        selectedItemColor: _selectedIndex < 3 ? Colors.green : Colors.grey[600],
        unselectedItemColor: Colors.grey[600],
        onTap: (value) {
          setState(() {
            _selectedIndex = value;
          });
        },
      ),
      body: SafeArea(child: _selectPage()),
    );
  }
}
