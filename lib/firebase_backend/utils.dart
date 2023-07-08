import 'dart:core';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_login_architecture/model.dart';


final RegExp PASSWORD_PATTERN =
RegExp(r"(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*\W)(.*)");
final RegExp EMAIL_PATTERN = RegExp(r"\w+([.]\w+)?@(\w+(-\w+)?[.])+\w+");
final RegExp PHONE_NUMBER_PATTERN = RegExp(r"[0-9]{12}");


class RequestResponse {
  final RequestResponseType type;
  final String message;

  RequestResponse(this.type, this.message);

  RequestResponse.success(this.message) : type = RequestResponseType.SUCCESS;

  RequestResponse.failure(this.message) : type = RequestResponseType.FAILURE;
}

enum RequestResponseType { SUCCESS, FAILURE() }


DatabaseReference getDriverLiveLocationFromFirebase(int driverId) {
  return FirebaseDatabase.instance.ref(driverId.toString());
}

String castRoleTypeToTableString(RoleType role) {
  if (role == RoleType.CUSTOMER) return 'Customer';
  if (role == RoleType.DRIVER) return 'Driver';
  return 'Supplier';
}

Future<UserModel> getUserModel(int id, RoleType type) async {
  var tableName = castRoleTypeToTableString(type);
  DocumentSnapshot snapshot =
  await FirebaseFirestore.instance.collection(tableName).doc(id.toString()).get();
  return UserModel(
    id: id,
    name: snapshot['name'],
    email: snapshot['email'],
    phoneNumber: snapshot['phoneNumber'],
    roleType: type,
  );
}

Future<Customer> getCustomer(int customerId) async {
  DocumentSnapshot snapshot =
  await FirebaseFirestore.instance.collection('Customer').doc(customerId.toString()).get();
  return Customer(
    serviceId: snapshot['serviceId'],
    latitude: snapshot['latitude'] * 1.0,
    longitude: snapshot['longitude'] * 1.0,
    locationName: snapshot['locationName'],
    id: customerId,
    name: snapshot['name'],
    email: snapshot['email'],
    phoneNumber: snapshot['phoneNumber'],
    roleType: RoleType.CUSTOMER,
  );
}

Future<Driver> getDriver(int driverId) async {
  DocumentSnapshot snapshot =
  await FirebaseFirestore.instance.collection('Driver').doc(driverId.toString()).get();

  var servicesId = snapshot['servicesId'];
  var totalServices = snapshot['totalServices'];
  var remainingServices = snapshot['remainingServices'];

  if (servicesId.length == 0) servicesId = <int>[];

  var currentServiceId = servicesId.length == 0 ? 0 : servicesId[totalServices-remainingServices];

  var driver = Driver(
    orderId: snapshot['orderId'],
    serviceId: currentServiceId,
    remainingServices: remainingServices,
    totalServices: totalServices,
    carLicense: snapshot['carLicense'],
    carColor: snapshot['carColor'],
    id: driverId,
    name: snapshot['name'],
    email: snapshot['email'],
    phoneNumber: snapshot['phoneNumber'],
    roleType: RoleType.DRIVER,
  );
  return driver;
}

Future<Supplier> getSupplier(int supplierId) async {
  DocumentSnapshot snapshot =
  await FirebaseFirestore.instance.collection('Supplier').doc(supplierId.toString()).get();
  return Supplier(
    orderId: snapshot['orderId'],
    myCustomersId: snapshot['myCustomersId'].cast<String>(),
    myDriversId: snapshot['myDriversId'].cast<String>(),
    latitude: snapshot['latitude'] * 1.0,
    longitude: snapshot['longitude'] * 1.0,
    id: supplierId,
    name: snapshot['name'],
    email: snapshot['email'],
    phoneNumber: snapshot['phoneNumber'],
    roleType: RoleType.SUPPLIER,
  );
}

Future<ServiceModel> getService(int serviceId) async {
  var ref = await FirebaseFirestore.instance.collection('service');
  return await getServiceFromReference(serviceId, ref);
}

Future<ServiceModel> getServiceFromReference(
    int serviceId,
    CollectionReference<Map<String, dynamic>> ref,
    ) async {
  DocumentSnapshot snapshot = await ref.doc(serviceId.toString()).get();
  return ServiceModel(
    id: serviceId,
    demand: snapshot['demand'],
    locationName: snapshot['locationName'],
    expectedArrivalTime: snapshot['expectedArrivalTime'],
    customerId: snapshot['customerId'],
    driverId: snapshot['driverId'],
    isLocked: snapshot['isLocked'],
    isDelivered: snapshot['isDelivered'],
  );
}

Future<OrderModel> getOrder(int orderTripId) async {
  DocumentSnapshot snapshot = await FirebaseFirestore.instance
      .collection('order')
      .doc(orderTripId.toString())
      .get();
  return OrderModel(
    id: orderTripId,
    numberOfServices: snapshot['numberOfServices'],
    servicesId: snapshot['servicesId'].cast<int>(),
    numberOfVehicles: snapshot['numberOfVehicles'],
    vehiclesCapacity: snapshot['vehiclesCapacity'].cast<int>(),
    driversId: snapshot['driversId'].cast<int>(),
  );
}

Future<OrderModelFullData> getOrderFullData(int orderTripId) async {
  DocumentSnapshot snapshot = await FirebaseFirestore.instance
      .collection('order')
      .doc(orderTripId.toString())
      .get();
  return OrderModelFullData(
    id: orderTripId,
    numberOfServices: snapshot['numberOfServices'],
    numberOfVehicles: snapshot['numberOfVehicles'],
    customersId: snapshot['customersId'].cast<int>(),
    isServicesLocked: <bool>[],
    newCustomersId: snapshot['newCustomersId'].cast<int>(),
    deletedCustomersId: snapshot['deletedCustomersId'].cast<int>(),
    driversId: snapshot['driversId'].cast<int>(),
    maxDemands: snapshot['maxDemands'].cast<int>(),
    minDemands: snapshot['minDemands'].cast<int>(),
    newMaxDemands: snapshot['newMaxDemands'].cast<int>(),
    newMinDemands: snapshot['newMinDemands'].cast<int>(),
    vehiclesCapacity: snapshot['vehiclesCapacity'].cast<int>(),
    servicesId: snapshot['servicesId'].cast<int>(),
    isLocked: snapshot['isLocked'],
  );
}

Future<List<bool>> getIsServicesLocked(List<int> servicesId) async {
  var ref = await FirebaseFirestore.instance.collection('service');
  var isLocked = <bool>[];
  for (var serviceId in servicesId) {
    var serviceRef = await ref.doc(serviceId.toString()).get();
    isLocked.add(serviceRef['isLocked']);
  }
  return isLocked;
}

Future<int> addServiceToReference(
    Map<String, dynamic> serviceData,
    CollectionReference<Map<String, dynamic>> ref,
    ) async {
  var id = await IncrementCountAndGet('service');
  await ref.doc(id.toString()).set(serviceData);
  return id;
}

Future<int> IncrementCountAndGet(String countFieldName) async {
  var ref =
  await FirebaseFirestore.instance.collection('counters').doc('counters');
  var res = await ref.get();
  var count = res[countFieldName] + 1;
  ref.update({countFieldName: count});
  return count;
}

String? validateUserName(String userName) {
  if (userName.isEmpty)
    return "user name required";
  else if (userName.length < 8)
    return "user name must be at least 8 characters";
  else
    return null;
}

String? validatePassword(String password) {
  if (password.isEmpty)
    return "password required";
  else if (password.length < 8)
    return "password must be at least 8 characters";
  else if (!PASSWORD_PATTERN.hasMatch(password))
    return "password must contain at least one uppercase letter, one lowercase letter, one number and one special character";
  else
    return null;
}

String? validateEmail(String email) {
  if (email.isEmpty)
    return "email required";
  else if (!EMAIL_PATTERN.hasMatch(email))
    return "email is not valid";
  else
    return null;
}

String? validatePhoneNumber(String phoneNumber) {
  if (phoneNumber.isEmpty)
    return "phone number required";
  else if (!PHONE_NUMBER_PATTERN.hasMatch(phoneNumber))
    return "phone number is not valid";
  else
    return null;
}
