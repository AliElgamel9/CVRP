import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_login_architecture/customer/cutomer_track_order.dart';
import 'package:flutter_login_architecture/customer/driver_details_view.dart';

import '../firebase_backend/customer_service.dart';
import '../utils/global_views.dart';
import '../model.dart';
import '../utils/permissions.dart';

class CustomerDashboard extends StatefulWidget {
  final CustomerFirebaseService customerFirebaseService;

  CustomerDashboard(this.customerFirebaseService);

  @override
  State<StatefulWidget> createState() =>
      _CustomerDashboard(customerFirebaseService);
}

class _CustomerDashboard extends State {
  final CustomerFirebaseService customerFirebaseService;
  StreamSubscription<Customer?>? subscription = null;
  Customer? customer;

  _CustomerDashboard(this.customerFirebaseService);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    requestLocationPermission(context);
    subscription = customerFirebaseService.customerStream
        .listen((event) => setState(() => customer = event));
  }

  @override
  void dispose() {
    subscription?.cancel();
    customerFirebaseService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var currentCustomer = customer;
    if (currentCustomer == null) return loadingScreen();
    return Scaffold(
      appBar: dashboardAppBar(context, 'Customer Dashboard'),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Logged in as Customer',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Image.asset(
                'assets/images/user_profile.png',
                width: 100,
                height: 100,
              ),
              SizedBox(height: 24),
              Text(
                'Customer ID: ${currentCustomer.id}',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 8),
              Text(
                'Customer Name: ${currentCustomer.name}',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 18),
              if (currentCustomer.serviceId == '')
                Text(
                  'You have no order yet',
                  style: TextStyle(fontSize: 16),
                )
              else
                Row(
                  children: [
                    Expanded(child:ElevatedButton(
                      onPressed: () => navigateToTrackMyOrder(context),
                      child: Text('Track My Order'),
                    )),
                    SizedBox(width: 8),
    Expanded(child:ElevatedButton(
                      onPressed: () => navigateToDriverDetails(context),
                      child: Text('Driver Details'),
                    ),)
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  navigateToTrackMyOrder(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => CustomerOrderTracking(customerFirebaseService)));
  }

  navigateToDriverDetails(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => DriverDetailsScreen(customerFirebaseService)));
  }
}
