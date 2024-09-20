import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_localization/flutter_localization.dart";
import "package:fluttertoast/fluttertoast.dart";
import "package:meta/meta.dart";
import "package:url_launcher/url_launcher.dart";

import "state.dart";
import "../core/state.dart";
import "../core/translations.dart";

mixin SupportsTranslation<T extends StateAwareWidget> on State<T> {
  ApplicationState get state => widget.state;

  @override
  @mustCallSuper
  void initState() {
    state.pushTranslationCallback((Locale? _) => setState(() {}));
    super.initState();
  }

  @override
  @mustCallSuper
  void dispose() {
    state.popTranslationCallback();
    super.dispose();
  }
}

mixin CommonStateMixin<T extends StateAwareWidget> on State<T> {
  /// The [GlobalKey] for the [Scaffold] returned by the [build] method
  final scaffoldKey = GlobalKey<ScaffoldState>();

  /// Whether this route can be popped when pressing the "Back" button
  bool get canPop => true;

  ApplicationState get state => widget.state;

  void refresh() {
    setState(() {});
  }

  @override
  @mustCallSuper
  void initState() {
    state.pushTranslationCallback((Locale? _) => refresh());
    super.initState();
  }

  @override
  @mustCallSuper
  void dispose() {
    state.popTranslationCallback();
    super.dispose();
  }

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

  /// Create a default [Drawer] for all pages within this application
  Drawer createDrawer(BuildContext context) {
    var currentRoute = ModalRoute.of(context)?.settings.name;
    return Drawer(
      child: Stack(
        children: [
          ListView(
            children: [
              const DrawerHeader(
                decoration: BoxDecoration(image: DecorationImage(image: AssetImage("assets/apartment.png"), fit: BoxFit.cover)),
                child: null,
              ),
              ListTile(
                leading: const Icon(Icons.lock),
                title: Text(
                  AppLocale.Login.getString(context),
                  style: currentRoute == "/login" ? const TextStyle(color: Colors.blue) : null,
                ),
                onTap: () => currentRoute == "/login" ? Navigator.pop(context) : Navigator.pushReplacementNamed(context, "/login"),
              ),
            ],
          ),
          Positioned(
            bottom: 5,
            left: 5,
            child: Row(
              children: [
                IconButton(
                  icon: Image.asset("assets/github/github-mark.png", height: 20, width: 20),
                  iconSize: 20,
                  onPressed: () async {
                    var launched = false;
                    try {
                      launched = await launchUrl(Uri.parse("https://github.com/Serious-senpai/resident-manager"));
                    } on PlatformException {
                      // pass
                    }

                    if (!launched) {
                      await Fluttertoast.showToast(msg: "Unable to open URL");
                    }
                  },
                  padding: EdgeInsets.zero,
                ),
                const SizedBox.square(dimension: 20),
                IconButton(
                  icon: Image.asset("assets/flags/en.png", height: 20, width: 20),
                  iconSize: 20,
                  onPressed: () => state.localization.translate("en"),
                  padding: EdgeInsets.zero,
                ),
                const SizedBox.square(dimension: 20),
                IconButton(
                  icon: Image.asset("assets/flags/vi.png", height: 20, width: 20),
                  iconSize: 20,
                  onPressed: () => state.localization.translate("vi"),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
