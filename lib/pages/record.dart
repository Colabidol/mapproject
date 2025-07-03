import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'dart:async';

enum RecordingState { idle, recording, paused }

class Recording extends StatefulWidget {
  const Recording({super.key});

  @override
  State<Recording> createState() => _RecordState();
}

class _RecordState extends State<Recording> {
  final Location location = Location();
  final MapController _mapController = MapController();
  final double currentZoom = 15;

  LocationData? _locationData;
  StreamSubscription<LocationData>? _locationSubscription;
  RecordingState _recordingState = RecordingState.idle;

  List<LatLng> _recordedPath = []; // 👈 New: Stores the path

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
      _recordedPath.clear(); // 👈 Clear previous path
    });

    location.changeSettings(interval: 7500);

    _locationData = await location.getLocation();

    _locationSubscription = location.onLocationChanged.listen((LocationData newLocation) {
      final newLatLng = LatLng(newLocation.latitude!, newLocation.longitude!);

      setState(() {
        _locationData = newLocation;
        _recordedPath.add(newLatLng); // 👈 Add point to path
      });

      final currentZoom = _mapController.camera.zoom;
      _mapController.move(newLatLng, currentZoom);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar(),
      body: content(),
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
  if (_locationData == null ||
      _locationData!.latitude == null ||
      _locationData!.longitude == null) {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: LatLng(14.5995, 120.9842),
        initialZoom: 12,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'dev.fleaflet.flutter_map.example',
        ),
      ],
    );
  }

  final double latitude = _locationData!.latitude!;
  final double longitude = _locationData!.longitude!;
  final LatLng currentLocation = LatLng(latitude, longitude);

  return FlutterMap(
    mapController: _mapController,
    options: MapOptions(
      initialCenter: currentLocation,
    ),
    children: [
      TileLayer(
        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
        userAgentPackageName: 'dev.fleaflet.flutter_map.example',
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
      MarkerLayer(
        markers: [
          Marker(
            point: currentLocation,
            width: 20,
            height: 20,
            child: Image.asset(
              'assets/icons/Group 77.png',
            ),
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
