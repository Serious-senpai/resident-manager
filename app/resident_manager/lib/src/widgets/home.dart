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
  CommonScaffold<HomePage> build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    return CommonScaffold.single(
      widgetState: this,
      title: Text(AppLocale.Home.getString(context), style: const TextStyle(fontWeight: FontWeight.bold)),
      sliver: SliverPadding(
        padding: const EdgeInsets.all(5),
        sliver: SliverList.list(
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    image: DecorationImage(
                      image: const AssetImage("assets/vector-background-blue.png"),
                      colorFilter: ColorFilter.mode(
                        Colors.black.withOpacity(0.3),
                        BlendMode.srcOver,
                      ),
                      fit: BoxFit.cover,
                    ),
                  ),
                  height: min(0.5 * mediaQuery.size.height, 9 / 16 * constraints.maxWidth),
                  padding: const EdgeInsets.all(20),
                  width: constraints.maxWidth,
                  child: Column(
                    // Alignment hack: https://stackoverflow.com/a/54174185
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "${AppLocale.Welcome.getString(context)}, ${state.resident?.name ?? "---"}!",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: mediaQuery.size.width < ScreenWidth.LARGE ? 24 : 36,
                          fontWeight: FontWeight.bold,
                          overflow: TextOverflow.ellipsis,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ],
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
                      onPressed: () async {
                        await pushNamedAndRefresh(context, ApplicationRoute.personalInfo);
                      },
                    ),
                  ),
                  Expanded(
                    child: TextButton.icon(
                      icon: const Icon(Icons.receipt_long_outlined),
                      label: Text(AppLocale.Payment.getString(context)),
                      onPressed: () async {
                        await pushNamedAndRefresh(context, ApplicationRoute.payment);
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
          ],
        ),
      ),
    );
  }
}
