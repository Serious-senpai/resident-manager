import "dart:math";

import "package:flutter/material.dart";
import "package:flutter_localization/flutter_localization.dart";

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
    const padding = 5.0;

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
        padding: const EdgeInsets.all(padding),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                image: DecorationImage(
                  colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.5), BlendMode.darken),
                  image: const AssetImage("assets/landscape.png"),
                  fit: BoxFit.cover,
                ),
              ),
              height: min(0.5 * mediaQuery.size.height, 9 / 16 * (mediaQuery.size.width - 2 * padding)),
              width: mediaQuery.size.width - 2 * padding,
              child: Padding(
                padding: const EdgeInsets.all(2 * padding),
                child: Column(
                  // Alignment hack: https://stackoverflow.com/a/54174185
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "${AppLocale.Welcome.getString(context)}, ${state.authorization?.resident?.name ?? "---"}!",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        overflow: TextOverflow.ellipsis,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ],
                ),
              ),
            ),
            // More stuff here...
          ],
        ),
      ),
      drawer: createDrawer(context),
    );
  }
}
