import "package:flutter/material.dart";
import "package:flutter_localization/flutter_localization.dart";

import "state.dart";
import "../routes.dart";
import "../state.dart";
import "../translations.dart";

abstract class AbstractCommonState<T extends StateAwareWidget> extends State<T> {
  ApplicationState get state => widget.state;

  void refresh() {
    if (mounted) setState(() {});
  }

  /// Push a named route, wait for it to return and refresh our current state.
  ///
  /// Use this method instead of the usual [Navigator.pushNamed] inside [StatefulWidget] states.
  ///
  /// Why do we need to refresh the current state? Suppose we are at initial route A and perform a `Navigator.pushNamed` to
  /// route B. At this point, the Navigator stack will be [A, B]. Now, if the user resizes the current window (other
  /// actions may also trigger this effect), *the entire navigation stack will be rebuilt*. This means that route A
  /// will evaluate `canPop = Navigator.canPop(context)` to `true`, thus create a back button in its app bar. When popping
  /// route B, if we don't rebuild route A, the back button will still be there, and clicking it will empty the navigation
  /// stack, leaving the user with a blank screen. This is why we need to refresh the current state when returning from B.
  Future<RT?> pushNamedAndRefresh<RT extends Object?>(BuildContext context, String route) async {
    final result = await Navigator.pushNamed<RT>(context, route);
    refresh();
    return result;
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
  @override
  CommonScaffold<T> build(BuildContext context);
}

class CommonScaffold<T extends StateAwareWidget> extends StatefulWidget {
  final CommonStateMixin<T> widgetState;
  final Widget title;
  final List<Widget> slivers;

  const CommonScaffold({
    super.key,
    required this.widgetState,
    required this.title,
    required this.slivers,
  });

  CommonScaffold.single({
    super.key,
    required this.widgetState,
    required this.title,
    required Widget sliver,
  }) : slivers = [sliver];

  @override
  State<CommonScaffold<T>> createState() => _CommonScaffoldState<T>();
}

class _CommonScaffoldState<T extends StateAwareWidget> extends State<CommonScaffold<T>> {
  /// The [GlobalKey] for the underlying [Scaffold]
  final scaffoldKey = GlobalKey<ScaffoldState>();

  final _scrollController = ScrollController();

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

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.canPop(context);
    return Scaffold(
      key: scaffoldKey,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverAppBar(
            flexibleSpace: FlexibleSpaceBar(
              background: Image.asset(
                "assets/vector-background-blue.png",
                fit: BoxFit.cover,
              ),
            ),
            floating: true,
            pinned: false,
            snap: false,
            leading: canPop
                ? IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_outlined),
                  )
                : IconButton(
                    onPressed: () => openDrawer(),
                    icon: const Icon(Icons.menu_outlined),
                  ),
            title: widget.title,
          ),
          ...widget.slivers,
        ],
      ),
      floatingActionButton: Opacity(
        opacity: 0.5,
        child: FloatingActionButton(
          backgroundColor: Colors.lightBlue,
          foregroundColor: Colors.white,
          onPressed: () {
            _scrollController.animateTo(
              _scrollController.position.minScrollExtent,
              curve: Curves.easeOut,
              duration: const Duration(milliseconds: 500),
            );
          },
          child: const Icon(Icons.arrow_upward_outlined),
        ),
      ),
      onDrawerChanged: (isOpened) {
        if (!isOpened) {
          widget.widgetState.refresh();
        }
      },
      drawer: Builder(
        builder: (context) {
          final currentRoute = ModalRoute.of(context)?.settings.name;
          final state = widget.widgetState.state;
          final navigator = <Widget>[
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.grey),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const CircleAvatar(child: Icon(Icons.account_circle_outlined)),
                    Text(state.loggedInAsAdmin ? AppLocale.Admin.getString(context) : state.resident?.name ?? AppLocale.NotYetLoggedIn.getString(context)),
                  ],
                ),
              ),
            ),
          ];

          Widget routeTile({
            required Icon leading,
            required String title,
            required String route,
            required bool popAll,
          }) =>
              ListTile(
                leading: leading,
                title: Text(
                  title,
                  style: currentRoute == route ? const TextStyle(color: Colors.blue) : null,
                ),
                onTap: () {
                  closeDrawer();
                  if (currentRoute != route) {
                    if (popAll) {
                      Navigator.popUntil(context, (route) => route.isFirst);
                      Navigator.pushReplacementNamed(context, route);
                    } else {
                      widget.widgetState.pushNamedAndRefresh(context, route);
                    }
                  }
                },
              );

          if (!widget.widgetState.state.loggedIn) {
            // Not yet logged in
            navigator.add(
              routeTile(
                leading: const Icon(Icons.lock_outlined),
                title: AppLocale.Login.getString(context),
                route: ApplicationRoute.login,
                popAll: true,
              ),
            );
          } else {
            // Logged in...
            if (widget.widgetState.state.loggedInAsAdmin) {
              // ... as admin
              navigator.addAll(
                [
                  routeTile(
                    leading: const Icon(Icons.how_to_reg_outlined),
                    title: AppLocale.RegisterQueue.getString(context),
                    route: ApplicationRoute.adminRegisterQueue,
                    popAll: false,
                  ),
                  routeTile(
                    leading: const Icon(Icons.people_outlined),
                    title: AppLocale.ResidentsList.getString(context),
                    route: ApplicationRoute.adminResidentsPage,
                    popAll: false,
                  ),
                  routeTile(
                    leading: const Icon(Icons.room_outlined),
                    title: AppLocale.RoomsList.getString(context),
                    route: ApplicationRoute.adminRoomsPage,
                    popAll: false,
                  ),
                ],
              );
            } else {
              // ... as resident
              navigator.addAll(
                [
                  routeTile(
                    leading: const Icon(Icons.home_outlined),
                    title: AppLocale.Home.getString(context),
                    route: ApplicationRoute.home,
                    popAll: false,
                  ),
                  routeTile(
                    leading: const Icon(Icons.person_outlined),
                    title: AppLocale.PersonalInfo.getString(context),
                    route: ApplicationRoute.personalInfo,
                    popAll: false,
                  ),
                ],
              );
            }

            navigator.add(
              ListTile(
                leading: const Icon(Icons.logout_outlined),
                title: Text(AppLocale.Logout.getString(context)),
                onTap: () async {
                  await widget.widgetState.state.deauthorize();
                  if (context.mounted) {
                    Navigator.popUntil(context, (route) => route.isFirst);
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
                        icon: Image.asset("assets/flags/en.png", height: 20, width: 20),
                        iconSize: 20,
                        onPressed: () => widget.widgetState.state.localization.translate("en"),
                        padding: EdgeInsets.zero,
                      ),
                      const SizedBox.square(dimension: 20),
                      IconButton(
                        icon: Image.asset("assets/flags/vi.png", height: 20, width: 20),
                        iconSize: 20,
                        onPressed: () => widget.widgetState.state.localization.translate("vi"),
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
