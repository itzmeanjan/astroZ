import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show MethodChannel;

class VideoPlayerWidget extends StatefulWidget {
  VideoPlayerWidget({Key key, this.url, this.methodChannel}) : super(key: key);

  final String url;
  final MethodChannel methodChannel;

  @override
  _VideoPlayerWidgetState createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  @override
  Widget build(BuildContext context) {
    return IconButton(
        icon: Icon(
          Icons.play_circle_outline,
        ),
        iconSize: 56,
        tooltip: 'Play Video',
        alignment: Alignment.center,
        splashColor: Colors.white,
        color: Colors.red,
        padding: EdgeInsets.all(0),
        onPressed: () {
          openInTargetApp(widget.url);
        });
  }

  Future<bool> openInTargetApp(String url) async {
    return await widget.methodChannel.invokeMethod(
        'openInTargetApp', <String, String>{'url': url}).then((val) => val);
  }
}
