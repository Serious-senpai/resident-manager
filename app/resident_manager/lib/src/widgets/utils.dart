import "package:flutter/material.dart";

class HoverContainer extends StatefulWidget {
  final Color onHover;
  final Widget child;

  const HoverContainer({super.key, required this.onHover, required this.child});

  @override
  HoverContainerState createState() => HoverContainerState();
}

class HoverContainerState extends State<HoverContainer> {
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
