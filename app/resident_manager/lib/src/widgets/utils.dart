import "package:flutter/material.dart";
import "package:flutter_localization/flutter_localization.dart";

import "../translations.dart";

class HoverContainer extends StatefulWidget {
  final Color onHover;
  final Widget child;

  const HoverContainer({super.key, required this.onHover, required this.child});

  @override
  State<HoverContainer> createState() => _HoverContainerState();
}

class _HoverContainerState extends State<HoverContainer> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Container(
        decoration: BoxDecoration(
          color: _hovered ? widget.onHover : null,
        ),
        child: widget.child,
      ),
    );
  }
}

class SliverCircularProgressFullScreen extends StatelessWidget {
  const SliverCircularProgressFullScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox.square(
              dimension: 50,
              child: CircularProgressIndicator(),
            ),
            const SizedBox.square(dimension: 5),
            Text(AppLocale.Loading.getString(context)),
          ],
        ),
      ),
    );
  }
}
