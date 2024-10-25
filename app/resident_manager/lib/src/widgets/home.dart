import "dart:math";

import "package:flutter/material.dart";
import "package:flutter_localization/flutter_localization.dart";
import "package:resident_manager/src/utils.dart";

import "common.dart";
import "state.dart";
import "../translations.dart";

class HomePage extends StateAwareWidget {
  const HomePage({super.key, required super.state});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends AbstractCommonState<HomePage> with CommonStateMixin<HomePage> {
  @override
  Scaffold buildScaffold(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar(
        leading: IconButton(
          onPressed: openDrawer,
          icon: const Icon(Icons.menu_outlined),
        ),
        title: Text(AppLocale.Home.getString(context)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(5),
        child: Column(
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    image: DecorationImage(
                      colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.5), BlendMode.darken),
                      image: const AssetImage("assets/landscape.png"),
                      fit: BoxFit.cover,
                    ),
                  ),
                  height: min(0.5 * mediaQuery.size.height, 9 / 16 * constraints.maxWidth),
                  width: constraints.maxWidth,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      // Alignment hack: https://stackoverflow.com/a/54174185
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Builder(
                          builder: (context) {
                            return Text(
                              "${AppLocale.Welcome.getString(context)}, ${state.resident?.name ?? "---"}!",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: mediaQuery.size.width < ScreenWidth.SMALL ? 24 : 48,
                                fontWeight: FontWeight.bold,
                                overflow: TextOverflow.ellipsis,
                              ),
                              textAlign: TextAlign.right,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox.square(dimension: 10),
            Builder(
              builder: (context) {
                final items = [
                  Expanded(
                    child: TextButton.icon(
                      icon: const Icon(Icons.person_outlined),
                      label: Text(AppLocale.PersonalInfo.getString(context)),
                      onPressed: () {
                        // TODO: Implement this
                      },
                    ),
                  ),
                  Expanded(
                    child: TextButton.icon(
                      icon: const Icon(Icons.settings_outlined),
                      label: Text(AppLocale.Settings.getString(context)),
                      onPressed: () {
                        // TODO: Implement this
                      },
                    ),
                  ),
                  Expanded(
                    child: TextButton.icon(
                      icon: const Icon(Icons.construction_outlined),
                      label: Text(AppLocale.ComingSoon.getString(context)),
                      onPressed: null,
                    ),
                  ),
                  Expanded(
                    child: TextButton.icon(
                      icon: const Icon(Icons.construction_outlined),
                      label: Text(AppLocale.ComingSoon.getString(context)),
                      onPressed: null,
                    ),
                  ),
                ];

                final itemsPerRow = mediaQuery.size.width < ScreenWidth.SMALL
                    ? 1
                    : mediaQuery.size.width < ScreenWidth.MEDIUM
                        ? 2
                        : 4;

                return Column(
                  children: [
                    for (var i = 0; i < items.length; i += itemsPerRow) Row(children: items.sublist(i, i + itemsPerRow)),
                  ],
                );
              },
            ),
          ],
        ),
      ),
      drawer: createDrawer(context),
    );
  }
}
