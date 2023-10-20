// ignore_for_file: prefer_const_constructors

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:zkfinger10/finger_status.dart';
import 'package:zkfinger10/finger_status_type.dart';
import 'package:zkfinger10/zk_finger.dart';
import 'package:zkfinger10_example/network_info.dart';

import 'functions.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MaterialApp(home: MyApp()));
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String? _platformVersion = 'Unknown';

  final TextEditingController _registerationCodeController =
      TextEditingController(text: "MAMASODIKOV");
  final TextEditingController _biometricController =
      TextEditingController(text: "BASE64");
  final TextEditingController _sendUrlController = TextEditingController();
  String sendUrl = 'https://google.com/';
  String base64Image = 'base64isNotGenerated';

  String? score;
  String? message;

  @override
  void dispose() {
    ZkFinger.onDestroy();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String? platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      platformVersion = await ZkFinger.platformVersion;
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }
    ZkFinger.imageStream.receiveBroadcastStream().listen(mapFingerImage);
    ZkFinger.statusChangeStream.receiveBroadcastStream().listen(updateStatus);

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  Uint8List? fingerImages;
  String statusText = '';
  String stringLengthBytes = '';

  FingerStatus? fingerStatus;
  FingerStatusType? tempStatusType;

  void updateStatus(dynamic value) {
    Map<dynamic, dynamic> statusMap = value as Map<dynamic, dynamic>;
    FingerStatusType statusType =
        FingerStatusType.values[statusMap['fingerStatus']];
    fingerStatus = FingerStatus(
        statusMap['message'], statusType, statusMap['id'], statusMap['data']);

    print(fingerStatus?.message);

    if (statusType == tempStatusType &&
        tempStatusType == FingerStatusType.CAPTURE_ERROR) {
      //ignore capture error when finger device get stucked
      statusText = 'CAPTURE ERROR';
    } else {
      tempStatusType = statusType;
      setState(() {
        setBiometricBase64TextField();
        statusText = statusType.toString();
      });
    }
  }

  void setBiometricBase64TextField() {
    if (fingerStatus!.statusType == FingerStatusType.ENROLL_SUCCESS) {
      resetFieldsData();
      _biometricController.text = fingerStatus!.data;
      message = '${fingerStatus!.id} enroll';
    } else if (fingerStatus!.statusType ==
        FingerStatusType.ENROLL_ALREADY_EXIST) {
      resetFieldsData();
      score = fingerStatus!.data;
      message = '${fingerStatus!.id} already enrolled';
    } else if (fingerStatus!.statusType ==
        FingerStatusType.IDENTIFIED_SUCCESS) {
      resetFieldsData();
      message = '${fingerStatus!.id} identified';
      score = fingerStatus!.data;
    } else if (fingerStatus!.statusType == FingerStatusType.ENROLL_STARTED) {
      resetFieldsData();
      message = '${fingerStatus!.id} confirm';
      _biometricController.text = 'Current Confirm Index ${fingerStatus!.data}';
    } else if (fingerStatus!.statusType == FingerStatusType.ENROLL_CONFIRM) {
      resetFieldsData();
      message = '${fingerStatus!.id} confirm';
      _biometricController.text = 'Current Confirm Index ${fingerStatus!.data}';
    } else {
      resetFieldsData();
    }
    stringLengthBytes = 'Text Size: ${_biometricController.text.length} bytes';
    statusText = '$statusText$stringLengthBytes\n';
  }

  void resetFieldsData() {
    _biometricController.text = '---';
    message = '---';
    score = '---';
  }

  String uint8ListTob64(Uint8List uint8list) {
    String base64String = base64Encode(uint8list);
    String header = "data:image/png;base64,";
    return header + base64String;
  }

  void mapFingerImage(dynamic imageBytes) {
    setState(() {
      try {
        fingerImages = imageBytes;
        base64Image = uint8ListTob64(fingerImages!);
        print('========= BASE64_IMAGE: $base64Image');
      } catch (e) {
        print(e);
      }
    });
  }

  bool? isDeviceSupported;

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    return MaterialApp(
      home: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          backgroundColor: Colors.indigo,
          title: const Text(
              'FingerPrint Plugin Showcase \t\t\t\t\t\t\t\t\t <===|| Swipe left to view rest ||'),
        ),
        body: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: MediaQuery.of(context).size.width + 230,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SizedBox(
                  width: 10,
                ),
                SingleChildScrollView(
                  child: LimitedBox(
                    maxWidth: 150,
                    child: Column(
                      children: <Widget>[
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigo,
                              elevation: 5,
                              padding: const EdgeInsets.all(12.0),
                            ),
                            onPressed: () async {
                              await ZkFinger.openConnection();
                            },
                            child: const Text(
                              'Open Connection',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigo,
                              elevation: 5,
                              padding: const EdgeInsets.all(12.0),
                            ),
                            // onPressed: null,
                            onPressed: () async {
                              await ZkFinger.startListen(
                                  userId: _registerationCodeController.text);
                            },
                            child: const Text(
                              'Start Listening',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigo,
                              elevation: 5,
                              padding: const EdgeInsets.all(12.0),
                            ),
                            onPressed: () async {
                              await ZkFinger.registerFinger(
                                  userId: _registerationCodeController.text);
                            },
                            child: Text(
                              'Enroll Finger',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigo,
                              elevation: 5,
                              padding: const EdgeInsets.all(12.0),
                            ),
                            onPressed: () async {
                              await ZkFinger.identify(
                                  userId: _registerationCodeController.text);
                            },
                            child: Text(
                              'Identify Finger',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigo,
                              elevation: 5,
                              padding: const EdgeInsets.all(12.0),
                            ),
                            onPressed: () async {
                              await ZkFinger.clearFingerDatabase();
                            },
                            child: Text(
                              'Clear finger\nDatabase',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigo,
                              elevation: 5,
                              padding: const EdgeInsets.all(12.0),
                            ),
                            onPressed: () async {
                              await ZkFinger.stopListen();
                            },
                            child: Text(
                              'Stop Listening',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigo,
                              elevation: 5,
                              padding: const EdgeInsets.all(12.0),
                            ),
                            onPressed: () async {
                              await ZkFinger.closeConnection();
                            },
                            child: Text(
                              'Close Connection',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  width: 10,
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    fingerImages != null
                        ? Container(
                            decoration: BoxDecoration(
                                border:
                                    Border.all(color: Colors.black, width: 2)),
                            child: Image.memory(
                              fingerImages!,
                              width: 150,
                              height: 150,
                              fit: BoxFit.contain,
                            ),
                          )
                        : SizedBox(
                            height: 150, width: 150, child: Placeholder()),
                    Container(
                        decoration: BoxDecoration(
                            border: Border.all(color: Colors.black, width: 2)),
                        height: 148,
                        width: 154,
                        child: _getFingerStatusImage()),
                  ],
                ),
                SizedBox(
                  width: 10,
                ),
                SizedBox(
                  width: MediaQuery.of(context).size.width * .3,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: <Widget>[
                        TextFormField(
                          controller: _registerationCodeController,
                          decoration:
                              InputDecoration(labelText: "Registration Code"),
                        ),
                        Text('Biometric Base64 Text:',
                            style:
                                TextStyle(fontSize: 14, color: Colors.indigo)),
                        TextFormField(
                            // readOnly: true,
                            controller: _biometricController,
                            maxLines: null,
                            style: TextStyle(fontSize: 15)),
                        Text('Score: $score',
                            style:
                                TextStyle(fontSize: 14, color: Colors.indigo)),
                        Text('Message: $message',
                            style:
                                TextStyle(fontSize: 14, color: Colors.indigo)),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  width: 10,
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(top: 10),
                    child: SizedBox(child: Text('STATUS:\n\n$statusText')),
                  ),
                ),
                SizedBox(
                  width: 10,
                ),
                Expanded(
                  child: Column(
                    children: [
                      TextField(
                        controller: _sendUrlController,
                        onChanged: (text) {
                          sendUrl = text;
                        },
                        decoration: InputDecoration(
                            hintText: "Input URL with http:// or https://"),
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      LimitedBox(
                        maxWidth: 150,
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigo,
                              elevation: 5,
                              padding: const EdgeInsets.all(12.0),
                            ),
                            onPressed: () => sendText(),
                            child: const Text(
                              'Send Text',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 10,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<bool> sendText() async {
    final NetworkInfo networkInfo =
        NetworkInfoImpl(InternetConnectionChecker());
    final Dio dio = Dio();

    if (await networkInfo.isConnected) {
      ///

      try {
        final response = await dio.post(sendUrl,
            options: Options(
                headers: <String, String>{'Content-Type': 'application/json'}),
            data: {
              "date": DateTime.now().toString(),
              "finger": base64Image
            });
        final data = response.data;
        print(data.toString());
        if (response.statusCode == 200) {
          CustomToast.showToast(data.toString());
          return true;
        } else {
          CustomToast.showToast(data.toString());
          print(data.toString());
          return false;
        }
      } on DioException catch (e) {
        print(e.error);

        if (e.type == DioExceptionType.badResponse) {
          if (e.response != null) {
            CustomToast.showToast('Server error: ' + "${e.response!.data}");
            print('Server error: ' + "${e.response!.data}");
          } else {
            CustomToast.showToast(e.error.toString());
          }
        } else {
          CustomToast.showToast(e.error.toString());
        }
        return false;
      }
    } else {
      CustomToast.showToast("No internet!");
      return false;
    }
  }

  Widget _getFingerStatusImage() {
    if (fingerStatus == null) {
      return SvgPicture.asset(
        'assets/finger.svg',
        color: Colors.black38,
        width: 70,
        height: 120,
      );
    }
    Color svgColor = Colors.black12;
    switch (fingerStatus!.statusType) {
      case FingerStatusType.STARTED_ALREADY:
      case FingerStatusType.STARTED_SUCCESS:
        svgColor = Colors.indigo;
        break;
      case FingerStatusType.IDENTIFIED_START_FIRST:
      case FingerStatusType.IDENTIFIED_FAILED:
      case FingerStatusType.IDENTIFIED_SUCCESS:
        svgColor = Colors.blue;
        break;
      case FingerStatusType.ENROLL_ALREADY_EXIST:
      case FingerStatusType.ENROLL_CONFIRM:
      case FingerStatusType.ENROLL_STARTED:
      case FingerStatusType.ENROLL_SUCCESS:
        svgColor = Colors.green;
        break;
      case FingerStatusType.STOPPED_ALREADY:
      case FingerStatusType.STOPPED_SUCCESS:
        svgColor = Colors.red;
        break;
      case FingerStatusType.FINGER_CLEARED:
        svgColor = Colors.yellow;
        break;
      case FingerStatusType.STARTED_FAILED:
      case FingerStatusType.STARTED_ERROR:
      case FingerStatusType.ENROLL_FAILED:
      case FingerStatusType.STOPPED_ERROR:
      case FingerStatusType.CAPTURE_ERROR:
        svgColor = Colors.redAccent;
        break;
      default:
        svgColor = Colors.black38;
    }

    return SvgPicture.asset(
      'assets/finger.svg',
      color: svgColor,
      width: 70,
      height: 120,
    );
  }
}
