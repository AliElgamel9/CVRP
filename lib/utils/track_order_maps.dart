import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_login_architecture/utils/global_views.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:rxdart/rxdart.dart';
import 'package:syncfusion_flutter_maps/maps.dart';
import 'package:url_launcher/url_launcher.dart';

abstract class OrderTracking extends StatefulWidget {
  final String? driverPhoneNumber;
  final ValueStream<LatLng> customerLocationStream;
  final ValueStream<LatLng?> driverLocationStream;

  OrderTracking({
    required this.driverPhoneNumber,
    required this.customerLocationStream,
    required this.driverLocationStream,
  });
}

abstract class _OrderTrackingState extends State<OrderTracking> {
  final String? driverPhoneNumber;

  StreamSubscription<LatLng>? customerLocationSubscription = null;
  StreamSubscription<LatLng?>? driverLocationSubscription = null;

  LatLng? customerLocation;
  LatLng? driverLocation;

  var isTracking = false;

  var isDriverLocationExist = false;
  var isDriverConnectionLost = false;
  Timer? timer;

  _OrderTrackingState(
      this.driverPhoneNumber,
      ValueStream<LatLng?> driverLocationStream,
      ValueStream<LatLng> customerLocationStream) {
    // customer update location
    customerLocationSubscription = customerLocationStream.listen((latlng) {
      updateCustomerLocation(latlng);
    });
    // driver update location
    driverLocationSubscription = driverLocationStream.listen((latlng) {
      if (latlng == null) {
        setState(() => isDriverLocationExist = false);
        return;
      }
      if(!isDriverLocationExist)
        updateCameraBounds();
      updateDriverLocation(latlng);
      setState(() => isDriverLocationExist = true);
    });
  }

  @override
  void dispose() {
    super.dispose();
    driverLocationSubscription?.cancel();
    customerLocationSubscription?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    if (customerLocation == null) return loadingScreen();
    return _main();
  }

  Widget _main() {
    return Stack(
      children: [
        mapWidget(),
        if (isDriverLocationExist)
          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 8.0, horizontal: 58.0),
              child: FloatingActionButton(
                onPressed: () => onTrackingButtonClick(),
                child: Image.asset(
                  'assets/images/gps.png',
                  width: 32.0,
                  height: 32.0,
                  color: Colors.white,
                ),
                backgroundColor: isTracking ? Colors.blue : Colors.blueGrey,
              ),
            ),
          ),
        _driverStatusWidget(),
      ],
    );
  }

  Widget mapWidget();

  Widget _driverStatusWidget() {
    if (driverLocation == null && isDriverLocationExist)
      return _messageOnMap('no driver assigned yet');
    if (!isDriverLocationExist)
      return _messageOnMap('the driver is not started the trip yet');
    if (isDriverConnectionLost)
      return Center(
        child: InkWell(
          onTap: _makePhoneCall,
          child: Container(
            padding: EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8.0),
              color: Colors.blue,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.phone,
                  color: Colors.white,
                ),
                SizedBox(width: 8.0),
                Text(
                  "driver connection lost, click to call driver",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    return Container();
  }

  Widget _messageOnMap(String message) {
    return Center(
      child: Card(
        color: Color.fromRGBO(128, 128, 128, 0.5),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            message,
            style: TextStyle(fontSize: 18.0, color: Colors.white),
          ),
        ),
      ),
    );
  }

  updateCustomerLocation(LatLng latLng) {
    setState(() => customerLocation = latLng);
  }

  updateDriverLocation(LatLng latLng) {
    setState(() => driverLocation = latLng);
  }

  void updateCameraBounds();

  onTrackingButtonClick() {
    setState(() => isTracking = !isTracking);
  }

  _makePhoneCall() async {
    final uri = Uri.parse('tel:$driverPhoneNumber');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }
}

class OrderTrackingGoogleMaps extends OrderTracking {
  OrderTrackingGoogleMaps({
    required super.driverPhoneNumber,
    required super.customerLocationStream,
    required super.driverLocationStream,
  });

  @override
  State<StatefulWidget> createState() => _OrderTrackingGoogleMapsState(
        driverPhoneNumber,
        driverLocationStream,
        customerLocationStream,
      );
}

class _OrderTrackingGoogleMapsState extends _OrderTrackingState {
  GoogleMapController? _controller;

  Marker? driverPin, destinationPin;
  var carPinIcon = BitmapDescriptor.defaultMarker;
  var destinationPinIcon = BitmapDescriptor.defaultMarker;
  CameraTargetBounds bounds = CameraTargetBounds(null);

  _OrderTrackingGoogleMapsState(
      String? driverPhoneNumber,
      ValueStream<LatLng?> driverLocationStream,
      ValueStream<LatLng> customerLocationStream)
      : super(driverPhoneNumber, driverLocationStream, customerLocationStream);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    getDriverMarkerIcon();
    getDestinationMarkerIcon();
  }

  @override
  Widget mapWidget() {
    return GoogleMap(
      onMapCreated: _onMapCreated,
      markers: getMarkers(),
      initialCameraPosition: CameraPosition(
        target: driverLocation ?? customerLocation!,
        zoom: 14.0,
      ),
      cameraTargetBounds: bounds,
    );
  }

  @override
  updateCustomerLocation(LatLng latLng) {
    super.updateCustomerLocation(latLng);
    _setDestinationPin();
  }

  @override
  updateDriverLocation(LatLng latLng) {
    super.updateDriverLocation(latLng);
    _updateDriverPin();
    if (isTracking)
      _controller?.animateCamera(CameraUpdate.newLatLng(driverLocation!));
  }

  Set<Marker> getMarkers() {
    var markers = Set<Marker>();
    if (driverPin != null) markers.add(driverPin!);
    if (destinationPin != null) markers.add(destinationPin!);
    return markers;
  }

  _updateDriverPin() {
    if (driverLocation == null) return;
    setState(() {
      driverPin = Marker(
        markerId: MarkerId("driver"),
        position: driverLocation!,
        rotation: 0.0,
        draggable: false,
        zIndex: 2,
        flat: true,
        anchor: Offset(0.5, 0.5),
        icon: carPinIcon,
      );
    });
  }

  _setDestinationPin() {
    setState(() {
      destinationPin = Marker(
        markerId: MarkerId("destination"),
        position: customerLocation!,
        rotation: 0.0,
        draggable: false,
        zIndex: 2,
        flat: true,
        anchor: Offset(0.5, 0.5),
        icon: destinationPinIcon,
      );
    });
  }

  getDriverMarkerIcon() async {
    final ImageConfiguration imageConfiguration =
        createLocalImageConfiguration(context);
    final BitmapDescriptor icon = await BitmapDescriptor.fromAssetImage(
      imageConfiguration,
      'assets/images/car_pin.png',
    );
    carPinIcon = icon;
    _updateDriverPin();
  }

  getDestinationMarkerIcon() async {
    final ImageConfiguration imageConfiguration =
        createLocalImageConfiguration(context);
    final BitmapDescriptor icon = await BitmapDescriptor.fromAssetImage(
      imageConfiguration,
      'assets/images/destination_pin.png',
    );
    destinationPinIcon = icon;
    _setDestinationPin();
  }

  _onMapCreated(GoogleMapController controller) async {
    _controller = controller;
    _setTargetBounds();
  }

  _setTargetBounds() {
    Timer(const Duration(milliseconds: 500), () => updateCameraBounds());
  }

  @override
  void updateCameraBounds(){
    var bounds = _getBounds();
    if(bounds != null)
      _controller?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 30));
  }

  LatLngBounds? _getBounds() {
    if (driverLocation == null || customerLocation == null) return null;
    var swLatitude = min(driverLocation!.latitude, customerLocation!.latitude);
    var swLongitude =
        min(driverLocation!.longitude, customerLocation!.longitude);
    var neLatitude = max(driverLocation!.latitude, customerLocation!.latitude);
    var neLongitude =
        max(driverLocation!.longitude, customerLocation!.longitude);
    var southwest = LatLng(swLatitude, swLongitude);
    var northeast = LatLng(neLatitude, neLongitude);
    var bounds = LatLngBounds(southwest: southwest, northeast: northeast);
    return bounds;
  }

  @override
  onTrackingButtonClick() {
    super.onTrackingButtonClick();
    if (isTracking)
      _controller
          ?.moveCamera(CameraUpdate.newLatLngZoom(driverLocation!, 14.0));
  }
}

class OrderTrackingBingMaps extends OrderTracking {
  OrderTrackingBingMaps({
    required super.driverPhoneNumber,
    required super.customerLocationStream,
    required super.driverLocationStream,
  });

  @override
  State<StatefulWidget> createState() => _OrderTrackingBingMapsState(
        driverPhoneNumber,
        driverLocationStream,
        customerLocationStream,
      );
}

class _OrderTrackingBingMapsState extends _OrderTrackingState {
  late MapTileLayerController _controller;
  late MapZoomPanBehavior _mapZoomPanBehaviour;

  _OrderTrackingBingMapsState(
      String? driverPhoneNumber,
      ValueStream<LatLng?> driverLocationStream,
      ValueStream<LatLng> customerLocationStream)
      : super(driverPhoneNumber, driverLocationStream, customerLocationStream) {
    _controller = MapTileLayerController();
    _mapZoomPanBehaviour = MapZoomPanBehavior();
  }

  @override
  Widget mapWidget() {
    return FutureBuilder(
      future: getBingUrlTemplate(
          'http://dev.virtualearth.net/REST/V1/Imagery/Metadata/RoadOnDemand?output=json&include=ImageryProviders&key=Ahgy2ECRAum11hzsnfaSr28NcoZi-9Oz1ArAKmwAbpC9SfaTkz0mq57ZYek5Ssyk'),
      builder: (context, snapshot) {
        if (snapshot.hasData)
          return SfMaps(
            layers: [
              MapTileLayer(
                urlTemplate: snapshot.data.toString(),
                controller: _controller,
                initialFocalLatLng: _latlngToMapLatlng(driverLocation) ??
                    _latlngToMapLatlng(customerLocation)!,
                initialMarkersCount: 2,
                markerBuilder: (context, index) {
                  if (index == 0) return getDriverBingMarker();
                  return getDestinationBingMarker();
                },
                initialZoomLevel: 14,
                initialLatLngBounds: _getBounds(),
                zoomPanBehavior: _mapZoomPanBehaviour,
              ),
            ],
          );
        return loadingScreen();
      },
    );
  }

  @override
  updateCustomerLocation(LatLng latLng) {
    super.updateCustomerLocation(latLng);
    _controller.updateMarkers([1]);
  }

  @override
  updateDriverLocation(LatLng latLng) {
    super.updateDriverLocation(latLng);
    _controller.updateMarkers([0]);
    if (isTracking)
      _mapZoomPanBehaviour.focalLatLng = _latlngToMapLatlng(latLng)!;
  }

  getDriverBingMarker() {
    return MapMarker(
      latitude: driverLocation?.latitude??0,
      longitude: driverLocation?.longitude??0,
      offset: Offset(0, -25),
      child: Image.asset(
        'assets/images/car_pin.png',
        height: 50,
        width: 50,
      ),
    );
  }

  getDestinationBingMarker() {
    return MapMarker(
      latitude: customerLocation!.latitude,
      longitude: customerLocation!.longitude,
      offset: Offset(0, -25),
      child: Image.asset(
        'assets/images/destination_pin.png',
        height: 50,
        width: 50,
      ),
    );
  }

  @override
  void updateCameraBounds(){
    Timer(const Duration(milliseconds: 500), () => _setTargetBounds());
  }

  void _setTargetBounds(){
    var bounds = _getBounds();
    if (bounds != null) _mapZoomPanBehaviour.latLngBounds = bounds;
  }

  MapLatLngBounds? _getBounds() {
    if (driverLocation == null) return null;
    var swLatitude = min(driverLocation!.latitude, customerLocation!.latitude);
    var swLongitude = min(driverLocation!.longitude, customerLocation!.longitude);
    var neLatitude = max(driverLocation!.latitude, customerLocation!.latitude);
    var neLongitude = max(driverLocation!.longitude, customerLocation!.longitude);
    var southwest = MapLatLng(swLatitude-.1, swLongitude-.1);
    var northeast = MapLatLng(neLatitude+.1, neLongitude+.1);
    var bounds = MapLatLngBounds(northeast, southwest);
    return bounds;
  }

  @override
  onTrackingButtonClick() {
    super.onTrackingButtonClick();
    if (isTracking)
      _mapZoomPanBehaviour.focalLatLng = _latlngToMapLatlng(driverLocation)!;
  }

  MapLatLng? _latlngToMapLatlng(LatLng? latLng) {
    if (latLng == null) return null;
    return MapLatLng(latLng.latitude, latLng.longitude);
  }
}
