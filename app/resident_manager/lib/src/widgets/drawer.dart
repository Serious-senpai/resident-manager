import "package:flutter/material.dart";
import "package:meta/meta.dart";
import "package:url_launcher/url_launcher.dart";

import "../core/state.dart";

/// Mixin on a [State] of a [StatefulWidget] that allows opening and closing a
/// drawer in a [Scaffold]
///
/// The [buildScaffold] method should return a [Scaffold] with its [Scaffold.key]
/// set to [scaffoldKey]
mixin PageStateWithDrawer<T extends StatefulWidget> on State<T> {
  /// The [GlobalKey] for the [Scaffold] returned by the [build] method
  final scaffoldKey = GlobalKey<ScaffoldState>();

  bool get canPop => true;

  /// Open the [Scaffold.drawer]
  void openDrawer() {
    final state = scaffoldKey.currentState;
    if (state != null) state.openDrawer();
  }

  /// Close the [Scaffold.drawer]
  void closeDrawer() {
    final state = scaffoldKey.currentState;
    if (state != null) state.closeDrawer();
  }

  Scaffold buildScaffold(BuildContext context);

  @nonVirtual
  @override
  Widget build(BuildContext context) {
    final scaffold = buildScaffold(context);
    assert(scaffold.key == scaffoldKey);
    assert(scaffold.drawer != null);
    return PopScope(
      canPop: canPop,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          openDrawer();
        }
      },
      child: scaffold,
    );
  }
}

/// Create a default [Drawer] for all pages within this application
Drawer createDrawer({required BuildContext context, required ApplicationState state}) {
  var currentRoute = ModalRoute.of(context)?.settings.name;
  return Drawer(
    child: Stack(
      children: [
        ListView(
          children: [
            const DrawerHeader(child: Text("Resident manager", style: TextStyle(fontWeight: FontWeight.bold))),
            ListTile(
              leading: const Icon(Icons.lock),
              title: Text("Login", style: currentRoute == "/login" ? const TextStyle(color: Colors.blue) : null),
              onTap: () => currentRoute == "/login" ? Navigator.pop(context) : Navigator.pushReplacementNamed(context, "/login"),
            ),
          ],
        ),
        Positioned(
          bottom: 5,
          left: 5,
          child: IconButton(
            icon: Image.asset("assets/github-mark-white.png"),
            iconSize: 15,
            onPressed: () => launchUrl(Uri.parse("https://github.com/Serious-senpai/resident-manager")),
          ),
        ),
      ],
    ),
  );
}
