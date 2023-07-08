import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_login_architecture/model.dart';

import '../firebase_backend/customer_service.dart';
import '../utils/global_views.dart';

class DriverDetailsScreen extends StatefulWidget {
  final CustomerFirebaseService customerFirebaseService;

  DriverDetailsScreen(this.customerFirebaseService);

  @override
  _DriverDetailsScreenState createState() =>
      _DriverDetailsScreenState(customerFirebaseService);
}

class _DriverDetailsScreenState extends State {
  final CustomerFirebaseService customerFirebaseService;
  bool? isCustomerHasOrder = null;
  Driver? driverModel;
  StreamSubscription<Driver?>? driverSubscription;
  StreamSubscription<ServiceModel?>? orderSubscription;

  _DriverDetailsScreenState(this.customerFirebaseService);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    driverSubscription = customerFirebaseService
        .getDriverModelStream()
        .listen((event) => setState(() => driverModel = event));

    orderSubscription = customerFirebaseService.getServiceStream().listen(
        (event) => setState(
            () => isCustomerHasOrder = event != null && event.id != ''));
  }

  @override
  void dispose() {
    driverSubscription?.cancel();
    orderSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var currentDriver = driverModel;
    if (currentDriver == null || isCustomerHasOrder == null)
      return loadingScreen();

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.onPrimary,
      appBar: AppBar(
        title: Text('Driver Details'),
      ),
      body: _body(currentDriver),
    );
  }

  Widget _body(Driver driver) {
    if (isCustomerHasOrder == false) return noOrderWidget();
    if (driver.id == 0) return noDriverWidget();
    return _main(driver);
  }

  Widget _main(Driver driver) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/user_profile.png',
              width: 100,
              height: 100,
            ),
            SizedBox(height: 12),
            Text(
              'Driver ID: ${driver.id}',
            ),
            SizedBox(height: 12),
            Text(
              'Driver Name: ${driver.name}',
            ),
            SizedBox(height: 12),
            Text(
              'Driver phone number: ${driver.phoneNumber}',
            ),
            SizedBox(height: 12),
            Text(
              'Driver Car License: ${driver.carLicense}',
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
                    color: Color(driver.carColor),
                    border: Border.all(color: Colors.black),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
