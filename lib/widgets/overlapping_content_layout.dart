// Path: lib/widgets/overlapping_content_layout.dart

import 'package:flutter/material.dart';

class OverlappingContentLayout extends StatefulWidget {
  final Widget header;
  final Widget overlappingWidget;
  final List<Widget> contentWidgets;
  final double overlap;
  final Color backgroundColor;
  final double contentSpacing; // New parameter for spacing between content widgets

  const OverlappingContentLayout({
    Key? key,
    required this.header,
    required this.overlappingWidget,
    required this.contentWidgets,
    this.overlap = 60.0,
    // this.backgroundColor = const Color(0xFFF9F5F1),
    this.backgroundColor = Colors.white12,
    this.contentSpacing = 16.0, // Default spacing between content widgets
  }) : super(key: key);

  @override
  State<OverlappingContentLayout> createState() => _OverlappingContentLayoutState();
}

class _OverlappingContentLayoutState extends State<OverlappingContentLayout> {
  final GlobalKey headerKey = GlobalKey();
  final GlobalKey overlappingWidgetKey = GlobalKey();
  double headerHeight = 200.0; // Default
  double overlappingWidgetHeight = 0.0;
  bool _measured = false;

  @override
  void initState() {
    super.initState();
    // Schedule measurement for after the first layout
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
    // Create a list that includes spacing between content widgets
    final List<Widget> spacedContentWidgets = [];

    // Add spacing between content widgets
    for (int i = 0; i < widget.contentWidgets.length; i++) {
      // Add the content widget
      spacedContentWidgets.add(widget.contentWidgets[i]);

      // Add spacing after each widget except the last one
      if (i < widget.contentWidgets.length - 1) {
        spacedContentWidgets.add(SizedBox(height: widget.contentSpacing));
      }
    }

    return SingleChildScrollView(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            children: [
              // Header with key for measurement
              KeyedSubtree(
                key: headerKey,
                child: widget.header,
              ),

              // Content area
              Container(
                color: widget.backgroundColor,
                // color: widget.backgroundColor,
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Space for the overlapping widget
                    SizedBox(height: _measured
                        ? (overlappingWidgetHeight - widget.overlap)
                        : 160.0),
                    // Add some initial spacing between the overlapping widget and first content
                    SizedBox(height: widget.contentSpacing),
                    // Content widgets with spacing
                    ...spacedContentWidgets,
                    // Add some bottom padding
                    SizedBox(height: widget.contentSpacing),
                  ],
                ),
              ),
            ],
          ),

          // Overlapping widget with key for measurement
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
    );
  }
}