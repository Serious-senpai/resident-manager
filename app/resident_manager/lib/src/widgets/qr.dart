import "package:flutter/material.dart";
import "package:flutter_localization/flutter_localization.dart";
import "package:qr_flutter/qr_flutter.dart";

import "common.dart";
import "../translations.dart";
import "../utils.dart";

class QRPage extends StateAwareWidget {
  const QRPage({super.key, required super.state});

  @override
  State<QRPage> createState() => _QRPageState();
}

class _QRPageState extends AbstractCommonState<QRPage> with CommonScaffoldStateMixin<QRPage> {
  @override
  CommonScaffold<QRPage> build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final resident = state.resident;
    final display = resident == null
        ? Text(AppLocale.NotYetLoggedIn.getString(context))
        : Column(
            children: [
              Text(
                resident.name,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: mediaQuery.size.width < ScreenWidth.SMALL
                        ? 20
                        : mediaQuery.size.width < ScreenWidth.LARGE
                            ? 24
                            : 36),
              ),
              const SizedBox.square(dimension: 10),
              Expanded(child: QrImageView(data: resident.id.toString())),
            ],
          );

    return CommonScaffold.single(
      widgetState: this,
      title: Text(AppLocale.QRCode.getString(context), style: const TextStyle(fontWeight: FontWeight.bold)),
      sliver: SliverFillRemaining(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Center(child: display),
        ),
      ),
    );
  }
}
