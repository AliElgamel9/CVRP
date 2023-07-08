import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_login_architecture/driver/driver_track_order.dart';
import 'package:flutter_login_architecture/driver/show_order_details.dart';
import 'package:flutter_login_architecture/model.dart';
import 'package:flutter_login_architecture/utils/loading_task.dart';

import '../firebase_backend/driver_service.dart';
import '../firebase_backend/utils.dart';
import '../utils/global_views.dart';
import '../utils/permissions.dart';
import 'driver_track_location_service.dart';

class DriverDashboard extends StatefulWidget {
  final DriverFirebaseService driverFirebaseService;

  DriverDashboard(this.driverFirebaseService) {
    stopAndroidLiveTrackingInBackground();
  }

  @override
  State<StatefulWidget> createState() =>
      _DriverDashboard(driverFirebaseService);
}

class _DriverDashboard extends State {
  final DriverFirebaseService driverFirebaseService;

  StreamSubscription<Driver?>? subscription = null;
  Driver? driver;

  var isLoading = false;

  _DriverDashboard(this.driverFirebaseService);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    requestLocationPermission(context);
    subscription = driverFirebaseService.driverStream.listen((event) {
      driverFirebaseService.startDriverLocationTracking(context);
      setState(() => driver = event);
    });
  }

  @override
  void dispose() {
    subscription?.cancel();
    driverFirebaseService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var currentDriver = driver;
    if (currentDriver == null) return loadingScreen();
    return Scaffold(
      appBar: dashboardAppBar(context, 'Driver Dashboard'),
      body: ProvideLoadingTask(
        isLoading: isLoading,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Logged in as driver',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16.0),
                Image.asset(
                  'assets/images/user_profile.png',
                  width: 100.0,
                  height: 100.0,
                ),
                SizedBox(height: 24.0),
                Text(
                  'Driver ID: ${currentDriver.id}',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 8.0),
                Text(
                  'Driver name: ${currentDriver.name}',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 12),
                Text(
                  'Driver Car License: ${currentDriver.carLicense}',
                ),
                SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Driver Car color'),
                    SizedBox(width: 12),
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Color(currentDriver.carColor),
                        border: Border.all(color: Colors.black),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 18.0),
                if (currentDriver.totalServices == 0)
                  _onNoOrdersAssigned(context, currentDriver)
                else if (currentDriver.remainingServices == 0)
                  _onNoRemainOrders(context, currentDriver)
                else
                  _onRemainOrders(context, currentDriver),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _onRemainOrders(BuildContext context, Driver currentDriver) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'You have ${currentDriver.remainingServices} orders remaining to deliver from ${currentDriver.totalServices} orders',
          style: TextStyle(fontSize: 16),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 12.0),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () => _navigateToOrderDetails(context),
                child: Text('Show Order Details'),
              ),
            ),
            SizedBox(width: 10.0),
            Expanded(
              child: ElevatedButton(
                onPressed: () => _navigateToOrderMap(context),
                child: Text('Show Order Map'),
              ),
            ),
          ],
        ),
        SizedBox(height: 8.0),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () => _showConfirmDialog(context,
                    'Are you sure you want to mark the order as delivered?', _markAsDelivered),
                child: Text('Mark Order as Delivered'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _onNoRemainOrders(BuildContext context, Driver currentDriver) {
    return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'You have delivered ${currentDriver.totalServices} orders successfully, there are no orders remaining to deliver, go back to the deposit',
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 12),
          ElevatedButton(
            onPressed: reachedTheDepotConfirmation,
            child: Text('Reached the depot'),
          ),
        ]
    );
  }

  Widget _onNoOrdersAssigned(BuildContext context, Driver currentDriver) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Text(
        'There is no order assigned to you, please wait for the order to be assigned to you',
        style: TextStyle(fontSize: 16),
        textAlign: TextAlign.center,
      ),
    );
  }

  _navigateToOrderDetails(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => OrderDetailsScreen(driverFirebaseService)));
  }

  _navigateToOrderMap(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => DriverOrderTracking(driverFirebaseService)));
  }

  _showConfirmDialog(BuildContext context, String msg, Function onConfirm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm'),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              onConfirm();
              Navigator.of(context).pop();
            },
            child: Text('Confirm'),
          ),
        ],
      ),
    );
  }

  _markAsDelivered() async {
    setState(() => isLoading = true);
    var res = await driverFirebaseService.serviceDelivered(context);
    var color =
        res.type == RequestResponseType.SUCCESS ? Colors.blue : Colors.red;
    showSnackBarMessage(context, res.message, color);
    setState(() => isLoading = false);
  }

  reachedTheDepotConfirmation() {
    _showConfirmDialog(context, 'Are you sure you reached the depot?', reachedTheDepot);
  }

  reachedTheDepot() async {
    setState(()=>isLoading = true);
    var result = await driverFirebaseService.reachedTheDepot();
    if(result.type == RequestResponseType.FAILURE)
      showSnackBarMessage(context, result.message, Colors.red);
    setState(()=>isLoading = false);
  }
}
