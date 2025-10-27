import 'package:flutter/material.dart';

class BeforeAfterSlider extends StatefulWidget {
  final String beforeUrl;
  final String afterUrl;
  final String title;
  const BeforeAfterSlider({super.key, required this.beforeUrl, required this.afterUrl, required this.title});

  @override
  State<BeforeAfterSlider> createState() => _BeforeAfterSliderState();
}

class _BeforeAfterSliderState extends State<BeforeAfterSlider> {
  double _sliderValue = 0.5;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: MediaQuery.of(context).viewInsets,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(widget.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ),
          AspectRatio(
            aspectRatio: 1.5,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                return Stack(
                  children: [
                    Positioned.fill(
                      child: Image.network(widget.beforeUrl, fit: BoxFit.cover),
                    ),
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      width: width * _sliderValue,
                      child: ClipRect(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          widthFactor: _sliderValue,
                          child: Image.network(widget.afterUrl, fit: BoxFit.cover),
                        ),
                      ),
                    ),
                    Positioned(
                      left: width * _sliderValue - 12,
                      top: 0,
                      bottom: 0,
                      child: Container(
                        width: 24,
                        color: Colors.black.withOpacity(0.2),
                        child: const Center(
                          child: Icon(Icons.drag_handle, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          Slider(
            value: _sliderValue,
            onChanged: (v) => setState(() => _sliderValue = v),
            min: 0.0,
            max: 1.0,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
