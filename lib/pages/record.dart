import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';

enum RecordingState { idle, recording, paused }

class Recording extends StatefulWidget {
  const Recording({super.key});

  @override
  State<Recording> createState() => _RecordState();
}

class _RecordState extends State<Recording> {
  final Location location = Location();
  final MapController _mapController = MapController();

  LocationData? _locationData;
  StreamSubscription<LocationData>? _locationSubscription;
  RecordingState _recordingState = RecordingState.idle;

  List<LatLng> _recordedPath = [];
  final ImagePicker _picker = ImagePicker();
  File? _imageFile;

  final LatLng _defaultCenter = const LatLng(14.5995, 120.9842); // Manila
  final double currentZoom = 15;

  final _tileProvider = FMTCTileProvider(
    stores: const {'mapStore': BrowseStoreStrategy.readUpdateCreate},
    loadingStrategy: BrowseLoadingStrategy.cacheFirst,
  );

  @override
  void initState() {
    super.initState();
    // Show default map with no location updates.
    // Recording starts manually via button.
  }

  Future<void> _takePicture() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
      print("Picture taken: ${pickedFile.path}");
    }
  }

  void _stopLocationUpdates() {
    _locationSubscription?.cancel();
    _locationSubscription = null;
    setState(() {
      _recordingState = RecordingState.idle;
    });
    print("Recording stopped");
  }

  void _pauseRecording() {
    _locationSubscription?.pause();
    setState(() {
      _recordingState = RecordingState.paused;
    });
    print("Recording paused");
  }

  void _resumeRecording() {
    _locationSubscription?.resume();
    setState(() {
      _recordingState = RecordingState.recording;
    });
    print("Recording resumed");
  }

  Future<void> _initLocation() async {
    bool serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) return;
    }

    PermissionStatus permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) return;
    }

    setState(() {
      _recordingState = RecordingState.recording;
      _recordedPath.clear();
    });

    location.changeSettings(interval: 7500);
    _locationData = await location.getLocation();

    _locationSubscription = location.onLocationChanged.listen((LocationData newLocation) {
      final newLatLng = LatLng(newLocation.latitude!, newLocation.longitude!);
      setState(() {
        _locationData = newLocation;
        _recordedPath.add(newLatLng);
      });

      final currentZoom = _mapController.camera.zoom;
      _mapController.move(newLatLng, currentZoom);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar(),
      body: Stack(
        children: [
          content(),
          if (_recordingState == RecordingState.recording || _recordingState == RecordingState.paused)
            Positioned(
              bottom: 90,
              right: 20,
              child: FloatingActionButton(
                onPressed: _takePicture,
                tooltip: 'Take Photo',
                child: const Icon(Icons.camera_alt),
              ),
            ),
        ],
      ),
      bottomNavigationBar: bottomAppBar(),
    );
  }

  AppBar appBar() {
    return AppBar(
      title: const Text("Map"),
      backgroundColor: Colors.blueAccent,
      foregroundColor: Colors.white,
      centerTitle: true,
    );
  }

  Widget content() {
    final LatLng center = _locationData != null
        ? LatLng(_locationData!.latitude!, _locationData!.longitude!)
        : _defaultCenter;

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: center,
        initialZoom: currentZoom,
        keepAlive: true,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.mapproject',
          tileProvider: _tileProvider,
        ),
        if (_recordedPath.isNotEmpty)
          PolylineLayer(
            polylines: [
              Polyline(
                points: _recordedPath,
                strokeWidth: 4.0,
                color: Colors.blueAccent,
              ),
            ],
          ),
        if (_locationData != null)
          MarkerLayer(
            markers: [
              Marker(
                point: LatLng(_locationData!.latitude!, _locationData!.longitude!),
                width: 20,
                height: 20,
                child: Image.asset('assets/icons/Group 77.png'),
              ),
            ],
          ),
      ],
    );
  }

  BottomAppBar bottomAppBar() {
    return BottomAppBar(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: _buildButtonsBasedOnState(),
      ),
    );
  }

  List<Widget> _buildButtonsBasedOnState() {
    switch (_recordingState) {
      case RecordingState.idle:
        return [
          ElevatedButton(
            onPressed: _initLocation,
            child: const Text("Start Recording"),
          ),
        ];
      case RecordingState.recording:
        return [
          ElevatedButton(
            onPressed: _pauseRecording,
            child: const Text("Pause"),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: _stopLocationUpdates,
            child: const Text("Finish"),
          ),
        ];
      case RecordingState.paused:
        return [
          ElevatedButton(
            onPressed: _resumeRecording,
            child: const Text("Resume"),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: _stopLocationUpdates,
            child: const Text("Finish"),
          ),
        ];
    }
  }
}
