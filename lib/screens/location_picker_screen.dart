import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class LocationPickerScreen extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;

  const LocationPickerScreen({super.key, this.initialLat, this.initialLng});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  GoogleMapController? _mapController;
  LatLng _currentLocation = const LatLng(-16.5000, -68.1500); // Default La Paz
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    if (widget.initialLat != null && widget.initialLng != null && widget.initialLat != 0) {
      _currentLocation = LatLng(widget.initialLat!, widget.initialLng!);
      setState(() => _isLoading = false);
    } else {
      await _determinePosition();
    }
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
          _isLoading = false;
        });
        _mapController?.animateCamera(CameraUpdate.newLatLng(_currentLocation));
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Elegir Ubicación'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () => Navigator.pop(context, _currentLocation),
          )
        ],
      ),
      body: Stack(
        children: [
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _currentLocation,
                zoom: 15,
              ),
              onMapCreated: (controller) => _mapController = controller,
              onCameraMove: (position) {
                _currentLocation = position.target;
              },
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
            ),
          const Center(
            child: Icon(Icons.location_on, size: 48, color: Colors.red),
          ),
          Positioned(
            bottom: 24,
            left: 24,
            right: 80,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  'Mueve el mapa para ubicar el pin en tu sucursal',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.check),
        onPressed: () => Navigator.pop(context, _currentLocation),
      ),
    );
  }
}
