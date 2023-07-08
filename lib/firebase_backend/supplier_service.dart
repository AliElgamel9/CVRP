import 'dart:async';
import 'dart:core';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_login_architecture/firebase_backend/utils.dart';
import 'package:flutter_login_architecture/model.dart';
import 'package:rxdart/rxdart.dart';

import 'authentication_services.dart';

class SupplierFirebaseService {
  final _supplierSubject = BehaviorSubject<Supplier>();
  final _orderSubject = BehaviorSubject<OrderModel?>();
  final _orderFullDataSubject = BehaviorSubject<OrderModelFullData?>();
  final _services = BehaviorSubject<List<ServiceModel>?>();
  final _driverTrackingModelSubject =
      BehaviorSubject<List<DriverTrackingModel>>();

  StreamSubscription<UserModel?>? _userSubscription;

  ValueStream<Supplier> get supplierStream => _supplierSubject.stream;

  ValueStream<OrderModel?> get _orderStream => _orderSubject.stream;

  ValueStream<OrderModelFullData?> get _orderFullDataStream =>
      _orderFullDataSubject.stream;

  ValueStream<List<ServiceModel>?> get _servicesStream => _services.stream;

  ValueStream<List<DriverTrackingModel>> get _driverTrackingModelStream =>
      _driverTrackingModelSubject.stream;

  SupplierFirebaseService(AuthenticationService auth) {
    _userSubscription = auth.userModelStream.listen((event) async {
      await _loadSupplier(event);
    });
  }

  dispose() {
    _userSubscription?.cancel();
  }

  ValueStream<OrderModel?> getOrderStream() {
    _loadOrder();
    return _orderStream;
  }

  ValueStream<List<ServiceModel>?> getServicesStream() {
    _loadServices();
    return _servicesStream;
  }

  ValueStream<OrderModelFullData?> getOrderFullDataStream() {
    _loadOrderFullData();
    return _orderFullDataStream;
  }

  ValueStream<List<DriverTrackingModel>> getDriverTrackingModelStream() {
    _loadDriversTrackingModel();
    return _driverTrackingModelStream;
  }

  Future<RequestResponse> placeOrder({
    required List<int> customersId,
    required List<int> customersDemandMin,
    required List<int> customersDemandMax,
    required List<int> vehiclesCapacity,
    required List<int> driversId,
  }) async {
    var currentSupplier = supplierStream.valueOrNull;
    if (currentSupplier == null || currentSupplier.id == 0)
      return RequestResponse.failure('no supplier');
    // validate data
    var res = _validateOrder(customersId, customersDemandMin,
        customersDemandMax, vehiclesCapacity, driversId);
    if (res != null) return RequestResponse.failure(res);

    // add orders to database and assign it to the customers
    List<int> servicesId = await _addNewServicesToCustomers(customersId);

    // add the order to firebase
    var id = await IncrementCountAndGet('order');
    var orderData = {
      'supplierId': currentSupplier.id,
      'customersId': customersId,
      'minDemands': customersDemandMin,
      'maxDemands': customersDemandMax,
      'numberOfServices': customersId.length,
      'numberOfVehicles': driversId.length,
      'driversId': driversId,
      'servicesId': servicesId,
      'vehiclesCapacity': vehiclesCapacity,
      'isLocked': false,
      'newCustomersId': <int>[],
      'newMaxDemands': <int>[],
      'newMinDemands': <int>[],
      'deletedCustomersId': <int>[],
      'status': 'new',
    };
    await FirebaseFirestore.instance
        .collection('order')
        .doc(id.toString())
        .set(orderData);
    // assign order trip to the supplier
    await FirebaseFirestore.instance
        .collection('Supplier')
        .doc(currentSupplier.id.toString())
        .update({
      'orderId': id,
    });
    var supplier = Supplier.clone(currentSupplier, orderId: id);
    _supplierSubject.add(supplier);
    return RequestResponse.success('Order is placed successfully');
  }

  Future<RequestResponse> updateOrder({
    required List<int> newCustomersId,
    required List<int> newDemandsMin,
    required List<int> newDemandsMax,
    required List<int> deletedCustomersId,
    required List<int> deletedNewCustomersId,
  }) async {
    var currentSupplier = supplierStream.valueOrNull;
    var currentFullData = _orderFullDataSubject.value!;
    if (currentSupplier == null || currentSupplier.id == 0)
      return RequestResponse.failure('no supplier');
    // validate data
    var res =
        _validateOrderUpdate(newCustomersId, newDemandsMin, newDemandsMax);

    if (res != null) return RequestResponse.failure(res);

    // delete new customers part
    var customersCount = currentFullData.customersId.length;
    var indexesOfDeletedNewCustomers = deletedNewCustomersId
        .map((e) => customersCount + currentFullData.newCustomersId.indexOf(e))
        .toList();
    var deletedNewServicesId = <int>[];
    indexesOfDeletedNewCustomers.sort();
    indexesOfDeletedNewCustomers.reversed.forEach((index) {
      deletedNewServicesId.add(currentFullData.servicesId[index]);
      currentFullData.servicesId.removeAt(index);
    });
    _deleteCustomersService(deletedNewCustomersId, deletedNewServicesId);

    // delete customers part
    var indexesOfDeletedCustomers = deletedCustomersId
        .map((e) => currentFullData.customersId.indexOf(e))
        .toList();
    var deletedServicesId = <int>[];
    indexesOfDeletedCustomers.sort();
    indexesOfDeletedCustomers.reversed.forEach((index) {
      currentFullData.customersId.removeAt(index);
      currentFullData.minDemands.removeAt(index);
      currentFullData.maxDemands.removeAt(index);
      deletedServicesId.add(currentFullData.servicesId[index]);
      currentFullData.servicesId.removeAt(index);
    });
    _deleteCustomersService(deletedCustomersId, deletedServicesId);

    // add new services for new customers
    List<int> newCustomersIdAddRecently = newCustomersId.sublist(
        currentFullData.newCustomersId.length - deletedNewCustomersId.length);
    if (newCustomersIdAddRecently.isNotEmpty) {
      List<int> newServicesId =
          await _addNewServicesToCustomers(newCustomersIdAddRecently);
      currentFullData.servicesId.addAll(newServicesId);
    }

    var finalDeletedCustomersId = currentFullData.deletedCustomersId;
    finalDeletedCustomersId.addAll(deletedCustomersId);
    var orderData = {
      'isLocked': false,
      'customersId': currentFullData.customersId,
      'minDemands': currentFullData.minDemands,
      'maxDemands': currentFullData.maxDemands,
      'newCustomersId': newCustomersId,
      'newMaxDemands': newDemandsMax,
      'newMinDemands': newDemandsMin,
      'servicesId': currentFullData.servicesId,
      'numberOfServices': currentFullData.servicesId.length,
      'deletedCustomersId': finalDeletedCustomersId,
      'status': 'updated',
    };
    await FirebaseFirestore.instance
        .collection('order')
        .doc(currentSupplier.orderId.toString())
        .update(orderData);

    var orderFullData = OrderModelFullData.clone(
      currentFullData,
      isLocked: false,
      customersId: currentFullData.customersId,
      minDemands: currentFullData.minDemands,
      maxDemands: currentFullData.maxDemands,
      newCustomersId: newCustomersId,
      newMaxDemand: newDemandsMax,
      newMinDemand: newDemandsMin,
      servicesId: currentFullData.servicesId,
      deletedCustomersId: finalDeletedCustomersId,
    );
    _orderFullDataSubject.add(orderFullData);
    return RequestResponse.success('Order is updated successfully');
  }

  Future<RequestResponse> addCustomer(String customerId) async {
    if (customerId.isEmpty)
      return RequestResponse.failure('please enter customer id');
    // check if the supplier is logged in
    var currentSupplier = supplierStream.valueOrNull;
    if (currentSupplier == null || currentSupplier.id == 0)
      return RequestResponse.failure('no supplier');
    // check if the customer exists
    var customerRef = FirebaseFirestore.instance.collection('Customer');
    var customer = await customerRef.doc(customerId.toString()).get();
    if (!customer.exists)
      return RequestResponse.failure(
          'there is no customer with this id $customerId');
    var customerName = customer['name'];
    // check if the supplier has already this customer id
    var customerIdEncoded = '$customerName#$customerId';
    var myCustomersId = currentSupplier.myCustomersId;
    if (myCustomersId.contains(customerIdEncoded))
      return RequestResponse.failure('the customer is already added');
    // add the customer to the supplier
    myCustomersId.add(customerIdEncoded);
    // update the supplier
    await FirebaseFirestore.instance
        .collection('Supplier')
        .doc(currentSupplier.id.toString())
        .update({
      'myCustomersId': myCustomersId,
    });
    var supplier =
        Supplier.clone(currentSupplier, myCustomersId: myCustomersId);
    _supplierSubject.add(supplier);
    return RequestResponse.success('the customer is added successfully');
  }

  Future<RequestResponse> addDriver(String driverId) async {
    if (driverId.isEmpty)
      return RequestResponse.failure('please enter driver id');
    // check if the supplier is logged in
    var currentSupplier = supplierStream.valueOrNull;
    if (currentSupplier == null || currentSupplier.id == 0)
      return RequestResponse.failure('no supplier');
    // check if the customer exists
    var driverRef = FirebaseFirestore.instance.collection('Driver');
    var driver = await driverRef.doc(driverId.toString()).get();
    if (!driver.exists)
      return RequestResponse.failure(
          'there is no driver with this id $driverId');
    var driverName = driver['name'];
    // check if the supplier has already this driver id
    var driverIdEncoded = '$driverName#$driverId';
    var myDriversId = currentSupplier.myDriversId;
    if (myDriversId.contains(driverIdEncoded))
      return RequestResponse.failure('the driver is already added');
    // add the driver to the supplier
    myDriversId.add(driverIdEncoded);
    // update the supplier
    await FirebaseFirestore.instance
        .collection('Supplier')
        .doc(currentSupplier.id.toString())
        .update({
      'myDriversId': myDriversId,
    });
    var supplier = Supplier.clone(currentSupplier, myDriversId: myDriversId);
    _supplierSubject.add(supplier);
    return RequestResponse.success('the driver is added successfully');
  }

  Future<void> lockOrder() async {
    _updateOrderLock(true);
  }

  Future<void> unLockOrder() async {
    _updateOrderLock(false);
  }

  Future<List<int>> _addNewServicesToCustomers(List<int> customersId) async {
    var servicesRef = await FirebaseFirestore.instance.collection('service');
    var customerRef = await FirebaseFirestore.instance.collection('Customer');
    var servicesId = <int>[];
    for (int i = 0; i < customersId.length; i++) {
      var customerDoc = await customerRef.doc(customersId[i].toString());
      var customerSnapshot = await customerDoc.get();
      var serviceData = {
        'customerId': customersId[i],
        'demand': 0,
        'driverId': 0,
        'isLocked': false,
        'expectedArrivalTime': '',
        'isDelivered': false,
        'locationName': customerSnapshot['locationName'],
      };
      var id = await addServiceToReference(serviceData, servicesRef);
      servicesId.add(id);
      customerDoc.update({'serviceId': id});
    }
    return servicesId;
  }

  Future<void> _deleteCustomersService(
      List<int> customersId, List<int> servicesId) async {
    var customerRef = FirebaseFirestore.instance.collection('Customer');
    // remove service id from each customer, and get that id
    for (var customerId in customersId) {
      var docRef = await customerRef.doc(customerId.toString());
      docRef.update({
        'serviceId': 0,
      });
    }
    var serviceRef = FirebaseFirestore.instance.collection('service');
    // remove service from firebase
    for (var serviceId in servicesId) {
      var docRef = await serviceRef.doc(serviceId.toString());
      docRef.delete();
    }
  }

  Future<void> _updateOrderLock(bool isLocked) async {
    var currentSupplier = supplierStream.valueOrNull;
    if (currentSupplier == null || currentSupplier.orderId == 0) return;
    await FirebaseFirestore.instance
        .collection('order')
        .doc(currentSupplier.orderId.toString())
        .update({
      'isLocked': isLocked,
    });
  }

  _validateOrder(
    List<int> customersIds,
    List<int> customersDemandMin,
    List<int> customersDemandMax,
    List<int> vehiclesCapacity,
    List<int> driversIds,
  ) {
    var results = [
      customersIds.length == 0 ? 'Please select at least one customer' : null,
      !_checkRangeValid(customersDemandMin, customersDemandMax)
          ? 'Minimum demand must be less than maximum demand'
          : null,
      driversIds.length == 0 ? 'Please select at least one driver' : null,
      vehiclesCapacity.length == 0 ? 'Please add at least one vehicle' : null,
      vehiclesCapacity.length != driversIds.length
          ? 'Number of vehicles must be equal to number of drivers'
          : null,
      customersDemandMax.contains(0)
          ? 'Please enter demand for each customer, demand must be greater than zero'
          : null,
      vehiclesCapacity.contains(0)
          ? 'Please enter capacity for each vehicle, capacity must be greater than zero'
          : null,
      customersIds.length != customersDemandMin.length
          ? 'Please enter demand for each customer'
          : null,
    ];
    var res =
        results.firstWhere((element) => element != null, orElse: () => null);
    return res;
  }

  _validateOrderUpdate(
    List<int> customersIds,
    List<int> customersDemandMin,
    List<int> customersDemandMax,
  ) {
    var results = [
      !_checkRangeValid(customersDemandMin, customersDemandMax)
          ? 'Minimum demand must be less than maximum demand'
          : null,
      customersDemandMax.contains(0)
          ? 'Please enter demand for each customer, demand must be greater than zero'
          : null,
      customersIds.length != customersDemandMin.length
          ? 'Please enter demand for each customer'
          : null,
    ];
    var res =
        results.firstWhere((element) => element != null, orElse: () => null);
    return res;
  }

  _checkRangeValid(List<int> customersDemandMin, List<int> customersDemandMax) {
    for (int i = 0; i < customersDemandMin.length; i++) {
      if (customersDemandMin[i] > customersDemandMax[i]) return false;
    }
    return true;
  }

  _loadSupplier(UserModel? user) async {
    if (user == null) {
      _supplierSubject.add(Supplier.empty());
      return;
    }
    var supplier = await getSupplier(user.id);
    _supplierSubject.add(supplier);
  }

  _loadOrder() async {
    var order = _orderStream.valueOrNull;
    // if orderTrip is loaded already return
    if (order != null && order.id != 0) return;
    // if supplier is not logged in
    if (supplierStream.valueOrNull == null) {
      _orderSubject.add(OrderModel.empty());
      return;
    }
    // check if the supplier has an orderTrip
    var orderId = supplierStream.valueOrNull?.orderId ?? 0;
    if (orderId == 0) {
      _orderSubject.add(OrderModel.empty());
      return;
    }
    order = await getOrder(orderId);
    _orderSubject.add(order);
  }

  _loadOrderFullData() async {
    _orderFullDataSubject.add(null);
    // if supplier is not logged in
    if (supplierStream.valueOrNull == null) {
      _orderFullDataSubject.add(OrderModelFullData.empty());
      return;
    }
    // check if the supplier has an orderTrip
    var orderId = supplierStream.valueOrNull?.orderId ?? 0;
    if (orderId == 0) {
      _orderFullDataSubject.add(OrderModelFullData.empty());
      return;
    }
    var orderFullData = await getOrderFullData(orderId);
    var customersServicesId =
        orderFullData.servicesId.sublist(0, orderFullData.customersId.length);
    orderFullData.isServicesLocked =
        await getIsServicesLocked(customersServicesId);
    _orderFullDataSubject.add(orderFullData);
  }

  _loadServices() async {
    var services = _servicesStream.valueOrNull;
    // if orders is loaded already return
    if (services != null && services.isNotEmpty) return;
    // if supplier is not logged in
    if (supplierStream.valueOrNull == null) {
      _services.add([]);
      return;
    }
    // check if the order trip has loaded
    if (_orderStream.valueOrNull == null) await _loadOrder();
    var orderTrip = _orderStream.value!;
    // check if the supplier has an orderTrip
    if (orderTrip.id == 0) {
      _services.add([]);
      return;
    }
    services = await _getServices(orderTrip.servicesId);
    _services.add(services);
  }

  _getServices(List<int> servicesId) async {
    var services = <ServiceModel>[];
    var ref = FirebaseFirestore.instance.collection('service');
    for (var serviceId in servicesId) {
      var service = await getServiceFromReference(serviceId, ref);
      services.add(service);
    }
    return services;
  }

  _loadDriversTrackingModel() async {
    var supplier = supplierStream.valueOrNull;
    if (supplier == null || supplier.id == 0) {
      _driverTrackingModelSubject.add([]);
      return;
    }
    if (_driverTrackingModelSubject.valueOrNull != null) return;
    await _loadOrder();
    var driversId = _orderStream.valueOrNull?.driversId ?? [];
    if (driversId.isEmpty) {
      _driverTrackingModelSubject.add([]);
      return;
    }
    var driversTrackingModel = <DriverTrackingModel>[];
    var driverCollectionRef = FirebaseFirestore.instance.collection('Driver');
    var serviceCollectionRef = FirebaseFirestore.instance.collection('service');
    var customerCollectionRef = FirebaseFirestore.instance.collection('Customer');

    for (var driverId in driversId) {
      var driverTrackingModel = await _loadDriverTrackingModel(
        driverId,
        supplier,
        driverCollectionRef,
        serviceCollectionRef,
        customerCollectionRef,
      );
      driversTrackingModel.add(driverTrackingModel);
    }

    _driverTrackingModelSubject.add(driversTrackingModel);
  }

  _loadDriverTrackingModel(
    int driverId,
    Supplier supplier,
    CollectionReference<Map<String, dynamic>> driverCollectionRef,
    CollectionReference<Map<String, dynamic>> serviceCollectionRef,
    CollectionReference<Map<String, dynamic>> customerCollectionRef,
  ) async {
    var driverDoc = await driverCollectionRef.doc(driverId.toString()).get();
    var servicesId = driverDoc['servicesId'].cast<int>();
    var customersName = <String>[];
    var demands = <int>[];
    var expectedArrivalTime = "";
    var locationName = "";
    var latitude = 0.0;
    var longitude = 0.0;

    var currentServiceIndex =
        driverDoc['totalServices'] - driverDoc['remainingServices'];
    var currentServiceId =
        servicesId.length == 0 ? 0 : servicesId[currentServiceIndex];

    for (var serviceId in servicesId) {
      if(serviceId == 0){
        customersName.add('End Point');
        demands.add(0);
        continue;
      }
      var serviceDoc =
          await serviceCollectionRef.doc(serviceId.toString()).get();
      var customerId = serviceDoc['customerId'];
      var customerName = supplier.myCustomersId.firstWhere(
          (element) => element.contains('#$customerId'),
          orElse: () => '');
      var demand = serviceDoc['demand'];

      if (serviceId == currentServiceId) {
        expectedArrivalTime = serviceDoc['expectedArrivalTime'];
        locationName = serviceDoc['locationName'];
        var customerDoc =
            await customerCollectionRef.doc(customerId.toString()).get();
        latitude = customerDoc['latitude']*1.0;
        longitude = customerDoc['longitude']*1.0;
      }

      customersName.add(customerName);
      demands.add(demand);
    }

    var driverName = "${driverDoc['name']}#${driverId}";
    var driverPhoneNumber = driverDoc['phoneNumber'];

    var driverTrackingModel = DriverTrackingModel(
      driverId: driverId,
      driverName: driverName,
      driverPhoneNumber: driverPhoneNumber,
      servicesId: servicesId,
      customersName: customersName,
      demands: demands,
      currentServiceIndex: currentServiceIndex,
      customerLatitude: latitude,
      customerLongitude: longitude,
      expectedArrivalTime: expectedArrivalTime,
      locationName: locationName,
    );
    return driverTrackingModel;
  }
}
