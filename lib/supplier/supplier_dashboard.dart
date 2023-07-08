import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_login_architecture/supplier/supplier_my_clients.dart';
import 'package:flutter_login_architecture/supplier/supplier_place_order.dart';
import 'package:flutter_login_architecture/supplier/supplier_track_order.dart';
import 'package:flutter_login_architecture/supplier/supplier_update_order.dart';

import '../firebase_backend/supplier_service.dart';
import '../model.dart';
import '../utils/global_views.dart';
import '../utils/permissions.dart';

class SupplierDashboard extends StatefulWidget {
  final SupplierFirebaseService supplierFirebaseService;

  SupplierDashboard(this.supplierFirebaseService);

  @override
  State<StatefulWidget> createState() =>
      _SupplierDashboard(supplierFirebaseService);
}

class _SupplierDashboard extends State {
  final SupplierFirebaseService supplierFirebaseService;
  StreamSubscription<Supplier?>? subscription = null;
  Supplier? supplier;

  _SupplierDashboard(this.supplierFirebaseService);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    requestLocationPermission(context);
    subscription = supplierFirebaseService.supplierStream
        .listen((event) => setState(() => supplier = event));
  }

  @override
  void dispose() {
    super.dispose();
    subscription?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    var currentSupplier = supplier;
    if (currentSupplier == null || currentSupplier.id == 0)
      return loadingScreen();
    return Scaffold(
      appBar: dashboardAppBar(context, 'Supplier Dashboard'),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Logged in as Supplier',
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
                'Supplier ID: ${currentSupplier.id}',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 8),
              Text(
                'Supplier Name: ${currentSupplier.name}',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 18),
              if (currentSupplier.orderId == 0)
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => navigateToPlaceOrder(context),
                        child: Text('Place Order'),
                      ),
                    ),
                  ],
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => navigateToTrackMyOrders(context),
                        child: Text('Track My Order'),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => navigateToUpdateOrder(context),
                        child: Text('Update Order'),
                      ),
                    ),
                  ],
                ),
              SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => navigateToMyCustomers(context),
                      child: Text('My Customers'),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => navigateToMyDrivers(context),
                      child: Text('My Drivers'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  navigateToTrackMyOrders(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => SupplierOrderTracking(supplierFirebaseService)));
  }

  navigateToPlaceOrder(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => SupplierPlaceOrder(supplierFirebaseService)));
  }

  navigateToUpdateOrder(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => SupplierUpdateOrder(supplierFirebaseService)));
  }

  navigateToMyCustomers(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => SupplierMyClients(
              supplier!.myCustomersId,
              'Customer',
              supplierFirebaseService.addCustomer,
            )));
  }

  navigateToMyDrivers(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => SupplierMyClients(
          supplier!.myDriversId,
          'Driver',
          supplierFirebaseService.addDriver,
        )));
  }
}
