import "package:flutter/material.dart";
import "package:flutter_localization/flutter_localization.dart";

import "../common.dart";
import "../state.dart";
import "../../core/translations.dart";

class RegisterQueuePage extends StateAwareWidget {
  const RegisterQueuePage({super.key, required super.state});

  @override
  RegisterQueuePageState createState() => RegisterQueuePageState();
}

class RegisterQueuePageState extends AbstractCommonState<RegisterQueuePage> with CommonStateMixin<RegisterQueuePage> {
  @override
  Scaffold buildScaffold(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar(
        leading: IconButton(
          onPressed: openDrawer,
          icon: const Icon(Icons.how_to_reg_outlined),
        ),
        title: Text(AppLocale.RegisterQueue.getString(context)),
      ),
      drawer: createDrawer(context),
    );
  }
}
