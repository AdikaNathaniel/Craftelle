import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class SelectedLocation {
  final double latitude;
  final double longitude;
  final String address;
  final String city;
  final String region;

  SelectedLocation({
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.city,
    required this.region,
  });
}

class LocationPickerPage extends StatefulWidget {
  final LatLng? initialPosition;
  final String title;

  const LocationPickerPage({
    Key? key,
    this.initialPosition,
    this.title = 'Select Location',
  }) : super(key: key);

  @override
  State<LocationPickerPage> createState() => _LocationPickerPageState();
}

class _LocationPickerPageState extends State<LocationPickerPage> {
  static const _pink = Color(0xFFFDA4AF);
  static const _pinkDark = Color(0xFFFB7185);

  // Default: Accra, Ghana
  static const _defaultPosition = LatLng(5.6037, -0.1870);

  GoogleMapController? _mapController;
  LatLng _selectedPosition = _defaultPosition;
  String _currentAddress = '';
  String _currentCity = '';
  String _currentRegion = '';
  bool _isLoading = true;
  bool _isGeocoding = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialPosition != null) {
      _selectedPosition = widget.initialPosition!;
      _isLoading = false;
      _reverseGeocode();
    } else {
      _determinePosition();
    }
  }

  Future<void> _determinePosition() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _isLoading = false);
          _reverseGeocode();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() => _isLoading = false);
        _reverseGeocode();
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _selectedPosition = LatLng(position.latitude, position.longitude);
        _isLoading = false;
      });

      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_selectedPosition, 16),
      );

      _reverseGeocode();
    } catch (e) {
      debugPrint('Error getting location: $e');
      setState(() => _isLoading = false);
      _reverseGeocode();
    }
  }

  Future<void> _reverseGeocode() async {
    setState(() => _isGeocoding = true);
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        _selectedPosition.latitude,
        _selectedPosition.longitude,
      );
      if (placemarks.isNotEmpty && mounted) {
        final place = placemarks.first;
        setState(() {
          _currentCity =
              place.locality ?? place.subAdministrativeArea ?? '';
          _currentRegion = place.administrativeArea ?? '';
          _currentAddress = [
            place.street,
            place.subLocality,
            place.locality,
            place.administrativeArea,
          ].where((s) => s != null && s.isNotEmpty).join(', ');
        });
      }
    } catch (e) {
      debugPrint('Reverse geocoding error: $e');
      if (mounted) {
        setState(() {
          _currentAddress =
              '${_selectedPosition.latitude.toStringAsFixed(5)}, ${_selectedPosition.longitude.toStringAsFixed(5)}';
        });
      }
    } finally {
      if (mounted) setState(() => _isGeocoding = false);
    }
  }

  void _goToCurrentLocation() async {
    setState(() => _isLoading = true);
    await _determinePosition();
  }

  void _confirmLocation() {
    if (_currentAddress.isEmpty) return;
    Navigator.pop(
      context,
      SelectedLocation(
        latitude: _selectedPosition.latitude,
        longitude: _selectedPosition.longitude,
        address: _currentAddress,
        city: _currentCity,
        region: _currentRegion,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        centerTitle: true,
        backgroundColor: _pink,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Google Map
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _selectedPosition,
              zoom: 15,
            ),
            onMapCreated: (controller) {
              _mapController = controller;
              if (!_isLoading) {
                controller.animateCamera(
                  CameraUpdate.newLatLngZoom(_selectedPosition, 16),
                );
              }
            },
            onCameraMove: (position) {
              _selectedPosition = position.target;
            },
            onCameraIdle: () {
              _reverseGeocode();
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
          ),

          // Center pin
          const Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: 36),
              child: Icon(
                Icons.location_pin,
                size: 48,
                color: Color(0xFFFB7185),
              ),
            ),
          ),

          // Pin shadow
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12),
              width: 8,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),

          // Loading overlay
          if (_isLoading)
            Container(
              color: Colors.white54,
              child: const Center(
                child: CircularProgressIndicator(color: _pinkDark),
              ),
            ),

          // My Location FAB
          Positioned(
            right: 16,
            bottom: 200,
            child: FloatingActionButton.small(
              heroTag: 'myLocation',
              backgroundColor: Colors.white,
              onPressed: _goToCurrentLocation,
              child: const Icon(Icons.my_location, color: _pinkDark),
            ),
          ),

          // Bottom address card
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _pink.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.location_on,
                            color: _pinkDark, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Selected Location',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            _isGeocoding
                                ? Row(
                                    children: [
                                      SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: _pinkDark,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Finding address...',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey[500],
                                        ),
                                      ),
                                    ],
                                  )
                                : Text(
                                    _currentAddress.isNotEmpty
                                        ? _currentAddress
                                        : 'Move the map to select a location',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1F2937),
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _currentAddress.isNotEmpty && !_isGeocoding
                          ? _confirmLocation
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _pinkDark,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey[300],
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Confirm Location',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
