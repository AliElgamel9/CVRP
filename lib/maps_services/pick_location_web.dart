import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:syncfusion_flutter_maps/maps.dart';

import '../utils/global_views.dart';

class PickLocationWeb extends StatefulWidget {
  final LatLng? initialLocation;

  PickLocationWeb({this.initialLocation});

  @override
  _PickLocationStateWeb createState() {
    if (initialLocation == null) return _PickLocationStateWeb(null);
    return _PickLocationStateWeb(
        MapLatLng(initialLocation!.latitude, initialLocation!.longitude));
  }
}

class _PickLocationStateWeb extends State {
  MapLatLng? selectedLocation;
  late MapTileLayerController _controller;
  var pinIcon = BitmapDescriptor.defaultMarker;

  _PickLocationStateWeb(this.selectedLocation);

  @override
  void initState() {
    super.initState();
    _controller = MapTileLayerController();
    if (selectedLocation == null) _getUserLocation();
  }

  @override
  Widget build(BuildContext context) {
    if (selectedLocation == null) return loadingScreen();
    return Scaffold(
      appBar: AppBar(
        title: Text('Pick Location'),
      ),
      body: FutureBuilder(
          future: getBingUrlTemplate(
              'http://dev.virtualearth.net/REST/V1/Imagery/Metadata/RoadOnDemand?output=json&include=ImageryProviders&key=Ahgy2ECRAum11hzsnfaSr28NcoZi-9Oz1ArAKmwAbpC9SfaTkz0mq57ZYek5Ssyk'),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return GestureDetector(
                  onTapUp: (details) =>
                      _updateMarkerChange(details.localPosition),
                  child: SfMaps(
                    layers: [
                      MapTileLayer(
                        urlTemplate: snapshot.data.toString(),
                        controller: _controller,
                        initialFocalLatLng: MapLatLng(
                          selectedLocation!.latitude,
                          selectedLocation!.longitude,
                        ),
                        initialMarkersCount: 1,
                        markerBuilder: (context, index) {
                          return MapMarker(
                            latitude: selectedLocation!.latitude,
                            longitude: selectedLocation!.longitude,
                            offset: Offset(0, -25),
                            child: Image.asset(
                              'assets/images/destination_pin.png',
                              height: 50,
                              width: 50,),
                          );
                        },
                        initialZoomLevel: 15,
                        zoomPanBehavior: MapZoomPanBehavior(),
                      ),
                    ],
                  ));
            }
            return loadingScreen();
          }),
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

  void _updateMarkerChange(Offset position) {
    selectedLocation = _controller.pixelToLatLng(position);
    _controller.updateMarkers([0]);
  }

  Future<void> _getUserLocation() async {
    Position position = await Geolocator.getCurrentPosition();
    setState(() {
      selectedLocation = MapLatLng(position.latitude, position.longitude);
    });
  }
}
