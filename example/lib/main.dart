// ignore_for_file: prefer_const_constructors

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:uuid/uuid.dart';

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
  runApp(const MaterialApp(home: MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  String? _platformVersion = 'Unknown';

  final TextEditingController _registerationCodeController =
  TextEditingController(text: "MAMASODIKOV");
  final TextEditingController _biometricController =
  TextEditingController(text: "Here will display base64 finger template");
  final TextEditingController _sendUrlController = TextEditingController();
  final TextEditingController _idleText1 =
  TextEditingController(text: "Copy base64 to verify");
  final TextEditingController _idleText2 =
  TextEditingController(text: "Copy base64 to verify");
  String sendUrl = 'https://google.com/';
  String base64Image = 'base64isNotGenerated';

  String? score;
  String? message;
  Map<String, String> users = {};

  // New state variables for enhanced features
  Map<String, String> databaseUsers = {};
  int databaseUserCount = 0;
  final TextEditingController _exportUrlController = TextEditingController(
      text: "https://68d98bdb90a75154f0daa3f8.mockapi.io/api/data"
  );
  final TextEditingController _importUrlController = TextEditingController(
      text: "https://68d98bdb90a75154f0daa3f8.mockapi.io/api/data"
  );
  bool _isLoadingFromUrl = false;
  bool _isExporting = false;
  bool _isLoadingDatabase = false;

  @override
  void dispose() {
    ZkFinger.onDestroy();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    initPlatformState();
    _refreshDatabaseInfo();
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
  bool? isDeviceSupported;

  void updateStatus(dynamic value) {
    Map<dynamic, dynamic> statusMap = value as Map<dynamic, dynamic>;
    FingerStatusType statusType =
    FingerStatusType.values[statusMap['fingerStatus']];
    fingerStatus = FingerStatus(
        statusMap['message'], statusType, statusMap['id'], statusMap['data']);

    print(fingerStatus?.message);

    if (statusType == tempStatusType &&
        tempStatusType == FingerStatusType.CAPTURE_ERROR) {
      //ignore capture error when finger device get stuck
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
    if (fingerStatus?.statusType == FingerStatusType.ENROLL_SUCCESS) {
      resetFieldsData();
      _biometricController.text = fingerStatus?.data ?? 'null';
      message = '${fingerStatus?.id} enroll';
    } else if (fingerStatus?.statusType ==
        FingerStatusType.ENROLL_ALREADY_EXIST) {
      resetFieldsData();
      score = fingerStatus?.data;
      message = '${fingerStatus!.id} already enrolled';
    } else if (fingerStatus?.statusType == FingerStatusType.FINGER_EXTRACTED) {
      resetFieldsData();
      _biometricController.text = fingerStatus?.data ?? 'null';
      message = fingerStatus?.message;
    } else if (fingerStatus!.statusType ==
        FingerStatusType.IDENTIFIED_SUCCESS) {
      resetFieldsData();
      message = '${fingerStatus?.id} identified';
      score = fingerStatus?.data;
    } else if (fingerStatus!.statusType == FingerStatusType.IDENTIFIED_FAILED) {
      resetFieldsData();
      message = 'User identify failed';
      score = fingerStatus?.data;
    } else if (fingerStatus?.statusType == FingerStatusType.VERIFIED_SUCCESS) {
      resetFieldsData();
      message = 'Given templates are verified';
      score = fingerStatus?.data;
    } else if (fingerStatus?.statusType == FingerStatusType.VERIFIED_FAILED) {
      resetFieldsData();
      message = 'Verify failed';
      score = fingerStatus?.data;
    } else if (fingerStatus?.statusType == FingerStatusType.ENROLL_STARTED) {
      resetFieldsData();
      message = '${fingerStatus?.id} confirm';
      _biometricController.text = 'Current Confirm Index ${fingerStatus?.data}';
    } else if (fingerStatus?.statusType == FingerStatusType.ENROLL_CONFIRM) {
      resetFieldsData();
      message = '${fingerStatus?.id} confirm';
      _biometricController.text = 'Current Confirm Index ${fingerStatus?.data}';
    } else {
      resetFieldsData();
    }
    stringLengthBytes = 'Text Size: ${_biometricController.text.length} bytes';
    statusText = '$statusText$stringLengthBytes\n';
  }

  void resetFieldsData() {
    // _biometricController.text = '---';
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

  // New methods for enhanced functionality
  Future<void> _exportAllUsers() async {
    if (_exportUrlController.text.trim().isEmpty) {
      _showMessage('Please enter a valid export URL');
      return;
    }

    setState(() {
      _isExporting = true;
    });

    try {
      // Get all users from database
      final allUsers = await ZkFinger.getAllUsers();
      final userCount = await ZkFinger.getUserCount();

      if (allUsers == null || allUsers.isEmpty) {
        if (mounted) {
          _showMessage('No users found in database to export');
        }
        return;
      }

      // Prepare export data
      final exportData = {
        'users': allUsers,
        'exportedAt': DateTime.now().toIso8601String(),
      };

      // Send POST request to export URL
      final dio = Dio();
      final response = await dio.post(
        _exportUrlController.text.trim(),
        data: exportData,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      print(response);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          _showMessage('Successfully exported ${allUsers.length} users to URL');
          _refreshDatabaseInfo();
        }
      } else {
        if (mounted) {
          _showMessage('Failed to export data: ${response.statusCode}');
        }
      }
    } catch (e) {
      if (mounted) {
        _showMessage('Export error: $e');
      }
    } finally {
      setState(() {
        _isExporting = false;
      });
    }
  }

  Future<void> _importFromUrl() async {
    if (_importUrlController.text.trim().isEmpty) {
      if (mounted) {
        _showMessage('Please enter a valid import URL');
      }
      return;
    }

    setState(() {
      _isLoadingFromUrl = true;
    });

    try {
      final dio = Dio();
      final response = await dio.get(_importUrlController.text.trim());

      print(response.data);

      if (response.statusCode == 200) {
        final data = response.data;
        print('Response data type: ${data.runtimeType}');

        final Map<String, String> loadedUsers = {};

        // Handle different response formats
        if (data is List) {
          // Handle array format: [{"users": {...}}, {"users": {...}}]
          print('Processing array of ${data.length} items');
          for (var item in data) {
            if (item is Map && item.containsKey('users')) {
              final usersData = item['users'];
              if (usersData is Map) {
                usersData.forEach((key, value) {
                  final userId = key.toString();
                  final template = value.toString();
                  loadedUsers[userId] = template;
                });
              }
            }
          }
        } else if (data is Map && data.containsKey('users')) {
          // Handle single object format: {"users": {...}}
          print('Processing single object');
          final usersData = data['users'];
          if (usersData is Map) {
            usersData.forEach((key, value) {
              final userId = key.toString();
              final template = value.toString();
              loadedUsers[userId] = template;
            });
          }
        } else {
          print('Data validation failed:');
          print('- data is List: ${data is List}');
          print('- data is Map: ${data is Map}');
          if (data is Map) {
            print('- data contains users: ${(data as Map).containsKey('users')}');
            print('- data keys: ${(data as Map).keys.toList()}');
          }
          if (mounted) {
            _showMessage('Invalid data format. Expected array of objects or single object with "users" key');
          }
          return;
        }

        print('Total loaded users: ${loadedUsers.length}');
          
          if (loadedUsers.isNotEmpty) {
            final success = await ZkFinger.clearAndLoadDatabase(vUserList: loadedUsers);
            if (success == true) {
              if (mounted) {
                _showMessage('Successfully imported ${loadedUsers.length} users from URL');
                _refreshDatabaseInfo();
              }
            } else {
              if (mounted) {
                _showMessage('Failed to load users to database');
              }
            }
          } else {
            if (mounted) {
              _showMessage('No users found in URL response');
            }
          }

      } else {
        if (mounted) {
          _showMessage('Failed to fetch data from URL: ${response.statusCode}');
        }
      }
    } catch (e) {
      print('Import error: $e');
      if (mounted) {
        _showMessage('Import error: $e');
      }
    } finally {
      setState(() {
        _isLoadingFromUrl = false;
      });
    }
  }

  Future<void> _refreshDatabaseInfo() async {
    setState(() {
      _isLoadingDatabase = true;
    });

    try {
      final allUsers = await ZkFinger.getAllUsers();
      final userCount = await ZkFinger.getUserCount();

      setState(() {
        databaseUsers = allUsers ?? {};
        databaseUserCount = userCount ?? 0;
      });
    } catch (e) {
      print('Error refreshing database info: $e');
    } finally {
      setState(() {
        _isLoadingDatabase = false;
      });
    }
  }

  void _showDatabaseUsersDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Current Database Users'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Users: $databaseUserCount',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 5),
                const Text(
                  'User List:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: databaseUsers.isEmpty
                      ? const Center(child: Text('No users in database'))
                      : ListView.builder(
                    itemCount: databaseUsers.length,
                    itemBuilder: (context, index) {
                      final userId = databaseUsers.keys.elementAt(index);
                      final template = databaseUsers[userId]!;
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 2),
                        child: ListTile(
                          leading: CircleAvatar(
                            child: Text('${index + 1}'),
                          ),
                          title: Text(
                            'User ID: $userId',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'Template: ${template.length > 50 ? '${template.substring(0, 50)}...' : template}',
                            style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.copy),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: template));
                              if (mounted) {
                                _showMessage('Template copied to clipboard');
                              }
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actionsPadding: EdgeInsets.zero,
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () {
                final jsonData = jsonEncode({
                  'users': databaseUsers,
                  'exportedAt': DateTime.now().toIso8601String(),
                });
                Clipboard.setData(ClipboardData(text: jsonData));
                if (mounted) {
                  _showMessage('Database data copied to clipboard');
                }
              },
              child: const Text('Copy as JSON'),
            ),
          ],
        );
      },
    );
  }

  void _showMessage(String message) {
    if (mounted && _scaffoldMessengerKey.currentState != null) {
      _scaffoldMessengerKey.currentState!.showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      // DeviceOrientation.landscapeLeft,
      // DeviceOrientation.landscapeRight,
    ]);

    return MaterialApp(
      scaffoldMessengerKey: _scaffoldMessengerKey,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.light,
        ),
        cardTheme: CardThemeData(
          elevation: 4,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 2,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ),
      home: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          title: const Text(
            'ZKFinger10 Professional Dashboard',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          elevation: 0,
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.primary.withOpacity(0.05),
                Theme.of(context).colorScheme.secondary.withOpacity(0.05),
              ],
            ),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            padding: const EdgeInsets.all(8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: MediaQuery.of(context).size.width,
                  minHeight: MediaQuery.of(context).size.height - 100,
                ),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      // Control Panel
                      SizedBox(
                          width: 180,
                          child: Card(
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: SingleChildScrollView(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        'Device Control',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 8),
                                          ),
                                          onPressed: () async {
                                            await ZkFinger.openConnection();
                                          },
                                          icon: const Icon(Icons.power_settings_new,
                                              size: 16),
                                          label: const Text('Connect',
                                              style: TextStyle(fontSize: 12)),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.blue,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 8),
                                          ),
                                          onPressed: () async {
                                            await ZkFinger.startListen(
                                                userId: _registerationCodeController
                                                    .text);
                                          },
                                          icon: const Icon(Icons.hearing, size: 16),
                                          label: const Text('Listen',
                                              style: TextStyle(fontSize: 12)),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.orange,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 8),
                                          ),
                                          onPressed: () async {
                                            await ZkFinger.registerFinger(
                                                userId: _registerationCodeController
                                                    .text);
                                          },
                                          icon: const Icon(Icons.fingerprint,
                                              size: 16),
                                          label: const Text('Enroll',
                                              style: TextStyle(fontSize: 12)),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.purple,
                                            foregroundColor: Colors.white,
                                          ),
                                          onPressed: () async {
                                            await ZkFinger.identify(
                                                userId: _registerationCodeController
                                                    .text);
                                          },
                                          icon: const Icon(Icons.search),
                                          label: const Text('Identify Finger'),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.teal,
                                            foregroundColor: Colors.white,
                                          ),
                                          onPressed: () async {
                                            await ZkFinger.verify(
                                                finger1: _idleText1.text,
                                                finger2: _idleText2.text);
                                          },
                                          icon: const Icon(Icons.verified),
                                          label: const Text('Verify Finger'),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      const Divider(),
                                      const SizedBox(height: 8),
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red,
                                            foregroundColor: Colors.white,
                                          ),
                                          onPressed: () async {
                                            await ZkFinger.clearFingerDatabase();
                                          },
                                          icon: const Icon(Icons.delete_forever),
                                          label: const Text('Clear Database'),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.grey,
                                            foregroundColor: Colors.white,
                                          ),
                                          onPressed: () async {
                                            await ZkFinger.stopListen();
                                          },
                                          icon: const Icon(Icons.stop),
                                          label: const Text('Stop Listening'),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red.shade700,
                                            foregroundColor: Colors.white,
                                          ),
                                          onPressed: () async {
                                            await ZkFinger.closeConnection();
                                          },
                                          icon: const Icon(Icons.power_off),
                                          label: const Text('Disconnect'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ))),
                      const SizedBox(width: 16),
                      // Fingerprint Display Section
                      SizedBox(
                          width: 180,
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Preview',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Center(
                                    child: fingerImages != null
                                        ? Container(
                                      decoration: BoxDecoration(
                                        borderRadius:
                                        BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                          width: 2,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black
                                                .withOpacity(0.1),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: ClipRRect(
                                        borderRadius:
                                        BorderRadius.circular(10),
                                        child: Image.memory(
                                          fingerImages!,
                                          width: 150,
                                          height: 150,
                                          fit: BoxFit.fill,
                                        ),
                                      ),
                                    )
                                        : Container(
                                      width: 150,
                                      height: 150,
                                      decoration: BoxDecoration(
                                        borderRadius:
                                        BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.grey.shade300,
                                          width: 2,
                                        ),
                                        color: Colors.grey.shade50,
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                        MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.fingerprint,
                                            size: 48,
                                            color: Colors.grey.shade400,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'No Image',
                                            style: TextStyle(
                                              color: Colors.grey.shade600,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  // Status Indicator
                                  Text(
                                    'Status Indicator',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Center(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                          width: 2,
                                        ),
                                        color: Colors.white,
                                      ),
                                      height: 148,
                                      width: 154,
                                      child: _getFingerStatusImage(),
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  // Status Information
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .surfaceVariant,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Status Information',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            const Icon(Icons.score, size: 16),
                                            const SizedBox(width: 4),
                                            Text('Score: $score'),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(Icons.message, size: 16),
                                            const SizedBox(width: 4),
                                            Expanded(
                                                child:
                                                Text('Message: $message')),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Device Status:',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleSmall
                                              ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          statusText,
                                          style: const TextStyle(
                                              fontSize: 12,
                                              fontFamily: 'monospace'),
                                        ),
                                      ],
                                    ),
                                  )
                                ],
                              ),
                            ),
                          )),
                      const SizedBox(width: 16),
                      // Data Management Section
                      SizedBox(
                        width: 250,
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: SingleChildScrollView(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    'Data Management',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _registerationCodeController,
                                    decoration: InputDecoration(
                                      labelText: "Registration Code",
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      prefixIcon: const Icon(Icons.person),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Biometric Base64 Template:',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    readOnly: true,
                                    controller: _biometricController,
                                    maxLines: 3,
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      prefixIcon: const Icon(Icons.data_object),
                                    ),
                                    style: const TextStyle(
                                        fontSize: 12, fontFamily: 'monospace'),
                                  )
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Verification Section
                      SizedBox(
                        width: 220,
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: SingleChildScrollView(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Verification',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary,
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  // Finger 1
                                  Text(
                                    'Template 1:',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    decoration: InputDecoration(
                                      labelText: "Fingerprint Template 1",
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      prefixIcon: const Icon(Icons.fingerprint),
                                    ),
                                    readOnly: true,
                                    controller: _idleText1,
                                    maxLines: 2,
                                    style: const TextStyle(
                                        fontSize: 12, fontFamily: 'monospace'),
                                  ),
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        _idleText1.text =
                                            _biometricController.text;
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Theme.of(context)
                                            .colorScheme
                                            .secondary,
                                        foregroundColor: Colors.white,
                                      ),
                                      icon: const Icon(Icons.copy),
                                      label: const Text('Copy Template'),
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  // Finger 2
                                  Text(
                                    'Template 2:',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    decoration: InputDecoration(
                                      labelText: "Fingerprint Template 2",
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      prefixIcon: const Icon(Icons.fingerprint),
                                    ),
                                    readOnly: true,
                                    controller: _idleText2,
                                    maxLines: 2,
                                    style: const TextStyle(
                                        fontSize: 12, fontFamily: 'monospace'),
                                  ),
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        _idleText2.text =
                                            _biometricController.text;
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Theme.of(context)
                                            .colorScheme
                                            .secondary,
                                        foregroundColor: Colors.white,
                                      ),
                                      icon: const Icon(Icons.copy),
                                      label: const Text('Copy Template'),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Database Management Section
                      SizedBox(
                        width: 280,
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: SingleChildScrollView(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Database Management',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary,
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  // Current Database Info
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .surfaceVariant,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(Icons.storage),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Current Database',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium
                                                  ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            const Icon(Icons.people, size: 16),
                                            const SizedBox(width: 4),
                                            Text('Users: ${_isLoadingDatabase ? "Loading..." : databaseUserCount}'),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton.icon(
                                            onPressed: _isLoadingDatabase ? null : () {
                                              _refreshDatabaseInfo();
                                              _showDatabaseUsersDialog();
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.blue,
                                              foregroundColor: Colors.white,
                                            ),
                                            icon: _isLoadingDatabase
                                                ? const SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(strokeWidth: 2),
                                            )
                                                : const Icon(Icons.list),
                                            label: const Text('View Users'),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  const Divider(),
                                  const SizedBox(height: 16),

                                  // Export Section
                                  Text(
                                    'Export to URL',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: _exportUrlController,
                                    decoration: InputDecoration(
                                      labelText: "Export URL (POST)",
                                      hintText: "https://api.example.com/export",
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      prefixIcon: const Icon(Icons.upload),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: _isExporting ? null : _exportAllUsers,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white,
                                      ),
                                      icon: _isExporting
                                          ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                          : const Icon(Icons.cloud_upload),
                                      label: Text(_isExporting ? 'Exporting...' : 'Export All Users'),
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  // Import Section
                                  Text(
                                    'Import from URL',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: _importUrlController,
                                    decoration: InputDecoration(
                                      labelText: "Import URL (GET)",
                                      hintText: "https://api.example.com/import",
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      prefixIcon: const Icon(Icons.download),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: _isLoadingFromUrl ? null : _importFromUrl,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.orange,
                                        foregroundColor: Colors.white,
                                      ),
                                      icon: _isLoadingFromUrl
                                          ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                          : const Icon(Icons.cloud_download),
                                      label: Text(_isLoadingFromUrl ? 'Importing...' : 'Import from URL'),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  const Divider(),
                                  const SizedBox(height: 8),

                                  // Legacy Network Section
                                  Text(
                                    'Legacy Network Operations',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.indigo,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: _sendUrlController,
                                    onChanged: (text) {
                                      sendUrl = text;
                                    },
                                    decoration: InputDecoration(
                                      hintText:
                                      "Enter URL (http:// or https://)",
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      prefixIcon: const Icon(Icons.link),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.indigo,
                                        foregroundColor: Colors.white,
                                      ),
                                      onPressed: () => sendText(),
                                      icon: const Icon(Icons.send),
                                      label: const Text('Send Data'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
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
            data: {"date": DateTime.now().toString(), "finger": base64Image});
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
            CustomToast.showToast('Server error: ${e.response!.data}');
            print('Server error: ${e.response!.data}');
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
        colorFilter: const ColorFilter.mode(Colors.black38, BlendMode.srcIn),
        width: 70,
        height: 120,
      );
    }
    Color svgColor = Colors.black12;
    switch (fingerStatus!.statusType) {
      case FingerStatusType.FINGER_EXTRACTED:
      case FingerStatusType.STARTED_ALREADY:
      case FingerStatusType.STARTED_SUCCESS:
        svgColor = Colors.indigo;
        break;
      case FingerStatusType.VERIFIED_SUCCESS:
        svgColor = Colors.green;
        break;
      case FingerStatusType.VERIFIED_FAILED:
        svgColor = Colors.redAccent;
        break;
      case FingerStatusType.VERIFIED_ERROR:
        svgColor = Colors.red;
        break;
      case FingerStatusType.IDENTIFIED_START_FIRST:
      case FingerStatusType.IDENTIFIED_FAILED:
        svgColor = Colors.redAccent;
        break;
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
        svgColor = Colors.redAccent;
        break;
      case FingerStatusType.STARTED_ERROR:
        svgColor = Colors.red;
        break;
      case FingerStatusType.ENROLL_FAILED:
        svgColor = Colors.redAccent;
        break;
      case FingerStatusType.STOPPED_ERROR:
        svgColor = Colors.red;
        break;
      case FingerStatusType.CAPTURE_ERROR:
        svgColor = Colors.red;
        break;
      default:
        svgColor = Colors.black38;
    }

    return SvgPicture.asset(
      'assets/finger.svg',
      colorFilter: ColorFilter.mode(svgColor, BlendMode.srcIn),
      width: 70,
      height: 120,
    );
  }
}
