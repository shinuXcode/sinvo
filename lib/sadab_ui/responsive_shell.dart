import 'package:flutter/material.dart';

class ShellDestination {
  const ShellDestination(this.label, this.icon, this.selectedIcon);
  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

/// Phone (<720dp): bottom NavigationBar. Tablet/desktop: NavigationRail,
/// extended (with labels) from 1100dp. Pages stay alive via IndexedStack.
class ResponsiveShell extends StatefulWidget {
  const ResponsiveShell({super.key, required this.destinations, required this.pages})
      : assert(destinations.length == pages.length);

  final List<ShellDestination> destinations;
  final List<Widget> pages;

  static const defaultDestinations = [
    ShellDestination('Home', Icons.dashboard_outlined, Icons.dashboard),
    ShellDestination('Products', Icons.inventory_2_outlined, Icons.inventory_2),
    ShellDestination('Billing', Icons.point_of_sale_outlined, Icons.point_of_sale),
    ShellDestination('Stock', Icons.move_to_inbox_outlined, Icons.move_to_inbox),
    ShellDestination('Reports', Icons.bar_chart_outlined, Icons.bar_chart),
    ShellDestination('Settings', Icons.settings_outlined, Icons.settings),
  ];

  @override
  State<ResponsiveShell> createState() => _ResponsiveShellState();
}

class _ResponsiveShellState extends State<ResponsiveShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final body = IndexedStack(index: _index, children: widget.pages);
    return LayoutBuilder(builder: (context, c) {
      if (c.maxWidth >= 720) {
        return Scaffold(
          body: SafeArea(
            child: Row(children: [
              NavigationRail(
                selectedIndex: _index,
                extended: c.maxWidth >= 1100,
                labelType: c.maxWidth >= 1100
                    ? NavigationRailLabelType.none
                    : NavigationRailLabelType.all,
                onDestinationSelected: (i) => setState(() => _index = i),
                destinations: [
                  for (final d in widget.destinations)
                    NavigationRailDestination(
                      icon: Icon(d.icon),
                      selectedIcon: Icon(d.selectedIcon),
                      label: Text(d.label),
                    ),
                ],
              ),
              const VerticalDivider(width: 1),
              Expanded(child: body),
            ]),
          ),
        );
      }
      return Scaffold(
        body: SafeArea(child: body),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          // Six items on a 360dp screen: only label the selected one so the
          // bar never overflows.
          labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: [
            for (final d in widget.destinations)
              NavigationDestination(
                icon: Icon(d.icon),
                selectedIcon: Icon(d.selectedIcon),
                label: d.label,
                tooltip: d.label,
              ),
          ],
        ),
      );
    });
  }
}
