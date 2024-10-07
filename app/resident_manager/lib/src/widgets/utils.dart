import "package:flutter/material.dart";

import "common.dart";
import "state.dart";

class TranslatedText extends StateAwareWidget {
  final String Function(BuildContext context) createText;
  final TextStyle? style;
  final StrutStyle? strutStyle;
  final TextAlign? textAlign;
  final TextDirection? textDirection;
  final Locale? locale;
  final bool? softWrap;
  final TextOverflow? overflow;
  final TextScaler? textScaler;
  final int? maxLines;
  final String? semanticsLabel;
  final TextWidthBasis? textWidthBasis;
  final TextHeightBehavior? textHeightBehavior;
  final Color? selectionColor;

  const TranslatedText(
    this.createText, {
    super.key,
    required super.state,
    this.style,
    this.strutStyle,
    this.textAlign,
    this.textDirection,
    this.locale,
    this.softWrap,
    this.overflow,
    this.textScaler,
    this.maxLines,
    this.semanticsLabel,
    this.textWidthBasis,
    this.textHeightBehavior,
    this.selectionColor,
  });

  @override
  TranslatedTextState createState() => TranslatedTextState();
}

class TranslatedTextState extends AbstractCommonState<TranslatedText> {
  @override
  Widget build(BuildContext context) => Text(
        widget.createText(context),
        style: widget.style,
        strutStyle: widget.strutStyle,
        textAlign: widget.textAlign,
        textDirection: widget.textDirection,
        locale: widget.locale,
        softWrap: widget.softWrap,
        overflow: widget.overflow,
        maxLines: widget.maxLines,
        semanticsLabel: widget.semanticsLabel,
        textWidthBasis: widget.textWidthBasis,
        textHeightBehavior: widget.textHeightBehavior,
        selectionColor: widget.selectionColor,
      );
}

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
