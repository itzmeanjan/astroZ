import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'VideoPlayerWidget.dart';

void main() => runApp(MyAPODHome());

class MyAPODHome extends StatefulWidget {
  @override
  _MyAPODHomeState createState() => _MyAPODHomeState();
}

class _MyAPODHomeState extends State<MyAPODHome> {
  var _dates;
  var _upTo = 0;
  var _isDeviceConnected = false;
  var _data = <Map<String, String>>[];
  String _targetPath;
  MethodChannel _methodChannel;
  EventChannel _eventChannel;
  ScrollController _controller;
  int _currentGradient = 1;
  LinearGradient _linearGradient = LinearGradient(colors: [
    Colors.tealAccent,
    Colors.lightBlueAccent,
    Colors.greenAccent,
    Colors.cyanAccent,
  ], end: Alignment.bottomRight, begin: Alignment.topLeft);

  @override
  void initState() {
    super.initState();
    _methodChannel = MethodChannel('nasa_apod_method');
    _dates = getDates();
    Timer.periodic(Duration(seconds: 4), (Timer tm) {
      if (tm.isActive)
        setState(() {
          _linearGradient = [
            LinearGradient(colors: [
              Colors.tealAccent,
              Colors.lightBlueAccent,
              Colors.greenAccent,
              Colors.cyanAccent,
            ], end: Alignment.bottomRight, begin: Alignment.topLeft),
            LinearGradient(colors: [
              Colors.greenAccent,
              Colors.cyanAccent,
              Colors.tealAccent,
            ], end: Alignment.centerRight, begin: Alignment.centerLeft),
            LinearGradient(colors: [
              Colors.tealAccent,
              Colors.cyanAccent,
              Colors.greenAccent,
            ], end: Alignment.topRight, begin: Alignment.bottomLeft),
            LinearGradient(colors: [
              Colors.cyanAccent,
              Colors.tealAccent,
              Colors.greenAccent,
            ], end: Alignment.topCenter, begin: Alignment.bottomCenter),
            LinearGradient(colors: [
              Colors.greenAccent,
              Colors.tealAccent,
              Colors.cyanAccent,
            ], end: Alignment.topLeft, begin: Alignment.bottomRight),
            LinearGradient(colors: [
              Colors.tealAccent,
              Colors.greenAccent,
              Colors.cyanAccent,
            ], end: Alignment.centerLeft, begin: Alignment.centerRight),
            LinearGradient(colors: [
              Colors.tealAccent,
              Colors.cyanAccent,
              Colors.greenAccent,
            ], end: Alignment.bottomLeft, begin: Alignment.topRight),
            LinearGradient(colors: [
              Colors.greenAccent,
              Colors.cyanAccent,
              Colors.tealAccent,
            ], end: Alignment.bottomCenter, begin: Alignment.topCenter),
          ][_currentGradient];
        });
      _currentGradient = _currentGradient == 0
          ? 1
          : (_currentGradient == 1
              ? 2
              : (_currentGradient == 2
                  ? 3
                  : (_currentGradient == 3
                      ? 4
                      : (_currentGradient == 4
                          ? 5
                          : (_currentGradient == 5
                              ? 6
                              : (_currentGradient == 6 ? 7 : 0))))));
    });
    isConnected().then((bool val) {
      if (val) {
        _controller = ScrollController()
          ..addListener(() {
            if (_controller.position.extentAfter < 500) {
              isConnected().then((dynamic val) {
                if (val) fetch(10);
              });
            }
          });
      }
      setState(() {
        _isDeviceConnected = val;
      });
      if (val) {
        fetch(10);
        Timer(Duration(seconds: 2), loadAd);
      }
    });
  }

  void loadAd() async {
    isConnected().then((bool val1) async {
      if (val1)
        await _methodChannel.invokeMethod('loadBannerAd').then((val2) {
          if (val2 == 1) {
            _eventChannel = EventChannel('nasa_apod_event');
            _eventChannel
                .receiveBroadcastStream()
                .listen(_onData, onError: _onError);
          }
        });
    });
  }

  void closeAd() async {
    await _methodChannel.invokeMethod('closeBannerAd').then((val) {
      if (val == 1) {
        _eventChannel = null;
        Timer(Duration(seconds: 2), loadAd);
      }
    });
  }

  void _onData(dynamic event) {
    print(event);
    if (event.toString() == 'closed') closeAd();
  }

  void _onError(dynamic error) {
    print(error);
  }

  List<String> getDates({String endDate: '1995-06-19'}) {
    var dt = DateTime.now();
    var listOfDates = <String>[];
    var current = getDate(dt);
    while (current != endDate) {
      listOfDates.add(current);
      dt = dt.subtract(Duration(hours: 24));
      current = getDate(dt);
    }
    return listOfDates;
  }

  String getDate(DateTime dt) {
    var target = <String>['${dt.year}']
      ..add(dt.month < 10 ? '0${dt.month}' : '${dt.month}')
      ..add(dt.day < 10 ? '0${dt.day}' : '${dt.day}');
    return target.join('-');
  }

  void fetch(int count) {
    _dates.getRange(_upTo, _upTo + count).forEach((elem) {
      getDataFromLocal(elem).then((val1) {
        if (val1.isNotEmpty) {
          setState(() {
            _data.add(val1);
          });
        } else
          getDataFromServer(elem).then((val2) {
            if (val2.isNotEmpty) {
              setState(() {
                _data.add(val2);
              });
              storeData([val2]);
            }
          });
      });
    });
    _upTo += count;
  }

  Future<bool> isConnected() async {
    return _methodChannel
        .invokeMethod('isConnected')
        .then((dynamic val) => val);
  }

  Future<Map<String, String>> getDataFromLocal(String date) async {
    // fetches data from local SQL database using platform channel
    return await _methodChannel
        .invokeMethod('getFromLocal', <String, String>{"date": date}).then(
            (dynamic val) => Map<String, String>.from(val));
  }

  Future<Map<String, String>> getDataFromServer(String date,
      {String host: '192.168.1.103',
      int port: 8000,
      String path: 'apodbydate'}) async {
    // fetches data from Express app which is running in Local Network,
    // you might try to run this Express App on some remote Server or Cloud, then make required changes.
    return await HttpClient()
        .get(host, port, '$path/$date')
        .catchError((error1) => <String, String>{})
        .then((HttpClientRequest req) => req.close())
        .catchError((error2) => <String, String>{})
        .then((HttpClientResponse resp) async {
      if (resp.statusCode != 200) {
        return <String, String>{};
      } else {
        var completer = Completer<Map<String, String>>();
        resp.transform(utf8.decoder).transform(json.decoder).listen((data) {
          completer.complete(Map<String, String>.from(data));
        });
        return completer.future;
      }
    }).catchError((error3) => <String, String>{});
  }

  Future<bool> storeData(List<Map<String, String>> data) async {
    return await _methodChannel.invokeMethod("storeInDB",
        <String, List<Map<String, String>>>{"data": data}).then((dynamic val) {
      return val == 1 ? true : false;
    });
  }

  Future<bool> isPermissionAvailable() async {
    return await _methodChannel
        .invokeMethod('isPermissionAvailable')
        .then((val) => val);
  }

  Future<bool> requestPermission() async {
    return await _methodChannel
        .invokeMethod('requestPermission')
        .then((val) => val);
  }

  Future<String> getTargetPath() async {
    return await _methodChannel
        .invokeMethod('getTargetPath')
        .then((val) => '$val/astroZ');
  }

  Future<bool> shareText(String text, String type) async {
    return await _methodChannel.invokeMethod('shareText',
        <String, String>{'text': text, 'type': type}).then((val) => val);
  }

  Future<bool> isFilePresent(String filePath) async {
    return await File(filePath)
        .exists()
        .then((bool val) => val)
        .catchError((error) => false);
  }

  Future<bool> isDirectoryPresent(String dirPath) async {
    return await Directory(dirPath)
        .exists()
        .then((bool val) => val)
        .catchError((error) => false);
  }

  Future<bool> createDirectory(String dirPath) async {
    return await Directory(dirPath)
        .create()
        .then((val) => true)
        .catchError((error) => false);
  }

  Future<bool> showToast(String msg, {String duration: 'short'}) async {
    return await _methodChannel.invokeMethod('showToast',
        <String, String>{'msg': msg, 'duration': duration}).then((val) => val);
  }

  Future<bool> downloadImage(String link, String fileName) async {
    return await HttpClient()
        .getUrl(Uri.parse(link))
        .catchError((error1) => false)
        .then((HttpClientRequest req) => req.close())
        .catchError((error2) => false)
        .then((HttpClientResponse resp) async {
      if (resp.statusCode != 200) {
        return false;
      } else {
        var file = File(fileName).openWrite();
        return await resp.pipe(file).then((val) {
          file.close();
          return true;
        });
      }
    }).catchError((error4) => false);
  }

  Future<bool> setWallPaper(String imagePath) async {
    return await _methodChannel.invokeMethod('setWallPaper',
        <String, String>{'imagePath': imagePath}).then((val) => val);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "AstroZ",
      darkTheme: ThemeData.dark(),
      theme: ThemeData.light(),
      home: Scaffold(
        appBar: AppBar(
          title: Text(
            'Astroz',
            style: TextStyle(color: Colors.black),
          ),
          elevation: 18,
          backgroundColor: Colors.cyanAccent,
          actions: <Widget>[
            IconButton(
                icon: Icon(Icons.refresh),
                tooltip: 'Reload',
                onPressed: () {
                  if (_isDeviceConnected) closeAd();
                  isConnected().then((bool val) {
                    if (val) {
                      if (_controller == null)
                        _controller = ScrollController()
                          ..addListener(() {
                            if (_controller.position.extentAfter < 500) {
                              isConnected().then((dynamic val) {
                                if (val) fetch(10);
                              });
                            }
                          });
                    }
                    setState(() {
                      _isDeviceConnected = val;
                      _data = [];
                    });
                    if (val) {
                      _controller.jumpTo(0);
                      _upTo = 0;
                      fetch(10);
                    }
                  });
                }),
            IconButton(
                icon: Icon(Icons.format_line_spacing),
                tooltip: 'Reorder',
                onPressed: () {
                  isConnected().then((bool val) {
                    if (val) {
                      if (_controller == null)
                        _controller = ScrollController()
                          ..addListener(() {
                            if (_controller.position.extentAfter < 500) {
                              isConnected().then((dynamic val) {
                                if (val) fetch(10);
                              });
                            }
                          });
                    }
                    setState(() {
                      _data = [];
                      _isDeviceConnected = val;
                    });
                    if (val) {
                      _controller.jumpTo(0);
                      _upTo = 0;
                      _dates = _dates.reversed.toList();
                      fetch(10);
                    }
                  });
                }),
            Builder(
              builder: (ctx) {
                return IconButton(
                  icon: Icon(Icons.info_outline),
                  tooltip: 'About',
                  onPressed: () {
                    showAboutDialog(
                        context: ctx,
                        children: [
                          Text(
                            "NASA's Astronomy Picture of the Day Displayer",
                            maxLines: 4,
                            overflow: TextOverflow.fade,
                          ),
                          Divider(
                            height: 16,
                            color: Colors.white,
                          ),
                          Text('Author: Anjan Roy ;)')
                        ],
                        applicationIcon: Icon(Icons.info_outline),
                        applicationName: "Astroz",
                        applicationVersion: "1.0");
                  },
                );
              },
            ),
          ],
        ),
        body: !_isDeviceConnected
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(
                      IconData(0x1f644),
                    ),
                    Divider(
                      height: 12,
                      color: Colors.white,
                    ),
                    Text('Connect to Internet and Reload')
                  ],
                ),
              )
            : ListView.separated(
                controller: _controller,
                separatorBuilder: (ctx, count) {
                  return VerticalDivider(
                    width: 16,
                    color: Colors.white,
                  );
                },
                scrollDirection: Axis.horizontal,
                itemCount: _data.length,
                itemBuilder: (ctx, count) {
                  return SizedBox(
                    width: MediaQuery.of(ctx).size.width * .9,
                    child: Card(
                        elevation: 12.0,
                        child: AnimatedContainer(
                            duration: Duration(seconds: 3),
                            curve: Curves.bounceIn,
                            padding: EdgeInsets.all(6.0),
                            decoration: BoxDecoration(
                              gradient: _linearGradient,
                            ),
                            child:
                                MediaQuery.of(ctx).orientation ==
                                        Orientation.portrait
                                    ? Column(
                                        children: <Widget>[
                                          Align(
                                            child: PopupMenuButton(
                                                icon: Icon(
                                                  Icons.more_vert,
                                                  size: 20,
                                                ),
                                                onSelected: (value) {
                                                  switch (value) {
                                                    case 0:
                                                      shareText(
                                                          'Astronomy Picture of the Day for ${_data[count]['date']} :\n\n${_data[count]['title']} :-\n\n${_data[count]['explanation']}\n\n${_data[count]['url']}\n\nShared via astroZ (https://play.google.com/store/apps/details?id=com.example.itzmeanjan.nasa_apod)',
                                                          'text/plain');
                                                      break;
                                                    case 1:
                                                      showDialog(
                                                          context: ctx,
                                                          builder: (ctx) {
                                                            return SimpleDialog(
                                                              elevation: 12,
                                                              title: Text(
                                                                "Copyright",
                                                                style: TextStyle(
                                                                    letterSpacing:
                                                                        3),
                                                              ),
                                                              contentPadding:
                                                                  EdgeInsets
                                                                      .all(8),
                                                              titlePadding:
                                                                  EdgeInsets
                                                                      .all(6),
                                                              children: <
                                                                  Widget>[
                                                                Text(
                                                                  '\u{00a9} ${_data[count]['copyright']}',
                                                                  maxLines: 8,
                                                                  style: TextStyle(
                                                                      fontStyle:
                                                                          FontStyle
                                                                              .italic),
                                                                  overflow:
                                                                      TextOverflow
                                                                          .fade,
                                                                ),
                                                              ],
                                                            );
                                                          });
                                                      break;
                                                    case 2:
                                                      isPermissionAvailable()
                                                          .then((bool perm) {
                                                        if (!perm)
                                                          requestPermission()
                                                              .then((bool
                                                                  permReq) {
                                                            if (permReq) {
                                                              getTargetPath()
                                                                  .then((String
                                                                      path) {
                                                                _targetPath =
                                                                    path;
                                                                isDirectoryPresent(
                                                                        _targetPath)
                                                                    .then((bool
                                                                        presence) {
                                                                  if (!presence) {
                                                                    createDirectory(
                                                                            _targetPath)
                                                                        .then((bool
                                                                            createDir) {
                                                                      if (createDir)
                                                                        isFilePresent('$_targetPath/${_data[count]['date']}${RegExp(r"(\.[a-zA-Z]+)$").stringMatch(_data[count]['url'])}').then((bool
                                                                            filePresence) {
                                                                          if (!filePresence)
                                                                            downloadImage(_data[count]['url'], '$_targetPath/${_data[count]['date']}${RegExp(r"(\.[a-zA-Z]+)$").stringMatch(_data[count]['url'])}').then((bool
                                                                                downloadRes) {
                                                                              showToast(downloadRes ? 'Downloaded Image' : 'Failed to download Image');
                                                                            });
                                                                          else
                                                                            showToast('Already downloaded Image');
                                                                        });
                                                                    });
                                                                  } else
                                                                    isFilePresent(
                                                                            '$_targetPath/${_data[count]['date']}${RegExp(r"(\.[a-zA-Z]+)$").stringMatch(_data[count]['url'])}')
                                                                        .then((bool
                                                                            filePresence) {
                                                                      if (!filePresence)
                                                                        downloadImage(_data[count]['url'], '$_targetPath/${_data[count]['date']}${RegExp(r"(\.[a-zA-Z]+)$").stringMatch(_data[count]['url'])}').then((bool
                                                                            downloadRes) {
                                                                          showToast(downloadRes
                                                                              ? 'Downloaded Image'
                                                                              : 'Failed to download Image');
                                                                        });
                                                                      else
                                                                        showToast(
                                                                            'Already downloaded Image');
                                                                    });
                                                                });
                                                              });
                                                            } else
                                                              showToast(
                                                                  'Permission Required !!!');
                                                          });
                                                        else
                                                          getTargetPath().then(
                                                              (String path) {
                                                            _targetPath = path;
                                                            isDirectoryPresent(
                                                                    _targetPath)
                                                                .then((bool
                                                                    presence) {
                                                              if (!presence) {
                                                                createDirectory(
                                                                        _targetPath)
                                                                    .then((bool
                                                                        createDir) {
                                                                  if (createDir)
                                                                    isFilePresent(
                                                                            '$_targetPath/${_data[count]['date']}${RegExp(r"(\.[a-zA-Z]+)$").stringMatch(_data[count]['url'])}')
                                                                        .then((bool
                                                                            filePresence) {
                                                                      if (!filePresence)
                                                                        downloadImage(_data[count]['url'], '$_targetPath/${_data[count]['date']}${RegExp(r"(\.[a-zA-Z]+)$").stringMatch(_data[count]['url'])}').then((bool
                                                                            downloadRes) {
                                                                          showToast(downloadRes
                                                                              ? 'Downloaded Image'
                                                                              : 'Failed to download Image');
                                                                        });
                                                                      else
                                                                        showToast(
                                                                            'Already downloaded Image');
                                                                    });
                                                                });
                                                              } else
                                                                isFilePresent(
                                                                        '$_targetPath/${_data[count]['date']}${RegExp(r"(\.[a-zA-Z]+)$").stringMatch(_data[count]['url'])}')
                                                                    .then((bool
                                                                        filePresence) {
                                                                  if (!filePresence)
                                                                    downloadImage(
                                                                            _data[count][
                                                                                'url'],
                                                                            '$_targetPath/${_data[count]['date']}${RegExp(r"(\.[a-zA-Z]+)$").stringMatch(_data[count]['url'])}')
                                                                        .then((bool
                                                                            downloadRes) {
                                                                      showToast(downloadRes
                                                                          ? 'Downloaded Image'
                                                                          : 'Failed to download Image');
                                                                    });
                                                                  else
                                                                    showToast(
                                                                        'Already downloaded Image');
                                                                });
                                                            });
                                                          });
                                                      });
                                                      break;
                                                    case 3:
                                                      isPermissionAvailable()
                                                          .then((bool perm) {
                                                        if (!perm)
                                                          requestPermission()
                                                              .then((bool
                                                                  permReq) {
                                                            if (permReq)
                                                              getTargetPath()
                                                                  .then((String
                                                                      path) {
                                                                _targetPath =
                                                                    path;
                                                                isDirectoryPresent(
                                                                        _targetPath)
                                                                    .then((bool
                                                                        presence) {
                                                                  if (!presence) {
                                                                    createDirectory(
                                                                            _targetPath)
                                                                        .then((bool
                                                                            createDir) {
                                                                      if (createDir)
                                                                        isFilePresent('$_targetPath/${_data[count]['date']}${RegExp(r"(\.[a-zA-Z]+)$").stringMatch(_data[count]['url'])}').then((bool
                                                                            filePresence) {
                                                                          if (!filePresence)
                                                                            downloadImage(_data[count]['url'], '$_targetPath/${_data[count]['date']}${RegExp(r"(\.[a-zA-Z]+)$").stringMatch(_data[count]['url'])}').then((bool
                                                                                downloadRes) {
                                                                              if (downloadRes)
                                                                                setWallPaper('$_targetPath/${_data[count]['date']}${RegExp(r"(\.[a-zA-Z]+)$").stringMatch(_data[count]['url'])}').then((bool setWall) {
                                                                                  showToast(setWall ? 'Set as Wallpaper' : 'Failed to set as Wallpaper');
                                                                                });
                                                                            });
                                                                          else
                                                                            setWallPaper('$_targetPath/${_data[count]['date']}${RegExp(r"(\.[a-zA-Z]+)$").stringMatch(_data[count]['url'])}').then((bool
                                                                                setWall) {
                                                                              showToast(setWall ? 'Set as Wallpaper' : 'Failed to set as Wallpaper');
                                                                            });
                                                                        });
                                                                    });
                                                                  } else
                                                                    isFilePresent(
                                                                            '$_targetPath/${_data[count]['date']}${RegExp(r"(\.[a-zA-Z]+)$").stringMatch(_data[count]['url'])}')
                                                                        .then((bool
                                                                            filePresence) {
                                                                      if (!filePresence)
                                                                        downloadImage(_data[count]['url'], '$_targetPath/${_data[count]['date']}${RegExp(r"(\.[a-zA-Z]+)$").stringMatch(_data[count]['url'])}').then((bool
                                                                            downloadRes) {
                                                                          if (downloadRes)
                                                                            setWallPaper('$_targetPath/${_data[count]['date']}${RegExp(r"(\.[a-zA-Z]+)$").stringMatch(_data[count]['url'])}').then((bool
                                                                                setWall) {
                                                                              showToast(setWall ? 'Set as Wallpaper' : 'Failed to set as Wallpaper');
                                                                            });
                                                                        });
                                                                      else
                                                                        setWallPaper('$_targetPath/${_data[count]['date']}${RegExp(r"(\.[a-zA-Z]+)$").stringMatch(_data[count]['url'])}').then((bool
                                                                            setWall) {
                                                                          showToast(setWall
                                                                              ? 'Set as Wallpaper'
                                                                              : 'Failed to set as Wallpaper');
                                                                        });
                                                                    });
                                                                });
                                                              });
                                                            else
                                                              showToast(
                                                                  'Permission Required !!!');
                                                          });
                                                        else
                                                          getTargetPath().then(
                                                              (String path) {
                                                            _targetPath = path;
                                                            isDirectoryPresent(
                                                                    _targetPath)
                                                                .then((bool
                                                                    presence) {
                                                              if (!presence) {
                                                                createDirectory(
                                                                        _targetPath)
                                                                    .then((bool
                                                                        createDir) {
                                                                  if (createDir)
                                                                    isFilePresent(
                                                                            '$_targetPath/${_data[count]['date']}${RegExp(r"(\.[a-zA-Z]+)$").stringMatch(_data[count]['url'])}')
                                                                        .then((bool
                                                                            filePresence) {
                                                                      if (!filePresence)
                                                                        downloadImage(_data[count]['url'], '$_targetPath/${_data[count]['date']}${RegExp(r"(\.[a-zA-Z]+)$").stringMatch(_data[count]['url'])}').then((bool
                                                                            downloadRes) {
                                                                          if (downloadRes)
                                                                            setWallPaper('$_targetPath/${_data[count]['date']}${RegExp(r"(\.[a-zA-Z]+)$").stringMatch(_data[count]['url'])}').then((bool
                                                                                setWall) {
                                                                              showToast(setWall ? 'Set as Wallpaper' : 'Failed to set as Wallpaper');
                                                                            });
                                                                        });
                                                                      else
                                                                        setWallPaper('$_targetPath/${_data[count]['date']}${RegExp(r"(\.[a-zA-Z]+)$").stringMatch(_data[count]['url'])}').then((bool
                                                                            setWall) {
                                                                          showToast(setWall
                                                                              ? 'Set as Wallpaper'
                                                                              : 'Failed to set as Wallpaper');
                                                                        });
                                                                    });
                                                                });
                                                              } else
                                                                isFilePresent(
                                                                        '$_targetPath/${_data[count]['date']}${RegExp(r"(\.[a-zA-Z]+)$").stringMatch(_data[count]['url'])}')
                                                                    .then((bool
                                                                        filePresence) {
                                                                  if (!filePresence)
                                                                    downloadImage(
                                                                            _data[count][
                                                                                'url'],
                                                                            '$_targetPath/${_data[count]['date']}${RegExp(r"(\.[a-zA-Z]+)$").stringMatch(_data[count]['url'])}')
                                                                        .then((bool
                                                                            downloadRes) {
                                                                      if (downloadRes)
                                                                        setWallPaper('$_targetPath/${_data[count]['date']}${RegExp(r"(\.[a-zA-Z]+)$").stringMatch(_data[count]['url'])}').then((bool
                                                                            setWall) {
                                                                          showToast(setWall
                                                                              ? 'Set as Wallpaper'
                                                                              : 'Failed to set as Wallpaper');
                                                                        });
                                                                    });
                                                                  else
                                                                    setWallPaper(
                                                                            '$_targetPath/${_data[count]['date']}${RegExp(r"(\.[a-zA-Z]+)$").stringMatch(_data[count]['url'])}')
                                                                        .then((bool
                                                                            setWall) {
                                                                      showToast(setWall
                                                                          ? 'Set as Wallpaper'
                                                                          : 'Failed to set as Wallpaper');
                                                                    });
                                                                });
                                                            });
                                                          });
                                                      });
                                                      break;
                                                  }
                                                },
                                                tooltip: 'Options',
                                                padding: EdgeInsets.all(0),
                                                elevation: 16,
                                                itemBuilder: (ctx) {
                                                  return <PopupMenuItem>[
                                                    PopupMenuItem(
                                                      child: Text("Share"),
                                                      value: 0,
                                                    ),
                                                    _data[count][
                                                                'media_type'] ==
                                                            'image'
                                                        ? PopupMenuItem(
                                                            child: Text(
                                                                "Download"),
                                                            value: 2,
                                                          )
                                                        : null,
                                                    _data[count][
                                                                'media_type'] ==
                                                            'image'
                                                        ? PopupMenuItem(
                                                            child: Text(
                                                                "Set as Wallpaper"),
                                                            value: 3,
                                                          )
                                                        : null,
                                                    !['null', 'NA'].contains(
                                                            _data[count]
                                                                ['copyright'])
                                                        ? PopupMenuItem(
                                                            child: Text(
                                                                "Copyright"),
                                                            value: 1,
                                                          )
                                                        : null,
                                                  ];
                                                }),
                                            alignment: Alignment.topRight,
                                          ),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: <Widget>[
                                              Text(
                                                _data[count]['date'],
                                                style: TextStyle(
                                                    letterSpacing: 3.0,
                                                    fontStyle: FontStyle.italic,
                                                    color: Colors.black,
                                                    shadows: [
                                                      Shadow(
                                                          color: Colors.black38,
                                                          blurRadius: 2,
                                                          offset:
                                                              Offset(1.5, 1.75))
                                                    ]),
                                              ),
                                            ],
                                          ),
                                          Divider(
                                            height: 10.0,
                                            color: Colors.cyanAccent,
                                          ),
                                          _data[count]['media_type'] == 'image'
                                              ? Stack(
                                                  alignment: Alignment.center,
                                                  children: <Widget>[
                                                    CircularProgressIndicator(
                                                      backgroundColor:
                                                          Colors.cyanAccent,
                                                    ),
                                                    ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              16),
                                                      child: Image.network(
                                                          _data[count]['url'],
                                                          repeat: ImageRepeat
                                                              .repeat,
                                                          fit: BoxFit.fill,
                                                          height:
                                                              MediaQuery.of(ctx)
                                                                      .size
                                                                      .height *
                                                                  .4,
                                                          width:
                                                              MediaQuery.of(ctx)
                                                                  .size
                                                                  .width),
                                                    )
                                                  ],
                                                )
                                              : Expanded(
                                                  child: VideoPlayerWidget(
                                                    url: _data[count]['url'],
                                                    methodChannel:
                                                        _methodChannel,
                                                  ),
                                                ),
                                          Divider(
                                            height: 10,
                                            color: Colors.cyanAccent,
                                          ),
                                          Expanded(
                                              child: ListView(
                                            children: <Widget>[
                                              Padding(
                                                padding: EdgeInsets.only(
                                                    left: 8,
                                                    right: 8,
                                                    top: 4,
                                                    bottom: 8),
                                                child: Text.rich(
                                                  TextSpan(children: [
                                                    TextSpan(
                                                        text:
                                                            '${_data[count]['title']}:\n\n',
                                                        style: TextStyle(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            letterSpacing: 2.0,
                                                            fontStyle: FontStyle
                                                                .italic)),
                                                    TextSpan(
                                                        text:
                                                            '${_data[count]['explanation']}',
                                                        style: TextStyle(
                                                            wordSpacing: 3.0))
                                                  ]),
                                                ),
                                              )
                                            ],
                                            scrollDirection: Axis.vertical,
                                          ))
                                        ],
                                      )
                                    : Row(
                                        children: <Widget>[
                                          RotatedBox(
                                            quarterTurns: 3,
                                            child: Text(
                                              _data[count]['date'],
                                              style: TextStyle(
                                                  letterSpacing: 3.0,
                                                  fontStyle: FontStyle.italic,
                                                  color: Colors.black,
                                                  shadows: [
                                                    Shadow(
                                                        color: Colors.black38,
                                                        blurRadius: 2,
                                                        offset:
                                                            Offset(1.5, 1.75))
                                                  ]),
                                            ),
                                          ),
                                          VerticalDivider(
                                            width: 6,
                                          ),
                                          _data[count]['media_type'] == 'image'
                                              ? Stack(
                                                  alignment: Alignment.center,
                                                  children: <Widget>[
                                                    CircularProgressIndicator(
                                                      backgroundColor:
                                                          Colors.cyanAccent,
                                                    ),
                                                    ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              16),
                                                      child: Image.network(
                                                          _data[count]['url'],
                                                          repeat: ImageRepeat
                                                              .repeat,
                                                          fit: BoxFit.fill,
                                                          height:
                                                              MediaQuery.of(ctx)
                                                                  .size
                                                                  .height,
                                                          width:
                                                              MediaQuery.of(ctx)
                                                                      .size
                                                                      .width *
                                                                  .45),
                                                    )
                                                  ],
                                                )
                                              : Expanded(
                                                  child: VideoPlayerWidget(
                                                    url: _data[count]['url'],
                                                    methodChannel:
                                                        _methodChannel,
                                                  ),
                                                ),
                                          Expanded(
                                              child: ListView(
                                            children: <Widget>[
                                              Padding(
                                                padding: EdgeInsets.only(
                                                    left: 8,
                                                    right: 8,
                                                    top: 4,
                                                    bottom: 8),
                                                child: Text.rich(
                                                  TextSpan(children: [
                                                    TextSpan(
                                                        text:
                                                            '${_data[count]['title']}:\n\n',
                                                        style: TextStyle(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            letterSpacing: 2.0,
                                                            fontStyle: FontStyle
                                                                .italic)),
                                                    TextSpan(
                                                        text:
                                                            '${_data[count]['explanation']}',
                                                        style: TextStyle(
                                                            wordSpacing: 3.0)),
                                                  ]),
                                                ),
                                              )
                                            ],
                                            scrollDirection: Axis.vertical,
                                          )),
                                          Align(
                                            child: PopupMenuButton(
                                                icon: Icon(
                                                  Icons.more_vert,
                                                  size: 20,
                                                ),
                                                onSelected: (value) {
                                                  switch (value) {
                                                    case 0:
                                                      shareText(
                                                          'Astronomy Picture of the Day for ${_data[count]['date']} :\n\n${_data[count]['title']} :-\n\n${_data[count]['explanation']}\n\n${_data[count]['url']}\n\nShared via astroZ (https://play.google.com/store/apps/details?id=com.example.itzmeanjan.nasa_apod)',
                                                          'text/plain');
                                                      break;
                                                    case 1:
                                                      showDialog(
                                                          context: ctx,
                                                          builder: (ctx) {
                                                            return SimpleDialog(
                                                              elevation: 12,
                                                              title: Text(
                                                                "Copyright",
                                                                style: TextStyle(
                                                                    letterSpacing:
                                                                        3),
                                                              ),
                                                              contentPadding:
                                                                  EdgeInsets
                                                                      .all(8),
                                                              titlePadding:
                                                                  EdgeInsets
                                                                      .all(6),
                                                              children: <
                                                                  Widget>[
                                                                Text(
                                                                  '\u{00a9} ${_data[count]['copyright']}',
                                                                  maxLines: 8,
                                                                  style: TextStyle(
                                                                      fontStyle:
                                                                          FontStyle
                                                                              .italic),
                                                                  overflow:
                                                                      TextOverflow
                                                                          .fade,
                                                                ),
                                                              ],
                                                            );
                                                          });
                                                      break;
                                                    case 2:
                                                      isPermissionAvailable()
                                                          .then((bool perm) {
                                                        if (!perm)
                                                          requestPermission()
                                                              .then((bool
                                                                  permReq) {
                                                            if (permReq) {
                                                              getTargetPath()
                                                                  .then((String
                                                                      path) {
                                                                _targetPath =
                                                                    path;
                                                                isDirectoryPresent(
                                                                        _targetPath)
                                                                    .then((bool
                                                                        presence) {
                                                                  if (!presence) {
                                                                    createDirectory(
                                                                            _targetPath)
                                                                        .then((bool
                                                                            createDir) {
                                                                      if (createDir)
                                                                        isFilePresent('$_targetPath/${_data[count]['date']}${RegExp(r"(\.[a-zA-Z]+)$").stringMatch(_data[count]['url'])}').then((bool
                                                                            filePresence) {
                                                                          if (!filePresence)
                                                                            downloadImage(_data[count]['url'], '$_targetPath/${_data[count]['date']}${RegExp(r"(\.[a-zA-Z]+)$").stringMatch(_data[count]['url'])}').then((bool
                                                                                downloadRes) {
                                                                              showToast(downloadRes ? 'Downloaded Image' : 'Failed to download Image');
                                                                            });
                                                                          else
                                                                            showToast('Already downloaded Image');
                                                                        });
                                                                    });
                                                                  } else
                                                                    isFilePresent(
                                                                            '$_targetPath/${_data[count]['date']}${RegExp(r"(\.[a-zA-Z]+)$").stringMatch(_data[count]['url'])}')
                                                                        .then((bool
                                                                            filePresence) {
                                                                      if (!filePresence)
                                                                        downloadImage(_data[count]['url'], '$_targetPath/${_data[count]['date']}${RegExp(r"(\.[a-zA-Z]+)$").stringMatch(_data[count]['url'])}').then((bool
                                                                            downloadRes) {
                                                                          showToast(downloadRes
                                                                              ? 'Downloaded Image'
                                                                              : 'Failed to download Image');
                                                                        });
                                                                      else
                                                                        showToast(
                                                                            'Already downloaded Image');
                                                                    });
                                                                });
                                                              });
                                                            } else
                                                              showToast(
                                                                  'Permission Required !!!');
                                                          });
                                                        else
                                                          getTargetPath().then(
                                                              (String path) {
                                                            _targetPath = path;
                                                            isDirectoryPresent(
                                                                    _targetPath)
                                                                .then((bool
                                                                    presence) {
                                                              if (!presence) {
                                                                createDirectory(
                                                                        _targetPath)
                                                                    .then((bool
                                                                        createDir) {
                                                                  if (createDir)
                                                                    isFilePresent(
                                                                            '$_targetPath/${_data[count]['date']}${RegExp(r"(\.[a-zA-Z]+)$").stringMatch(_data[count]['url'])}')
                                                                        .then((bool
                                                                            filePresence) {
                                                                      if (!filePresence)
                                                                        downloadImage(_data[count]['url'], '$_targetPath/${_data[count]['date']}${RegExp(r"(\.[a-zA-Z]+)$").stringMatch(_data[count]['url'])}').then((bool
                                                                            downloadRes) {
                                                                          showToast(downloadRes
                                                                              ? 'Downloaded Image'
                                                                              : 'Failed to download Image');
                                                                        });
                                                                      else
                                                                        showToast(
                                                                            'Already downloaded Image');
                                                                    });
                                                                });
                                                              } else
                                                                isFilePresent(
                                                                        '$_targetPath/${_data[count]['date']}${RegExp(r"(\.[a-zA-Z]+)$").stringMatch(_data[count]['url'])}')
                                                                    .then((bool
                                                                        filePresence) {
                                                                  if (!filePresence)
                                                                    downloadImage(
                                                                            _data[count][
                                                                                'url'],
                                                                            '$_targetPath/${_data[count]['date']}${RegExp(r"(\.[a-zA-Z]+)$").stringMatch(_data[count]['url'])}')
                                                                        .then((bool
                                                                            downloadRes) {
                                                                      showToast(downloadRes
                                                                          ? 'Downloaded Image'
                                                                          : 'Failed to download Image');
                                                                    });
                                                                  else
                                                                    showToast(
                                                                        'Already downloaded Image');
                                                                });
                                                            });
                                                          });
                                                      });
                                                      break;
                                                    case 3:
                                                      isPermissionAvailable()
                                                          .then((bool perm) {
                                                        if (!perm)
                                                          requestPermission()
                                                              .then((bool
                                                                  permReq) {
                                                            if (permReq)
                                                              getTargetPath()
                                                                  .then((String
                                                                      path) {
                                                                _targetPath =
                                                                    path;
                                                                isDirectoryPresent(
                                                                        _targetPath)
                                                                    .then((bool
                                                                        presence) {
                                                                  if (!presence) {
                                                                    createDirectory(
                                                                            _targetPath)
                                                                        .then((bool
                                                                            createDir) {
                                                                      if (createDir)
                                                                        isFilePresent('$_targetPath/${_data[count]['date']}${RegExp(r"(\.[a-zA-Z]+)$").stringMatch(_data[count]['url'])}').then((bool
                                                                            filePresence) {
                                                                          if (!filePresence)
                                                                            downloadImage(_data[count]['url'], '$_targetPath/${_data[count]['date']}${RegExp(r"(\.[a-zA-Z]+)$").stringMatch(_data[count]['url'])}').then((bool
                                                                                downloadRes) {
                                                                              if (downloadRes)
                                                                                setWallPaper('$_targetPath/${_data[count]['date']}${RegExp(r"(\.[a-zA-Z]+)$").stringMatch(_data[count]['url'])}').then((bool setWall) {
                                                                                  showToast(setWall ? 'Set as Wallpaper' : 'Failed to set as Wallpaper');
                                                                                });
                                                                            });
                                                                          else
                                                                            setWallPaper('$_targetPath/${_data[count]['date']}${RegExp(r"(\.[a-zA-Z]+)$").stringMatch(_data[count]['url'])}').then((bool
                                                                                setWall) {
                                                                              showToast(setWall ? 'Set as Wallpaper' : 'Failed to set as Wallpaper');
                                                                            });
                                                                        });
                                                                    });
                                                                  } else
                                                                    isFilePresent(
                                                                            '$_targetPath/${_data[count]['date']}${RegExp(r"(\.[a-zA-Z]+)$").stringMatch(_data[count]['url'])}')
                                                                        .then((bool
                                                                            filePresence) {
                                                                      if (!filePresence)
                                                                        downloadImage(_data[count]['url'], '$_targetPath/${_data[count]['date']}${RegExp(r"(\.[a-zA-Z]+)$").stringMatch(_data[count]['url'])}').then((bool
                                                                            downloadRes) {
                                                                          if (downloadRes)
                                                                            setWallPaper('$_targetPath/${_data[count]['date']}${RegExp(r"(\.[a-zA-Z]+)$").stringMatch(_data[count]['url'])}').then((bool
                                                                                setWall) {
                                                                              showToast(setWall ? 'Set as Wallpaper' : 'Failed to set as Wallpaper');
                                                                            });
                                                                        });
                                                                      else
                                                                        setWallPaper('$_targetPath/${_data[count]['date']}${RegExp(r"(\.[a-zA-Z]+)$").stringMatch(_data[count]['url'])}').then((bool
                                                                            setWall) {
                                                                          showToast(setWall
                                                                              ? 'Set as Wallpaper'
                                                                              : 'Failed to set as Wallpaper');
                                                                        });
                                                                    });
                                                                });
                                                              });
                                                            else
                                                              showToast(
                                                                  'Permission Required !!!');
                                                          });
                                                        else
                                                          getTargetPath().then(
                                                              (String path) {
                                                            _targetPath = path;
                                                            isDirectoryPresent(
                                                                    _targetPath)
                                                                .then((bool
                                                                    presence) {
                                                              if (!presence) {
                                                                createDirectory(
                                                                        _targetPath)
                                                                    .then((bool
                                                                        createDir) {
                                                                  if (createDir)
                                                                    isFilePresent(
                                                                            '$_targetPath/${_data[count]['date']}${RegExp(r"(\.[a-zA-Z]+)$").stringMatch(_data[count]['url'])}')
                                                                        .then((bool
                                                                            filePresence) {
                                                                      if (!filePresence)
                                                                        downloadImage(_data[count]['url'], '$_targetPath/${_data[count]['date']}${RegExp(r"(\.[a-zA-Z]+)$").stringMatch(_data[count]['url'])}').then((bool
                                                                            downloadRes) {
                                                                          if (downloadRes)
                                                                            setWallPaper('$_targetPath/${_data[count]['date']}${RegExp(r"(\.[a-zA-Z]+)$").stringMatch(_data[count]['url'])}').then((bool
                                                                                setWall) {
                                                                              showToast(setWall ? 'Set as Wallpaper' : 'Failed to set as Wallpaper');
                                                                            });
                                                                        });
                                                                      else
                                                                        setWallPaper('$_targetPath/${_data[count]['date']}${RegExp(r"(\.[a-zA-Z]+)$").stringMatch(_data[count]['url'])}').then((bool
                                                                            setWall) {
                                                                          showToast(setWall
                                                                              ? 'Set as Wallpaper'
                                                                              : 'Failed to set as Wallpaper');
                                                                        });
                                                                    });
                                                                });
                                                              } else
                                                                isFilePresent(
                                                                        '$_targetPath/${_data[count]['date']}${RegExp(r"(\.[a-zA-Z]+)$").stringMatch(_data[count]['url'])}')
                                                                    .then((bool
                                                                        filePresence) {
                                                                  if (!filePresence)
                                                                    downloadImage(
                                                                            _data[count][
                                                                                'url'],
                                                                            '$_targetPath/${_data[count]['date']}${RegExp(r"(\.[a-zA-Z]+)$").stringMatch(_data[count]['url'])}')
                                                                        .then((bool
                                                                            downloadRes) {
                                                                      if (downloadRes)
                                                                        setWallPaper('$_targetPath/${_data[count]['date']}${RegExp(r"(\.[a-zA-Z]+)$").stringMatch(_data[count]['url'])}').then((bool
                                                                            setWall) {
                                                                          showToast(setWall
                                                                              ? 'Set as Wallpaper'
                                                                              : 'Failed to set as Wallpaper');
                                                                        });
                                                                    });
                                                                  else
                                                                    setWallPaper(
                                                                            '$_targetPath/${_data[count]['date']}${RegExp(r"(\.[a-zA-Z]+)$").stringMatch(_data[count]['url'])}')
                                                                        .then((bool
                                                                            setWall) {
                                                                      showToast(setWall
                                                                          ? 'Set as Wallpaper'
                                                                          : 'Failed to set as Wallpaper');
                                                                    });
                                                                });
                                                            });
                                                          });
                                                      });
                                                      break;
                                                  }
                                                },
                                                tooltip: 'Options',
                                                padding: EdgeInsets.all(0),
                                                elevation: 16,
                                                itemBuilder: (ctx) {
                                                  return <PopupMenuItem>[
                                                    PopupMenuItem(
                                                      child: Text("Share"),
                                                      value: 0,
                                                    ),
                                                    _data[count][
                                                                'media_type'] ==
                                                            'image'
                                                        ? PopupMenuItem(
                                                            child: Text(
                                                                "Download"),
                                                            value: 2,
                                                          )
                                                        : null,
                                                    _data[count][
                                                                'media_type'] ==
                                                            'image'
                                                        ? PopupMenuItem(
                                                            child: Text(
                                                                "Set as Wallpaper"),
                                                            value: 3,
                                                          )
                                                        : null,
                                                    !['null', 'NA'].contains(
                                                            _data[count]
                                                                ['copyright'])
                                                        ? PopupMenuItem(
                                                            child: Text(
                                                                "Copyright"),
                                                            value: 1,
                                                          )
                                                        : null,
                                                  ];
                                                }),
                                            alignment: Alignment.topRight,
                                          ),
                                        ],
                                      ))),
                  );
                },
                padding:
                    EdgeInsets.only(left: 14, right: 14, top: 36, bottom: 36),
              ),
      ),
    );
  }
}
