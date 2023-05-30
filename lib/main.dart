import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:location/location.dart';
import 'package:sensors_plus/sensors_plus.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Ensure that there's at least one camera available
  final cameras = await availableCameras();
  if (cameras.isEmpty) {
    print('No cameras available');
    return;
  }
  runApp(MyApp(camera: cameras.first));
}

class MyApp extends StatefulWidget {
  final CameraDescription camera;

  const MyApp({Key? key, required this.camera}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  CameraController? _controller;
  LocationData? _locationData;
  List<double> _accelerometerValues = <double>[];
  List<double> _gyroscopeValues = <double>[];

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _initializeLocation();
    _startListeningToSensors();
  }

  Future<void> _initializeCamera() async {
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    try {
      await _controller!.initialize();
    } catch (e) {
      print('Error initializing camera: $e');
    }

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _initializeLocation() async {
    final location = Location();
    bool serviceEnabled;
    PermissionStatus permissionStatus;

    serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        print('Location service is disabled');
        return;
      }
    }

    permissionStatus = await location.hasPermission();
    if (permissionStatus == PermissionStatus.denied) {
      permissionStatus = await location.requestPermission();
      if (permissionStatus != PermissionStatus.granted) {
        print('Location permission denied');
        return;
      }
    }

    location.onLocationChanged.listen((LocationData result) {
      setState(() {
        _locationData = result;
      });
    });
  }

  void _startListeningToSensors() {
    accelerometerEvents.listen((AccelerometerEvent event) {
      setState(() {
        _accelerometerValues = <double>[event.x, event.y, event.z];
      });
    });

    gyroscopeEvents.listen((GyroscopeEvent event) {
      setState(() {
        _gyroscopeValues = <double>[event.x, event.y, event.z];
      });
    });
  }

  Future<void> _captureImage() async {
    if (_controller!.value.isInitialized) {
      final DateTime now = DateTime.now();
      final String formattedDateTime =
          '${now.year}-${now.month}-${now.day}_${now.hour}-${now.minute}-${now.second}';

      final path = '${Directory.systemTemp.path}/$formattedDateTime.png';

      try {
        await _controller!.takePicture();
      } catch (e) {
        print('Error capturing image: $e');
        return;
      }

      print('Image captured: $path');
      print('Date and Time: $formattedDateTime');
      print('Latitude: ${_locationData?.latitude}');
      print('Longitude: ${_locationData?.longitude}');
      print('Accelerometer Values: $_accelerometerValues');
      print('Gyroscope Values: $_gyroscopeValues');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_controller!.value.isInitialized) {
      return Container();
    }

    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Camera App'),
        ),
        body: Column(
          children: [
            Expanded(
              child: Center(
                child: CameraPreview(_controller!),
              ),
            ),
            ElevatedButton(
              onPressed: _captureImage,
              child: const Text('Capture Image'),
            ),
          ],
        ),
      ),
    );
  }
}
