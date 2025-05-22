import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gettext_i18n/gettext_i18n.dart';

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
  bool _showCopyButton = false;

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
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextButton(
            onPressed: () {
              setState(() {
                isVisible = !isVisible;

                if (isVisible) {
                  Future.delayed(const Duration(milliseconds: 50), () {
                    if (mounted && isVisible) {
                      setState(() => _showCopyButton = true);
                    }
                  });
                } else {
                  _showCopyButton = false;
                }
              });
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: isVisible
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(context.t('Close details')),
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Icon(Icons.keyboard_arrow_up),
                      ),
                    ],
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Icon(Icons.info_outline),
                      ),
                      Text(context.t('Show details')),
                    ],
                  ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 12.0, right: 12.0),
          child: Stack(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                height: isVisible ? 200 : 0,
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
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 100),
                switchInCurve: Curves.easeIn,
                switchOutCurve: Curves.easeOut,
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(opacity: animation, child: child);
                },
                child: _showCopyButton
                    ? Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Align(
                          alignment: Alignment.topRight,
                          child: IconButton(
                            onPressed: () {
                              Clipboard.setData(
                                ClipboardData(
                                  text: widget.outputLines.join('\n'),
                                ),
                              );
                            },
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.grey.shade600,
                            ),
                            iconSize: 16.0,
                            constraints: const BoxConstraints(),
                            icon: const Icon(
                              Icons.copy,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
