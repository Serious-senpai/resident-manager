import "package:flutter/material.dart";
import "package:flutter_localization/flutter_localization.dart";

import "../common.dart";
import "../state.dart";
import "../../core/translations.dart";

class ResidentsPage extends StateAwareWidget {
  const ResidentsPage({super.key, required super.state});

  @override
  ResidentsPageState createState() => ResidentsPageState();
}

class ResidentsPageState extends AbstractCommonState<ResidentsPage> with CommonStateMixin<ResidentsPage> {
  @override
  Scaffold buildScaffold(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar(
        backgroundColor: Colors.blue,
        leading: IconButton(
          onPressed: openDrawer,
          icon: const Icon(Icons.menu_outlined),
        ),
        title: Text(AppLocale.ResidentsList.getString(context)),
      ),
      drawer: createDrawer(context),
    );
  }
}
