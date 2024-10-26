import "dart:math";

import "package:flutter/material.dart";
import "package:flutter_localization/flutter_localization.dart";

import "common.dart";
import "state.dart";
import "../routes.dart";
import "../translations.dart";
import "../utils.dart";

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
      appBar: createAppBar(context, title: AppLocale.Home.getString(context)),
      body: Builder(builder: (context) {
        final children = [
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
          Builder(
            builder: (context) {
              final items = [
                Expanded(
                  child: TextButton.icon(
                    icon: const Icon(Icons.person_outlined),
                    label: Text(AppLocale.PersonalInfo.getString(context)),
                    onPressed: () => Navigator.pushReplacementNamed(context, ApplicationRoute.personalInfo),
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

              final rows = mediaQuery.size.width < ScreenWidth.SMALL
                  ? [
                      [0],
                      [1],
                      [2],
                      [3],
                    ]
                  : mediaQuery.size.width < ScreenWidth.MEDIUM
                      ? [
                          [0, 1],
                          [2, 3],
                        ]
                      : [
                          [0, 1, 2, 3],
                        ];

              return Column(
                children: List<Widget>.from(
                  rows.map(
                    (row) => Row(
                      children: List<Widget>.from(
                        row.map(
                          (i) => items[i],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ];

        return Column(
          children: List<Widget>.from(
            children.map(
              (w) => Padding(
                padding: const EdgeInsets.all(8),
                child: w,
              ),
            ),
          ),
        );
      }),
      drawer: createDrawer(context),
    );
  }
}
