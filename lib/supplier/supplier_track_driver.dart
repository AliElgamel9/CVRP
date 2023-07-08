import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_login_architecture/firebase_backend/supplier_service.dart';
import 'package:flutter_login_architecture/firebase_backend/utils.dart';
import 'package:flutter_login_architecture/utils/global_views.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:rxdart/rxdart.dart';

import '../utils/track_order_maps.dart';

class SupplierTrackDriver extends StatefulWidget {
  final SupplierFirebaseService supplierFirebaseService;
  final int driverId;
  final String driverPhoneNumber;
  final LatLng customerLocation;

  SupplierTrackDriver({
    required this.supplierFirebaseService,
    required this.driverId,
    required this.driverPhoneNumber,
    required this.customerLocation,
  });

  @override
  State<StatefulWidget> createState() => _SupplierTrackDriverState(
      supplierFirebaseService, driverId, driverPhoneNumber, customerLocation);
}

class _SupplierTrackDriverState extends State<SupplierTrackDriver> {
  final SupplierFirebaseService supplierFirebaseService;
  final int driverId;

  final _customerLocationSubject = BehaviorSubject<LatLng>();
  final _driverLocationSubject = BehaviorSubject<LatLng?>();
  String? driverPhoneNumber;

  StreamSubscription<DatabaseEvent>? driverLocationSubscription = null;

  _SupplierTrackDriverState(
    this.supplierFirebaseService,
    this.driverId,
    this.driverPhoneNumber,
    LatLng customerLocation,
  ) {
    _customerLocationSubject.add(customerLocation);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _listenToDriverLocation();
  }

  @override
  void dispose() {
    super.dispose();
    driverLocationSubscription?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Driver Tracking'),
      ),
      body: _body(),
    );
  }

  Widget _body() {
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

  _listenToDriverLocation() {
    driverLocationSubscription =
        getDriverLiveLocationFromFirebase(driverId).onValue.listen((event) {
      if (!event.snapshot.exists) {
        _driverLocationSubject.add(null);
        return;
      }
      var data = event.snapshot.value as Map<dynamic, dynamic>;
      _driverLocationSubject
          .add(LatLng(data['latitude'] * 1.0, data['longitude'] * 1.0));
    });
  }
}
