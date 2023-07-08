import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_login_architecture/utils/track_order_maps.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:rxdart/rxdart.dart';

import '../firebase_backend/customer_service.dart';
import '../model.dart';
import '../utils/global_views.dart';

class CustomerOrderTracking extends StatefulWidget {
  final CustomerFirebaseService customerFirebaseService;

  CustomerOrderTracking(this.customerFirebaseService);

  @override
  _CustomerOrderTrackingState createState() =>
      _CustomerOrderTrackingState(customerFirebaseService);
}

class _CustomerOrderTrackingState extends State {
  final CustomerFirebaseService customerFirebaseService;
  ServiceModel? serviceModel;
  StreamSubscription<ServiceModel?>? subscription;

  _CustomerOrderTrackingState(this.customerFirebaseService);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    subscription = customerFirebaseService
        .getServiceStream()
        .listen((event) => setState(() => serviceModel = event));
  }

  @override
  void dispose() {
    subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var currentService = serviceModel;

    return Scaffold(
      appBar: AppBar(
        title: Text('Order Tracking'),
      ),
      backgroundColor: Theme.of(context).colorScheme.onPrimary,
      body: _body(currentService),
    );
  }

  Widget _body(ServiceModel? currentService) {
    if (currentService == null)
      return loadingScreen();
    else if (currentService.id == 0)
      return noOrderWidget();
    else if (currentService.isDelivered) return orderDeliveredCustomer();
    return _main(currentService);
  }

  Widget _main(ServiceModel currentService) {
    var expectedArrivalTime = currentService.expectedArrivalTime;
    if (expectedArrivalTime == '') expectedArrivalTime = 'N/A';
    dynamic demand = currentService.demand;
    if (demand == 0) demand = 'N/A';

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 8),
          Row(children: [
            Image.asset(
              'assets/images/clock.png',
              width: 64.0,
              height: 64.0,
            ),
            SizedBox(width: 12.0),
            Text(
              'Expected Arrival time is at $expectedArrivalTime',
            ),
          ]),
          SizedBox(height: 16),
          Text(
            'Order demand: $demand',
          ),
          SizedBox(height: 16),
          Text(
            'Tracking your order on the map',
          ),
          SizedBox(height: 16),
          Expanded(
              child: Container(
            child: MapTracking(customerFirebaseService),
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.blue, // Set the border color
                width: 1.0, // Set the border width
              ),
            ),
          )),
        ],
      ),
    );
  }
}

class MapTracking extends StatefulWidget {
  final CustomerFirebaseService customerFirebaseService;

  MapTracking(this.customerFirebaseService);

  @override
  _MapTrackingState createState() => _MapTrackingState(customerFirebaseService);
}

class _MapTrackingState extends State<MapTracking> {
  final CustomerFirebaseService customerFirebaseService;

  final _customerLocationSubject = BehaviorSubject<LatLng>();
  final _driverLocationSubject = BehaviorSubject<LatLng?>();
  String? driverPhoneNumber;

  StreamSubscription<DatabaseEvent>? subscriptionLocation = null;
  StreamSubscription<UserModel?>? subscriptionDriver = null;


  _MapTrackingState(this.customerFirebaseService);

  @override
  void dispose() {
    super.dispose();
    subscriptionLocation?.cancel();
    subscriptionDriver?.cancel();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    var customer = customerFirebaseService.customerStream.value;
    _customerLocationSubject.add(LatLng(customer.latitude, customer.longitude));

    subscriptionDriver =
        customerFirebaseService.getDriverModelStream().listen((event) {
      setState(() => driverPhoneNumber = event?.phoneNumber);
      _listenToDriverLiveLocation();
    });
  }

  _listenToDriverLiveLocation() {
    subscriptionLocation?.cancel();
    customerFirebaseService.getDriverLiveLocation().then((ref) {
      if (ref == null) return;
      subscriptionLocation = ref.onValue.listen((event) {
        if (!event.snapshot.exists) {
          _driverLocationSubject.add(null);
          return;
        }
        var data = event.snapshot.value as Map<dynamic, dynamic>;
        _driverLocationSubject
            .add(LatLng(data['latitude'] * 1.0, data['longitude'] * 1.0));
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (driverPhoneNumber == null) return loadingScreen();
    if (kIsWeb)
      return OrderTrackingBingMaps(
          driverPhoneNumber: driverPhoneNumber,
          customerLocationStream: _customerLocationSubject.stream,
          driverLocationStream: _driverLocationSubject.stream);
    return OrderTrackingGoogleMaps(
        driverPhoneNumber: driverPhoneNumber,
        customerLocationStream: _customerLocationSubject.stream,
        driverLocationStream: _driverLocationSubject.stream);
  }
}