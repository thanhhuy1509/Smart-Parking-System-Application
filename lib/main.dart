import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:flutter/foundation.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: 'AIzaSyDVb-BLDzVu3zx9oPSj2Znlnqg5wzSAOcA',
      appId: '1:325235418530:android:f1e9670d30d3806c077efb',
      messagingSenderId: '325235418530',
      projectId: 'smart-car-parking-system-1c0d8',
      databaseURL:
          'https://smart-car-parking-system-1c0d8-default-rtdb.firebaseio.com',
      storageBucket: 'smart-car-parking-system-1c0d8.appspot.com',
    ),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Car Parking',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Smart Car Parking App'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool slot1 = false;
  bool slot2 = false;
  late DatabaseReference _slot1Ref;
  late DatabaseReference _slot2Ref;
  late StreamSubscription<DatabaseEvent> _slot1Subscription;
  late StreamSubscription<DatabaseEvent> _slot2Subscription;
  var slot1Image = 'assets/images/red.jpg';
  var slot2Image = 'assets/images/red.jpg';
  FirebaseException? _error;
  Barcode? result;
  QRViewController? controller;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');

  @override
  void initState() {
    init();
    super.initState();
  }

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller!.pauseCamera();
    }
    controller!.resumeCamera();
  }

  Future<void> init() async {
    _slot1Ref = FirebaseDatabase.instance.ref('Slot 1');
    _slot2Ref = FirebaseDatabase.instance.ref('Slot 2');

    final database = FirebaseDatabase.instance;

    if (!kIsWeb) {
      database.setPersistenceEnabled(true);
      database.setPersistenceCacheSizeBytes(10000000);
    }

    if (!kIsWeb) {
      await _slot1Ref.keepSynced(true);
      await _slot2Ref.keepSynced(true);
    }

    try {
      final slot1Snapshot = await _slot1Ref.get();
      final slot2Snapshot = await _slot2Ref.get();
    } catch (err) {
      print(err);
    }

    _slot1Subscription = _slot1Ref.onValue.listen((DatabaseEvent event) {
      setState(() {
        _error = null;
        slot1 = (event.snapshot.value ?? 0) as bool;
      });
    }, onError: (Object o) {
      final error = o as FirebaseException;
      setState(() {
        _error = error;
      });
    });

    _slot2Subscription = _slot2Ref.onValue.listen((DatabaseEvent event) {
      setState(() {
        _error = null;
        slot2 = (event.snapshot.value ?? 0) as bool;
      });
    }, onError: (Object o) {
      final error = o as FirebaseException;
      setState(() {
        _error = error;
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
    _slot1Subscription.cancel();
    _slot2Subscription.cancel();
    controller?.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Flexible(
                      child: slot1 == false
                          ? Image.asset(
                              'assets/images/green.jpg',
                              fit: BoxFit.cover,
                              height: 100,
                              width: 100,
                            )
                          : Image.asset(
                              'assets/images/red.jpg',
                              fit: BoxFit.cover,
                              height: 100,
                              width: 100,
                            )),
                  Flexible(
                      child: slot2 == false
                          ? Image.asset(
                              'assets/images/green.jpg',
                              fit: BoxFit.cover,
                              height: 100,
                              width: 100,
                            )
                          : Image.asset(
                              'assets/images/red.jpg',
                              fit: BoxFit.cover,
                              height: 100,
                              width: 100,
                            ))
                ],
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Expanded(flex: 4, child: _buildQrView(context)),
                  Expanded(
                    flex: 1,
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: <Widget>[
                          if (result != null)
                            Text(
                                'Barcode Type: ${describeEnum(result!.format)}   Data: ${result!.code}')
                          else
                            const Text('Scan a code'),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: <Widget>[
                              Container(
                                width: 100,
                                height: 100,
                                margin: const EdgeInsets.all(8),
                                child: ElevatedButton(
                                    onPressed: () async {
                                      await controller?.toggleFlash();
                                      setState(() {});
                                    },
                                    child: FutureBuilder(
                                      future: controller?.getFlashStatus(),
                                      builder: (context, snapshot) {
                                        return Text('Flash: ${snapshot.data}');
                                      },
                                    )),
                              ),
                              Container(
                                width: 100,
                                height: 100,
                                margin: const EdgeInsets.all(8),
                                child: ElevatedButton(
                                    onPressed: () async {
                                      await controller?.flipCamera();
                                      setState(() {});
                                    },
                                    child: FutureBuilder(
                                      future: controller?.getCameraInfo(),
                                      builder: (context, snapshot) {
                                        if (snapshot.data != null) {
                                          return Text(
                                              'Camera facing ${describeEnum(snapshot.data!)}');
                                        } else {
                                          return const Text('loading');
                                        }
                                      },
                                    )),
                              )
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: <Widget>[
                              Container(
                                width: 100,
                                height: 100,
                                margin: const EdgeInsets.all(8),
                                child: ElevatedButton(
                                  onPressed: () async {
                                    await controller?.pauseCamera();
                                  },
                                  child: const Text('pause',
                                      style: TextStyle(fontSize: 20)),
                                ),
                              ),
                              Container(
                                width: 100,
                                height: 100,
                                margin: const EdgeInsets.all(8),
                                child: ElevatedButton(
                                  onPressed: () async {
                                    await controller?.resumeCamera();
                                  },
                                  child: const Text('resume',
                                      style: TextStyle(fontSize: 20)),
                                ),
                              )
                            ],
                          ),
                        ],
                      ),
                    ),
                  )
                ],
              )
            ],
          ),
        ) // This trailing comma makes auto-formatting nicer for build methods.
        );
  }

  Widget _buildQrView(BuildContext context) {
    // For this example we check how width or tall the device is and change the scanArea and overlay accordingly.
    var scanArea = (MediaQuery.of(context).size.width < 400 ||
            MediaQuery.of(context).size.height < 400)
        ? 150.0
        : 300.0;
    // To ensure the Scanner view is properly sizes after rotation
    // we need to listen for Flutter SizeChanged notification and update controller
    return QRView(
      key: qrKey,
      onQRViewCreated: _onQRViewCreated,
      overlay: QrScannerOverlayShape(
          borderColor: Colors.red,
          borderRadius: 10,
          borderLength: 30,
          borderWidth: 10,
          cutOutSize: scanArea),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    setState(() {
      this.controller = controller;
    });
    controller.scannedDataStream.listen((scanData) {
      setState(() {
        result = scanData;
        FirebaseDatabase.instance.ref('Check_in').set(result.toString());
      });
    });
  }
}
