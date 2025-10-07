import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';

class SlideFadeIn extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final Curve curve;
  final Offset beginOffset;
  final Offset endOffset;
  final double beginOpacity;
  final double endOpacity;

  const SlideFadeIn({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 350),
    this.delay = Duration.zero,
    this.curve = Curves.easeOutCubic,
    this.beginOffset = const Offset(0, 0.08),
    this.endOffset = Offset.zero,
    this.beginOpacity = 0,
    this.endOpacity = 1,
  });

  @override
  State<SlideFadeIn> createState() => _SlideFadeInState();
}

class _SlideFadeInState extends State<SlideFadeIn> {
  bool _show = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      if (widget.delay > Duration.zero) {
        await Future.delayed(widget.delay);
        if (!mounted) return;
      }
      setState(() => _show = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = context.select<AppState, bool>((s) => s.reduceMotion);
    final offset = _show ? widget.endOffset : widget.beginOffset;
    final opacity = _show ? widget.endOpacity : widget.beginOpacity;
    if (reduceMotion) {
      return widget.child;
    }
    return AnimatedSlide(
      offset: offset,
      duration: widget.duration,
      curve: widget.curve,
      child: AnimatedOpacity(
        opacity: opacity,
        duration: widget.duration,
        curve: widget.curve,
        child: widget.child,
      ),
    );
  }
}
