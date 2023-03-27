import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:webview_flutter/webview_flutter.dart';

///
///A Chart library based on [High Charts (.JS)](https://www.highcharts.com/)
///
class HighCharts extends StatefulWidget {
  const HighCharts(
      {required this.data,
      this.loader = const Center(child: CircularProgressIndicator()),
      required this.size,
      this.scripts = const [],
      Key? key})
      : super(key: key);

  ///Custom `loader` widget, until script is loaded
  ///
  ///Has no effect on Web
  ///
  ///Defaults to `CircularProgressIndicator`
  final Widget loader;

  ///Chart data
  ///
  ///(use `jsonEncode` if the data is in `Map<String,dynamic>`)
  ///
  ///Reference: [High Charts API](https://api.highcharts.com/highcharts)
  ///
  ///```dart
  ///String chart_data = '''{
  ///      title: {
  ///          text: 'Combination chart'
  ///      },
  ///      xAxis: {
  ///          categories: ['Apples', 'Oranges', 'Pears', 'Bananas', 'Plums']
  ///      },
  ///      labels: {
  ///          items: [{
  ///              html: 'Total fruit consumption',
  ///              style: {
  ///                  left: '50px',
  ///                  top: '18px',
  ///                  color: (
  ///                      Highcharts.defaultOptions.title.style &&
  ///                      Highcharts.defaultOptions.title.style.color
  ///                  ) || 'black'
  ///              }
  ///          }]
  ///      },
  ///
  ///      ...
  ///
  ///    }''';
  ///
  ///```
  ///
  ///Reference: [High Charts API](https://api.highcharts.com/highcharts)
  final String data;

  ///Chart size
  ///
  ///Height and width of the chart is required
  ///
  ///```dart
  ///Size size = Size(400, 300);
  ///```
  final Size size;

  ///Scripts to be loaded
  ///
  ///Url's of the hightchart js scripts.
  ///
  ///Reference: [Full Scripts list](https://code.highcharts.com/)
  ///
  ///or use any CDN hosted script
  ///
  ///### For `android` and `ios` platforms, the scripts must be provided
  ///
  ///```dart
  ///List<String> scripts = [
  ///  'https://code.highcharts.com/highcharts.js',
  ///  'https://code.highcharts.com/modules/exporting.js',
  ///  'https://code.highcharts.com/modules/export-data.js'
  /// ];
  /// ```
  ///
  ///### For `web` platform, the scripts must be provided in `web/index.html`
  ///
  ///```html
  ///<head>
  ///   <script src="https://code.highcharts.com/highcharts.js"></script>
  ///   <script src="https://code.highcharts.com/modules/exporting.js"></script>
  ///   <script src="https://code.highcharts.com/modules/export-data.js"></script>
  ///</head>
  ///```
  ///
  final List<Uri> scripts;
  @override
  _HighChartsState createState() => _HighChartsState();
}

class _HighChartsState extends State<HighCharts> {
  bool _isLoaded = false;

  late WebViewController controller;

  @override
  void initState() {
    super.initState();
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // Update loading bar.
          },
          onPageStarted: (String url) {},
          onPageFinished: (String url) {
            _loadData();
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint(error.toString());
          },
          onNavigationRequest: (NavigationRequest request) async {
            if (await canLaunchUrlString(request.url)) {
              try {
                launchUrlString(request.url);
              } catch (e) {
                debugPrint('High Charts Error ->' + e.toString());
              }
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      );
    _loadHtmlContent(controller);
  }

  @override
  void didUpdateWidget(covariant HighCharts oldWidget) {
    if (oldWidget.data != widget.data || oldWidget.scripts != widget.scripts) {
      _loadHtmlContent(controller);
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      fit: StackFit.passthrough,
      children: [
        !_isLoaded ? widget.loader : const SizedBox.shrink(),
        WebViewWidget(
          controller: controller,
        ),
      ],
    );
  }

  void _loadHtmlContent(WebViewController _) {
    String html = "";
    html +=
        '<!DOCTYPE html><html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, minimum-scale=1.0, user-scalable=0"/> </head> <body><div style="height:100%;width:100%;" id="highChartsDiv"></div><script>function __loadData(a){ eval(a); return true;}</script>';
    for (Uri src in widget.scripts) {
      html += '<script async="false" src="${src.toString()}"></script>';
    }
    html += '</body></html>';
    _.loadHtmlString(html);
  }

  void _loadData() {
    setState(() {
      _isLoaded = true;
    });
    controller.runJavaScriptReturningResult(
        "__loadData(`Highcharts.chart('highChartsDiv',${widget.data} )`);");
  }
}
