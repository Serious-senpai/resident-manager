import "package:flutter/material.dart";
import "package:flutter_localization/flutter_localization.dart";

import "../common.dart";
import "../state.dart";
import "../../translations.dart";

class AdminHomePage extends StateAwareWidget {
  const AdminHomePage({super.key, required super.state});

  @override
  AbstractCommonState<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends AbstractCommonState<AdminHomePage> with CommonStateMixin<AdminHomePage> {
  @override
  CommonScaffold<AdminHomePage> build(BuildContext context) {
    return CommonScaffold.single(
      widgetState: this,
      title: Text(AppLocale.Home.getString(context), style: const TextStyle(fontWeight: FontWeight.bold)),
      sliver: const DecoratedSliver(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/vector-background-white.png"),
            repeat: ImageRepeat.repeat,
          ),
        ),
        sliver: SliverPadding(
          padding: EdgeInsets.all(10),
          sliver: SliverToBoxAdapter(
            child: SizedBox.square(dimension: 500),
          ),
        ),
      ),
    );
  }
}
