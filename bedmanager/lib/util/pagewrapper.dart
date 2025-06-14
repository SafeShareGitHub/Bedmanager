import 'package:flutter/material.dart';
import 'package:bedmanager/Screens/home.dart';
import 'package:bedmanager/Screens/page2.dart'; // Atlantic
import 'package:bedmanager/Screens/page3.dart'; // Harmony
import 'package:bedmanager/Screens/page4.dart'; // Neptune
import 'package:bedmanager/Screens/page5.dart'; // Ocean
import 'package:bedmanager/Screens/page6.dart'; // Pacific
import 'package:bedmanager/Screens/page7.dart'; // Peace
import 'package:bedmanager/Screens/page8.dart'; // Sunlight
import 'package:bedmanager/Screens/page9.dart'; // Sunrise
import 'package:bedmanager/Screens/page10.dart'; // Sunray
import 'package:bedmanager/Screens/page11.dart'; // Sunset
import 'package:bedmanager/Screens/page12.dart'; // Sunshine
import 'package:bedmanager/Screens/page13.dart'; // Sunday

class PageWrapper extends StatefulWidget {
  final int currentPage;
  final bool isExpanded;

  PageWrapper({required this.currentPage, this.isExpanded = false});

  @override
  _PageWrapperState createState() => _PageWrapperState();
}

class _PageWrapperState extends State<PageWrapper> {
  late bool isExpanded;

  @override
  void initState() {
    super.initState();
    isExpanded = widget.isExpanded;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: widget.currentPage,
            onDestinationSelected: (index) {
              if (index != widget.currentPage) {
                _navigateToPage(context, index);
              }
            },
            extended: isExpanded,
            backgroundColor: Colors.blue.shade100,
            selectedIconTheme: IconThemeData(color: Colors.blue, size: 32),
            unselectedIconTheme: IconThemeData(color: Colors.grey, size: 24),
            selectedLabelTextStyle: TextStyle(
              color: Colors.blue,
              fontWeight: FontWeight.bold,
            ),
            unselectedLabelTextStyle: TextStyle(color: Colors.grey),
            leading: Column(
              children: [
                SizedBox(height: 16),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        isExpanded ? Icons.arrow_back : Icons.arrow_forward,
                        color: Colors.blue,
                      ),
                      onPressed: () => setState(() => isExpanded = !isExpanded),
                    ),
                    if (isExpanded)
                      Text(
                        "Bedmanager",
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                  ],
                ),
              ],
            ),
            destinations: [
              NavigationRailDestination(
                icon: Icon(Icons.home),
                label: Text('Home'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.water),
                label: Text('Atlantic'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.spa),
                label: Text('Harmony'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.water_damage),
                label: Text('Neptune'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.sailing),
                label: Text('Ocean'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.landscape),
                label: Text('Pacific'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.self_improvement),
                label: Text('Peace'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.wb_sunny),
                label: Text('Sunlight'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.brightness_5),
                label: Text('Sunrise'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.brightness_7),
                label: Text('Sunray'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.brightness_3),
                label: Text('Sunset'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.wb_incandescent),
                label: Text('Sunshine'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.calendar_today),
                label: Text('Sunday'),
              ),
            ],
          ),
          Expanded(
            child: _getPageContent(widget.currentPage),
          ),
        ],
      ),
    );
  }

  void _navigateToPage(BuildContext context, int index) {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => PageWrapper(
          currentPage: index,
          isExpanded: isExpanded,
        ),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  Widget _getPageContent(int page) {
    switch (page) {
      case 0:
        return HomeScreen();
      case 1:
        return Atlantic();
      case 2:
        return Harmony();
      case 3:
        return Neptune();
      case 4:
        return Ocean();
      case 5:
        return Pacific();
      case 6:
        return Peace();
      case 7:
        return Sunlight();
      case 8:
        return Sunrise();
      case 9:
        return Sunray();
      case 10:
        return Sunset();
      case 11:
        return Sunshine();
      case 12:
        return Sunday();
      default:
        return Center(child: Text('Página não encontrada'));
    }
  }
}
