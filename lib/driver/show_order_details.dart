import 'dart:async';

import 'package:flutter/material.dart';

import '../firebase_backend/driver_service.dart';
import '../model.dart';
import '../utils/global_views.dart';

class OrderDetailsScreen extends StatefulWidget {
  final DriverFirebaseService driverFirebaseService;

  OrderDetailsScreen(this.driverFirebaseService);

  @override
  _OrderDetailsScreen createState() =>
      _OrderDetailsScreen(driverFirebaseService);
}

class _OrderDetailsScreen extends State {
  final DriverFirebaseService driverFirebaseService;
  UserModel? customerModel;
  ServiceModel? orderModel;
  StreamSubscription<UserModel?>? customerSubscription;
  StreamSubscription<ServiceModel?>? orderSubscription;

  _OrderDetailsScreen(this.driverFirebaseService);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    customerSubscription = driverFirebaseService
        .getCustomerModelStream()
        .listen((event) => setState(() => customerModel = event));

    orderSubscription = driverFirebaseService
        .getOrderModelStream()
        .listen((event) => setState(() => orderModel = event));
  }

  @override
  void dispose() {
    customerSubscription?.cancel();
    orderSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var currentCustomer = customerModel;
    var currentOrder = orderModel;
    if (currentCustomer == null || currentOrder == null) return loadingScreen();

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.onPrimary,
      appBar: AppBar(
        title: Text(
          'Order Details',
        ),
      ),
      body: _body(
        currentOrder,
        currentCustomer,
      ),
    );
  }

  Widget _body(ServiceModel order, UserModel customer) {
    if (order.id == "") return noOrderWidget();
    return _main(order, customer);
  }

  Widget _main(ServiceModel order, UserModel customer) {
    return Container(
      margin: EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 64.0,
                height: 64.0,
                margin: EdgeInsets.only(right: 10.0),
                child: Image.asset('assets/images/user_profile.png'),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Customer ID: ${customer.id}',
                    ),
                    Text(
                      'Customer Name: ${customer.name}',
                    ),
                    Text(
                      'Customer Number: ${customer.phoneNumber}',
                    ),
                  ],
                ),
              )
            ],
          ),
          SizedBox(height: 30.0),
          Row(
            children: [
              Container(
                width: 64.0,
                height: 64.0,
                margin: EdgeInsets.only(right: 10.0),
                child: Image.asset('assets/images/location_pin.png'),
              ),
              Expanded(
                child:Text(
                '${order.locationName}',
                maxLines: 2,
              ),)
            ],
          ),
          SizedBox(height: 30.0),
          Row(
            children: [
              Container(
                width: 64.0,
                height: 64.0,
                margin: EdgeInsets.only(right: 10.0),
                child: Image.asset('assets/images/clock.png'),
              ),
              Text(
                'Requested time to deliver: ${order.expectedArrivalTime}',
              ),
            ],
          ),
          SizedBox(height: 20.0),
          Row(
            children: [
              Container(
                width: 84.0,
                height: 84.0,
                margin: EdgeInsets.only(right: 10.0),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
                child: Image.asset('assets/images/truck.png'),
              ),
              Text(
                'Demand capacity: ${order.demand} items',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
