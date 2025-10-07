import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';

class FadeIn extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final Curve curve;
  final double beginOpacity;
  final double endOpacity;

  const FadeIn({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 350),
    this.delay = Duration.zero,
    this.curve = Curves.easeInOut,
    this.beginOpacity = 0,
    this.endOpacity = 1,
  });

  @override
  State<FadeIn> createState() => _FadeInState();
}

class _FadeInState extends State<FadeIn> {
  double _opacity = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      if (widget.delay > Duration.zero) {
        await Future.delayed(widget.delay);
        if (!mounted) return;
      }
      setState(() => _opacity = 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = context.select<AppState, bool>((s) => s.reduceMotion);
    final targetOpacity = _opacity == 1 ? widget.endOpacity : widget.beginOpacity;
    if (reduceMotion) {
      return Opacity(opacity: targetOpacity == widget.endOpacity ? widget.endOpacity : widget.endOpacity, child: widget.child);
    }
    return AnimatedOpacity(
      opacity: targetOpacity,
      duration: widget.duration,
      curve: widget.curve,
      child: widget.child,
    );
  }
}
