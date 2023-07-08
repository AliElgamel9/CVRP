import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_login_architecture/firebase_backend/supplier_service.dart';
import 'package:flutter_login_architecture/model.dart';
import 'package:flutter_login_architecture/supplier/supplier_track_driver.dart';
import 'package:flutter_login_architecture/supplier/utils.dart';
import 'package:flutter_login_architecture/utils/collapsible_widget.dart';
import 'package:flutter_login_architecture/utils/global_views.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class SupplierOrderTracking extends StatefulWidget {
  final SupplierFirebaseService supplierFirebaseService;

  SupplierOrderTracking(this.supplierFirebaseService);

  @override
  State<StatefulWidget> createState() =>
      _SupplierOrderTrackingState(supplierFirebaseService);
}

class _SupplierOrderTrackingState extends State<SupplierOrderTracking> {
  final SupplierFirebaseService supplierFirebaseService;

  StreamSubscription<List<DriverTrackingModel>>?
      driversTrackingModelSubscription = null;
  List<DriverTrackingModel>? driversTrackingModel;

  _SupplierOrderTrackingState(this.supplierFirebaseService);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    driversTrackingModelSubscription = supplierFirebaseService
        .getDriverTrackingModelStream()
        .listen((event) => setState(() => driversTrackingModel = event));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Order Tracking'),
      ),
      body: _body(),
    );
  }

  Widget _body() {
    if (driversTrackingModel == null) return loadingScreen();
    if (driversTrackingModel!.isEmpty) return noOrderWidget();
    return _main();
  }

  Widget _main() {
    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(height: 12),
          Text('Your Drivers', style: TextStyle(fontSize: 20)),
          SizedBox(height: 12),
          for (var model in driversTrackingModel!)
            Column(
              children: [
                _driverTrackingInfoWidget(model),
                SizedBox(height: 12),
              ],
            ),
        ],
      ),
    );
  }

  Widget _driverTrackingInfoWidget(DriverTrackingModel model) {
    return CollapsibleWidget(
      headerTitle: 'Driver ${model.driverName}',
      onActionClick: () => navigateToTrackDriver(model),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Expanded(child: Text('Customer Name')),
              SizedBox(width: 12),
              Container(
                width: 65,
                transformAlignment: Alignment.center,
                child: Text('Demand'),
              ),
              SizedBox(width: 12),
              Container(
                width: 65,
                transformAlignment: Alignment.center,
                child: Text('Status'),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Expanded(
                child: listTextWidget(
                  model.customersName,
                  encodeName: shortenName,
                ),
              ),
              SizedBox(width: 12),
              Container(
                width: 50,
                transformAlignment: Alignment.centerLeft,
                child: listTextWidget(model.demands),
              ),
              SizedBox(width: 12),
              Container(
                width: 70,
                transformAlignment: Alignment.centerLeft,
                child: _statusListWidget(
                    model.currentServiceIndex, model.demands.length),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusListWidget(int currentServiceIndex, int count) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        for (int i = 0; i < count; i++)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Container(
                height: 35,
                alignment: Alignment.centerLeft,
                child: _statusWidget(i, currentServiceIndex),
              ),
              SizedBox(height: 12),
            ],
          ),
      ],
    );
  }

  /**
   * 0: delivered
   * 1: in the way
   * 2: waiting
   */
  Widget _statusWidget(int index, int currentServiceIndex) {
    if (index < currentServiceIndex)
      return Text('Delivered',
          style: TextStyle(color: Colors.green), textAlign: TextAlign.start);
    else if (index == currentServiceIndex)
      return Text('In the way',
          style: TextStyle(color: Colors.orange), textAlign: TextAlign.start);
    return Text('Waiting',
        style: TextStyle(color: Colors.red), textAlign: TextAlign.start);
  }

  navigateToTrackDriver(DriverTrackingModel model) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SupplierTrackDriver(
          supplierFirebaseService: supplierFirebaseService,
          driverId: model.driverId,
          driverPhoneNumber: model.driverPhoneNumber,
          customerLocation:
              LatLng(model.customerLatitude, model.customerLongitude),
        ),
      ),
    );
  }
}
