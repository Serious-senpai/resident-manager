import "package:flutter/material.dart";
import "package:flutter_localization/flutter_localization.dart";

import "common.dart";
import "state.dart";
import "../translations.dart";

class PaymentPage extends StateAwareWidget {
  const PaymentPage({super.key, required super.state});

  @override
  PaymentPageState createState() => PaymentPageState();
}

class PaymentPageState extends AbstractCommonState<PaymentPage> with CommonStateMixin<PaymentPage> {
  @override
  CommonScaffold<PaymentPage> build(BuildContext context) {
    return CommonScaffold.single(
      widgetState: this,
      title: Text(AppLocale.Payment.getString(context)),
      sliver: const SliverToBoxAdapter(child: SizedBox.square(dimension: 0)),
    );
  }
}
