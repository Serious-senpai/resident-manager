import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_localization/flutter_localization.dart";
import "package:meta/meta.dart";
import "package:url_launcher/url_launcher.dart";

import "state.dart";
import "../routes.dart";
import "../utils.dart";
import "../core/state.dart";
import "../core/translations.dart";

abstract class AbstractCommonState<T extends StateAwareWidget> extends State<T> {
  ApplicationState get state => widget.state;

  void refresh() {
    setState(() {});
  }

  @override
  @mustCallSuper
  void initState() {
    state.pushTranslationCallback((_) => refresh());
    super.initState();
  }

  @override
  @mustCallSuper
  void dispose() {
    state.popTranslationCallback();
    super.dispose();
  }
}

mixin CommonStateMixin<T extends StateAwareWidget> on AbstractCommonState<T> {
  /// The [GlobalKey] for the [Scaffold] returned by the [build] method
  final scaffoldKey = GlobalKey<ScaffoldState>();

  /// Whether this route can be popped when pressing the "Back" button
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

  /// Create a default [Drawer] for all pages within this application
  Drawer createDrawer(BuildContext context) {
    var currentRoute = ModalRoute.of(context)?.settings.name;

    final navigator = <Widget>[
      const DrawerHeader(
        decoration: BoxDecoration(image: DecorationImage(image: AssetImage("assets/apartment.png"), fit: BoxFit.cover)),
        child: null,
      ),
    ];

    final authorization = state.authorization;
    if (authorization == null) {
      navigator.add(
        ListTile(
          leading: const Icon(Icons.lock_outlined),
          title: Text(
            AppLocale.Login.getString(context),
            style: currentRoute == ApplicationRoute.login ? const TextStyle(color: Colors.blue) : null,
          ),
          onTap: () => currentRoute == ApplicationRoute.login
              ? Navigator.pop(context)
              : Navigator.pushReplacementNamed(
                  context,
                  ApplicationRoute.login,
                ),
        ),
      );
    } else {
      if (authorization.isAdmin) {
        navigator.addAll(
          [
            ListTile(
              leading: const Icon(Icons.how_to_reg_outlined),
              title: Text(
                AppLocale.RegisterQueue.getString(context),
                style: currentRoute == ApplicationRoute.adminRegisterQueue ? const TextStyle(color: Colors.blue) : null,
              ),
              onTap: () => currentRoute == ApplicationRoute.adminRegisterQueue
                  ? Navigator.pop(context)
                  : Navigator.pushReplacementNamed(
                      context,
                      ApplicationRoute.adminRegisterQueue,
                    ),
            ),
          ],
        );
      } else {
        navigator.addAll(
          [
            ListTile(
              leading: const Icon(Icons.home_outlined),
              title: Text(
                AppLocale.Home.getString(context),
                style: currentRoute == ApplicationRoute.home ? const TextStyle(color: Colors.blue) : null,
              ),
              onTap: () => currentRoute == ApplicationRoute.home
                  ? Navigator.pop(context)
                  : Navigator.pushReplacementNamed(
                      context,
                      ApplicationRoute.home,
                    ),
            ),
          ],
        );
      }

      navigator.add(
        ListTile(
          leading: const Icon(Icons.logout_outlined),
          title: Text(AppLocale.Logout.getString(context)),
          onTap: () async {
            await state.deauthorize();
            if (context.mounted) {
              await Navigator.pushReplacementNamed(context, ApplicationRoute.login);
            }
          },
        ),
      );
    }

    return Drawer(
      child: Stack(
        children: [
          ListView(children: navigator),
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
                      await showToastSafe(
                        msg: context.mounted ? AppLocale.UnableToOpenUrl.getString(context) : AppLocale.UnableToOpenUrl,
                      );
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
