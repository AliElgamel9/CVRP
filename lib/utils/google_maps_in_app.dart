import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';

class GoogleMapsInWebView extends StatefulWidget {
  final Uri uri;

  GoogleMapsInWebView({required this.uri});

  @override
  State<StatefulWidget> createState() => _GoogleMapsInWebView(uri: uri);
}

class _GoogleMapsInWebView extends State {
  final Uri uri;
  _GoogleMapsInWebView({required this.uri});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('RoutePro'),
      ),
      body: InAppWebView(
        initialUrlRequest: URLRequest(url: uri),
        initialOptions: InAppWebViewGroupOptions(
          crossPlatform: InAppWebViewOptions(
            useShouldOverrideUrlLoading: true,
          ),
        ),
        shouldOverrideUrlLoading: (controller, navigationAction) async {
          _launchApp();
          return NavigationActionPolicy.CANCEL;
        }
      ),
    );
  }

  Future<void> _launchApp() async {
    if (await canLaunchUrl(uri))
      await launchUrl(uri, mode: LaunchMode.externalNonBrowserApplication);
  }
}
