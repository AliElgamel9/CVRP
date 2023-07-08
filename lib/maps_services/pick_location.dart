import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../utils/global_views.dart';

class PickLocation extends StatefulWidget {
  final LatLng? initialLocation;

  PickLocation({this.initialLocation});

  @override
  _PickLocationState createState() => _PickLocationState(initialLocation);
}

class _PickLocationState extends State<PickLocation> {
  LatLng? selectedLocation;

  _PickLocationState(this.selectedLocation);

  @override
  void initState() {
    super.initState();
    if (selectedLocation == null) _getUserLocation();
  }

  @override
  Widget build(BuildContext context) {
    if (selectedLocation == null) return loadingScreen();
    return Scaffold(
      appBar: AppBar(
        title: Text('Pick Location'),
      ),
      body: GoogleMap(
        onTap: (position) => setState(() => selectedLocation = position),
        initialCameraPosition: CameraPosition(
          target: selectedLocation!,
          zoom: 12.0,
        ),
        markers: {
          Marker(
            markerId: MarkerId('selected_location'),
            position: selectedLocation!,
          )
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pop(
              context,
              LatLng(
                selectedLocation!.latitude,
                selectedLocation!.longitude,
              ));
        },
        child: Icon(Icons.check),
      ),
    );
  }


  Future<void> _getUserLocation() async {
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    setState(() {
      selectedLocation = LatLng(position.latitude, position.longitude);
    });
  }
}
