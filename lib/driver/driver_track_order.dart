import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:rxdart/rxdart.dart';
import 'package:url_launcher/url_launcher.dart';

import '../firebase_backend/driver_service.dart';
import '../model.dart';
import '../utils/global_views.dart';
import '../utils/google_maps_in_app.dart';
import '../utils/track_order_maps.dart';

class DriverOrderTracking extends StatefulWidget {
  final DriverFirebaseService driverFirebaseService;

  DriverOrderTracking(this.driverFirebaseService);

  @override
  _DriverOrderTracking createState() =>
      _DriverOrderTracking(driverFirebaseService);
}

class _DriverOrderTracking extends State {
  final DriverFirebaseService driverFirebaseService;
  final _customerLocationSubject = BehaviorSubject<LatLng>();
  final _driverLocationSubject = BehaviorSubject<LatLng?>();

  Customer? customer;
  ServiceModel? order;
  StreamSubscription<Customer?>? customerSubscription;
  StreamSubscription<ServiceModel?>? orderSubscription;
  StreamSubscription<Position>? positionSubscription;

  _DriverOrderTracking(this.driverFirebaseService);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    customerSubscription =
        driverFirebaseService.getCustomerModelStream().listen((event) {
      setState(() => customer = event);
      if (event == null) return;
      _customerLocationSubject.add(LatLng(event.latitude, event.longitude));
    });

    orderSubscription =
        driverFirebaseService.getOrderModelStream().listen((event) {
      setState(() => order = event);
    });

    _observeDriverLocation();
  }

  @override
  void dispose() {
    customerSubscription?.cancel();
    positionSubscription?.cancel();
    orderSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var currentCustomer = customer;
    var currentOrder = order;
    if (currentCustomer == null || currentOrder == null) return loadingScreen();

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.onPrimary,
      appBar: AppBar(
        title: Text('Order Tracking'),
      ),
      body: _body(
        currentCustomer,
        currentOrder,
      ),
    );
  }

  Widget _body(Customer customer, ServiceModel order) {
    if (customer.id == 0) return noOrderWidget();
    if (order.isDelivered) return orderDeliveredDriver();
    return _main();
  }

  Widget _main() {
    return Stack(
      children: [
        if (!kIsWeb)
          OrderTrackingGoogleMaps(
            driverPhoneNumber: '',
            customerLocationStream: _customerLocationSubject.stream,
            driverLocationStream: _driverLocationSubject.stream,
          ),
        if (kIsWeb)
          OrderTrackingBingMaps(
            driverPhoneNumber: '',
            customerLocationStream: _customerLocationSubject.stream,
            driverLocationStream: _driverLocationSubject.stream,
          ),
        Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 8.0, horizontal: 125.0),
              child: FloatingActionButton(
                onPressed: () => _startNavigation(context),
                child: Image.asset(
                  'assets/images/navigation_icon.png',
                  width: 32.0,
                  height: 32.0,
                  color: Colors.white,
                ),
                backgroundColor: Colors.blue,
              ),
            )),
      ],
    );
  }

  void _observeDriverLocation() {
    positionSubscription = driverFirebaseService.trackLocationService?.driverPositionStream.listen((event) {
      _driverLocationSubject.add(LatLng(event.latitude, event.longitude));
    });
  }

  void _startNavigation(BuildContext context) async {
    var currentCustomer = customer;
    if (currentCustomer == null) return;
    var latitude = currentCustomer.latitude;
    var longitude = currentCustomer.longitude;
    final url =
        'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude';
    var uri = Uri.parse(url);
    if(kIsWeb) {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GoogleMapsInWebView(
          uri: uri, // Replace with your desired URL
        ),
      ),
    );
  }
}
