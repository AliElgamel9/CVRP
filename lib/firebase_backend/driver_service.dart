import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_login_architecture/firebase_backend/utils.dart';
import 'package:flutter_login_architecture/model.dart';
import 'package:rxdart/rxdart.dart';

import '../driver/driver_track_location_service.dart';
import 'authentication_services.dart';

class DriverFirebaseService {
  final _driverSubject = BehaviorSubject<Driver>();
  final _customerModelSubject = BehaviorSubject<Customer?>();
  final _serviceSubject = BehaviorSubject<ServiceModel?>();
  StreamSubscription<UserModel?>? _userSubscription;

  ValueStream<Driver> get driverStream => _driverSubject.stream;

  ValueStream<Customer?> get customerModelStream =>
      _customerModelSubject.stream;

  ValueStream<ServiceModel?> get serviceStream => _serviceSubject.stream;

  TrackDriverLocationService? trackLocationService;

  DriverFirebaseService(AuthenticationService auth) {
    _userSubscription = auth.userModelStream.listen((event) async {
      _customerModelSubject.add(null);
      _serviceSubject.add(null);
      await _loadDriver(event);
      _loadCustomerModel();
    });
  }

  dispose() {
    _userSubscription?.cancel();
    _driverSubject.close();
    _customerModelSubject.close();
    _serviceSubject.close();
    trackLocationService?.cancelTracking();
    startAndroidLiveTrackingInBackground();
  }

  ValueStream<ServiceModel?> getOrderModelStream() {
    _loadService();
    return serviceStream;
  }

  ValueStream<Customer?> getCustomerModelStream() {
    _loadCustomerModel();
    return customerModelStream;
  }

  startDriverLocationTracking(BuildContext context) {
    trackLocationService?.cancelTracking();
    trackLocationService = null;
    var driver = driverStream.valueOrNull;
    if (driver == null || driver.id == 0 || driver.remainingServices == 0)
      return;
    trackLocationService = TrackDriverLocationService(driver.id.toString());
    trackLocationService!.startTracking(context);
  }

  Future<RequestResponse> serviceDelivered(BuildContext context) async {
    var currentDriver = driverStream.valueOrNull;
    var currentServiceId = currentDriver?.serviceId;
    // check if driver is logged in
    if (currentDriver == null || currentDriver.id == 0)
      return RequestResponse.failure('No driver found, please sign in again');
    // check if driver has an order
    if (currentServiceId == null || currentServiceId == 0)
      return RequestResponse.failure('No order found');
    // mark order as delivered
    var serviceDoc = await FirebaseFirestore.instance
        .collection('service')
        .doc(currentServiceId.toString());
    await serviceDoc.update({'isDelivered': true});
    // get driver doc
    var driverDoc = await FirebaseFirestore.instance
        .collection('Driver')
        .doc(currentDriver.id.toString());
    // remove order from driver and update remaining orders
    var driverSnapshot = await driverDoc.get();
    var remainingServices = driverSnapshot['remainingServices'] - 1;
    await driverDoc.update({
      'remainingServices': remainingServices,
    });
    // update driver stream
    var nextServiceIndex = driverSnapshot['totalServices'] - remainingServices;
    var nextServiceId = driverSnapshot['servicesId'][nextServiceIndex];
    if (nextServiceId != 0) {
      // lock the service
      var serviceDoc = await FirebaseFirestore.instance
          .collection('service')
          .doc(nextServiceId.toString());
      await serviceDoc.update({'isLocked': true});
    }
    var driver = Driver.clone(currentDriver,
        serviceId: nextServiceId, remainingServices: remainingServices);
    _driverSubject.add(driver);
    return RequestResponse.success('Order delivered successfully');
  }

  Future<RequestResponse> reachedTheDepot() async {
    var currentDriver = driverStream.valueOrNull;
    // check if driver is logged in
    if (currentDriver == null || currentDriver.id == 0)
      return RequestResponse.failure('No driver found, please sign in again');
    await FirebaseFirestore.instance
        .collection('order')
        .doc(currentDriver.orderId.toString())
        .update({
      'driverFinishedId': currentDriver.id,
      'status': 'driverFinished'
    });
    return RequestResponse.success('Thanks for your job, wait for another order');
  }

  _loadDriver(UserModel? user) async {
    if (user == null) {
      _driverSubject.add(Driver.empty());
      return;
    }
    var driver = await getDriver(user.id);
    _driverSubject.add(driver);
  }

  Future<void> _loadService() async {
    var service = serviceStream.valueOrNull;
    // if order is loaded already return
    if (service != null && service.id != 0) return;
    // if driver is not logged in
    var currentDriver = driverStream.valueOrNull;
    if (currentDriver == null) {
      _serviceSubject.add(ServiceModel.empty());
      return;
    }
    var serviceId = currentDriver.serviceId;
    // check if the driver has an order
    if (serviceId == 0) {
      _serviceSubject.add(ServiceModel.empty());
      return;
    }
    service = await getService(serviceId);
    _serviceSubject.add(service);
  }

  _loadCustomerModel() async {
    // if customer is loaded already return
    var customer = customerModelStream.valueOrNull;
    if (customer != null && customer.id != 0) return;
    // if driver is not logged in
    if (driverStream.valueOrNull == null) {
      _customerModelSubject.add(Customer.empty());
      return;
    }
    // check if order is loaded
    await _loadService();
    var customerId = serviceStream.valueOrNull?.customerId ?? 0;
    // check if driver has order, then the order has a customer
    if (customerId == 0) {
      _customerModelSubject.add(Customer.empty());
      return;
    }
    customer = await getCustomer(customerId);
    _customerModelSubject.add(customer);
  }
}
