// Path: lib/widgets/overlapping_content_layout.dart

import 'package:flutter/material.dart';

class OverlappingContentLayout extends StatefulWidget {
  final Widget header;
  final Widget overlappingWidget;
  final List<Widget> contentWidgets;
  final double overlap;
  final Gradient backgroundGradient; // ✅ CHANGED: From Color to Gradient
  final double contentSpacing;

  const OverlappingContentLayout({
    Key? key,
    required this.header,
    required this.overlappingWidget,
    required this.contentWidgets,
    this.overlap = 40.0,
    // ✅ CHANGED: Default gradient instead of solid color
    this.backgroundGradient = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        // Colors.white,
        // Colors.white,
        // Color(0xFFF5E6D3),
        Color(0xFFF5F5F5),
        Color(0xFFF5F5F5),
      ],
    ),
    this.contentSpacing = 16.0,
  }) : super(key: key);

  @override
  State<OverlappingContentLayout> createState() => _OverlappingContentLayoutState();
}

class _OverlappingContentLayoutState extends State<OverlappingContentLayout> {
  final GlobalKey headerKey = GlobalKey();
  final GlobalKey overlappingWidgetKey = GlobalKey();
  double headerHeight = 200.0;
  double overlappingWidgetHeight = 0.0;
  bool _measured = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _measureWidgets();
    });
  }

  void _measureWidgets() {
    final headerContext = headerKey.currentContext;
    final overlappingContext = overlappingWidgetKey.currentContext;

    if (headerContext != null) {
      final headerBox = headerContext.findRenderObject() as RenderBox;
      headerHeight = headerBox.size.height;
    }

    if (overlappingContext != null) {
      final overlappingBox = overlappingContext.findRenderObject() as RenderBox;
      overlappingWidgetHeight = overlappingBox.size.height;
    }

    if (mounted) {
      setState(() {
        _measured = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> spacedContentWidgets = [];

    for (int i = 0; i < widget.contentWidgets.length; i++) {
      spacedContentWidgets.add(widget.contentWidgets[i]);
      if (i < widget.contentWidgets.length - 1) {
        spacedContentWidgets.add(SizedBox(height: widget.contentSpacing));
      }
    }

    return Container(
      // ✅ CHANGED: Use gradient instead of solid color
      decoration: BoxDecoration(
        gradient: widget.backgroundGradient,
      ),
      child: SingleChildScrollView(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              children: [
                KeyedSubtree(
                  key: headerKey,
                  child: widget.header,
                ),

                // ✅ CHANGED: Remove background color (transparent to show gradient)
                Container(
                  color: Colors.transparent,
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: _measured
                          ? (overlappingWidgetHeight - widget.overlap)
                          : 160.0),
                      SizedBox(height: widget.contentSpacing),
                      ...spacedContentWidgets,
                      SizedBox(height: widget.contentSpacing),
                    ],
                  ),
                ),
              ],
            ),

            Positioned(
              top: headerHeight - widget.overlap,
              left: 16.0,
              right: 16.0,
              child: KeyedSubtree(
                key: overlappingWidgetKey,
                child: widget.overlappingWidget,
              ),
            ),
          ],
        ),
      ),
    );
  }
}