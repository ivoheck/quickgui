import 'package:flutter/material.dart';

class DownloadTerminalOutput extends StatefulWidget {
  const DownloadTerminalOutput({super.key, required this.outputLines});

  final List<String> outputLines;

  @override
  State<DownloadTerminalOutput> createState() => _DownloadTerminalOutputState();
}

class _DownloadTerminalOutputState extends State<DownloadTerminalOutput> {
  final ScrollController _scrollController = ScrollController();
  bool _shouldAutoScroll = true;
  bool isVisible = false;

  @override
  void didUpdateWidget(covariant DownloadTerminalOutput oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients && _shouldAutoScroll) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  void initState() {
    super.initState();

    // Disable automatic scrolling if the user scrolls up
    _scrollController.addListener(() {
      final double maxScroll = _scrollController.position.maxScrollExtent;
      final double currentScroll = _scrollController.position.pixels;
      const double threshold = 20.0;

      if ((maxScroll - currentScroll) > threshold) {
        _shouldAutoScroll = false;
      } else {
        _shouldAutoScroll = true;
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextButton(
          onPressed: () {
            setState(() {
              isVisible = !isVisible;
            });
          },
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: isVisible
              ? const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Show less details'),
                    Icon(Icons.arrow_drop_up),
                  ],
                )
              : const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.info_outline),
                    Text('Show more details'),
                  ],
                ),
        ),
        if (isVisible)
          Padding(
            padding: const EdgeInsets.only(left: 12.0, right: 12.0),
            child: Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.black,
              ),
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SelectableText(
                    widget.outputLines.join('\n'),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
