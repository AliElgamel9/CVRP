import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_login_architecture/model.dart';
import 'package:rxdart/rxdart.dart';
import 'package:flutter_login_architecture/firebase_backend/utils.dart';
import 'authentication_services.dart';


class CustomerFirebaseService {
  final _customerSubject = BehaviorSubject<Customer>();
  final _driverModelSubject = BehaviorSubject<Driver?>();
  final _serviceSubject = BehaviorSubject<ServiceModel?>();
  StreamSubscription<UserModel?>? _userSubscription;

  ValueStream<Customer> get customerStream => _customerSubject.stream;

  ValueStream<Driver?> get driverModelStream => _driverModelSubject.stream;

  ValueStream<ServiceModel?> get serviceStream => _serviceSubject.stream;

  CustomerFirebaseService(AuthenticationService auth) {
    _userSubscription = auth.userModelStream.listen((event) async {
      _driverModelSubject.add(null);
      _serviceSubject.add(null);
      await _loadCustomer(event);
      _loadDriverModel();
    });
  }

  dispose() {
    _userSubscription?.cancel();
  }

  ValueStream<ServiceModel?> getServiceStream() {
    _loadService();
    return serviceStream;
  }

  ValueStream<Driver?> getDriverModelStream() {
    _loadDriverModel();
    return driverModelStream;
  }

  _loadCustomer(UserModel? user) async {
    if (user == null) {
      _customerSubject.add(Customer.empty());
      return;
    }
    var res = await getCustomer(user.id);
    _customerSubject.add(res);
  }

  Future<void> _loadService() async {
    var service = serviceStream.valueOrNull;
    // check if order is already loaded
    if (service != null && service.id != 0) return;
    var currentCustomer = customerStream.valueOrNull;
    // if customer is not logged in
    if (currentCustomer == null) {
      _serviceSubject.add(ServiceModel.empty());
      return;
    }
    // check if customer has an order
    var serviceId = currentCustomer.serviceId;
    if (serviceId == 0) {
      _serviceSubject.add(ServiceModel.empty());
      return;
    }
    service = await getService(serviceId);
    _serviceSubject.add(service);
  }

  _loadDriverModel() async {
    var driver = driverModelStream.valueOrNull;
    // check if driver is already loaded
    if (driver != null && driver.id != 0) return;
    // if customer is not logged in
    if (customerStream.valueOrNull == null) {
      _driverModelSubject.add(Driver.empty());
      return;
    }
    // if order is not loaded
    if (serviceStream.valueOrNull == null) await _loadService();
    var driverId = serviceStream.valueOrNull?.driverId ?? 0;
    // if order has no driver
    if (driverId == 0) {
      _driverModelSubject.add(Driver.empty());
      return;
    }
    driver = await getDriver(driverId);
    _driverModelSubject.add(driver);
  }

  Future<DatabaseReference?> getDriverLiveLocation() async {
    await _loadDriverModel();
    var driverId = driverModelStream.valueOrNull?.id;
    if (driverId == null || driverId == '') return null;
    return getDriverLiveLocationFromFirebase(driverId);
  }
}