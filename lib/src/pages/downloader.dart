import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:desktop_notifications/desktop_notifications.dart';
import 'package:flutter/material.dart';
import 'package:gettext_i18n/gettext_i18n.dart';
import 'package:quickgui/src/widgets/downloader/download_terminal_output.dart';

import '../model/operating_system.dart';
import '../model/option.dart';
import '../model/version.dart';
import '../widgets/downloader/cancel_dismiss_button.dart';
import '../widgets/downloader/download_label.dart';
import '../widgets/downloader/download_progress_bar.dart';

class Downloader extends StatefulWidget {
  const Downloader({
    required this.operatingSystem,
    required this.version,
    this.option,
    super.key,
  });

  final OperatingSystem operatingSystem;
  final Version version;
  final Option? option;

  @override
  _DownloaderState createState() => _DownloaderState();
}

class _DownloaderState extends State<Downloader> {
  final notificationsClient = Platform.isMacOS ? null : NotificationsClient();
  final curlPattern = RegExp("( [0-9.]+%)");
  late final Stream<double> _progressStream;
  bool _downloadFinished = false;
  var controller = StreamController<double>();
  Process? _process;

  final List<String> _outputLines = [];

  @override
  void initState() {
    _progressStream = progressStream();
    super.initState();
  }

  void parseCurlProgress(String line) {
    var matches = curlPattern.allMatches(line).toList();
    if (matches.isNotEmpty) {
      var percent = matches[0].group(1);
      if (percent != null) {
        var value = double.parse(percent.replaceAll('%', '')) / 100.0;
        controller.add(value);
      }
    }
  }

  bool isProgressLine(String line) {
    return RegExp(r'\d+\s+\d+[kMG]?\s+\d+').hasMatch(line) &&
        line.contains('%') == false;
  }

  Stream<double> progressStream() {
    var options = [widget.operatingSystem.code, widget.version.version];
    if (widget.option != null) {
      options.add(widget.option!.option);
    }
    Process.start('quickget', options).then((process) {
      if (widget.option!.downloader != 'zsync') {
        // process.stderr.transform(utf8.decoder).forEach(parseCurlProgress);
        process.stderr
            .transform(utf8.decoder)
            .transform(
              const LineSplitter(),
            )
            .listen((line) {
          if (isProgressLine(line)) {
            setState(() {
              _outputLines.add(
                line,
              );
            });
          }

          parseCurlProgress(line);
        });

        process.stdout
            .transform(const SystemEncoding().decoder)
            .transform(
              const LineSplitter(),
            )
            .listen((line) {
          setState(() {
            _outputLines.add(
              line,
            );
          });
        });
      } else {
        controller.add(-1);
      }

      process.exitCode.then((value) {
        bool cancelled = value.isNegative;
        controller.close();
        setState(() {
          _downloadFinished = true;
          notificationsClient?.notify(
            cancelled
                ? context.t('Download cancelled')
                : context.t('Download complete'),
            body: cancelled
                ? context.t(
                    'Download of {0} has been canceled.',
                    args: [widget.operatingSystem.name],
                  )
                : context.t(
                    'Download of {0} has completed.',
                    args: [widget.operatingSystem.name],
                  ),
            appName: 'Quickgui',
            expireTimeoutMs: 10000, /* 10 seconds */
          );
        });
      });

      setState(() {
        _process = process;
      });
    });

    return controller.stream;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.t('Downloading {0}', args: [
            '${widget.operatingSystem.name} ${widget.version.version}${widget.option!.option.isNotEmpty ? ' (${widget.option!.option})' : ''}'
          ]),
        ),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: _progressStream,
              builder: (context, AsyncSnapshot<double> snapshot) {
                var data =
                    !snapshot.hasData || widget.option!.downloader != 'curl'
                        ? null
                        : snapshot.data;
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    DownloadLabel(
                      downloadFinished: _downloadFinished,
                      data: snapshot.hasData ? snapshot.data : null,
                      downloader: widget.option!.downloader,
                    ),
                    DownloadProgressBar(
                      downloadFinished: _downloadFinished,
                      data: snapshot.hasData ? data : null,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 32),
                      child: Text(context.t('Target folder : {0}',
                          args: [Directory.current.path])),
                    ),
                    DownloadTerminalOutput(outputLines: _outputLines),
                  ],
                );
              },
            ),
          ),
          CancelDismissButton(
            onCancel: () {
              _process?.kill();
            },
            downloadFinished: _downloadFinished,
          ),
        ],
      ),
    );
  }
}
