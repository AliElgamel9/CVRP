import 'dart:core';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_login_architecture/firebase_backend/utils.dart';
import 'package:flutter_login_architecture/model.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';


class AuthenticationService {
  final _userModelSubject = BehaviorSubject<UserModel?>();

  ValueStream<UserModel?> get userModelStream => _userModelSubject.stream;

  signOut() {
    SharedPreferences.getInstance()
        .then((value) {
        value.setString("email", "");
        value.setString("password", "");
      });
    _userModelSubject.add(null);
  }

  Future<RequestResponse> signIn({
    required String email,
    required String password,
    required RoleType role,
  }) async {
    email = email.toLowerCase();
    var docId = await _getUserDocumentId(email, role);
    if (docId == null)
      return RequestResponse.failure('user name or password is incorrect!');
    var userModel = await getUserModel(int.parse(docId), role);
    if (!(await checkPassword(docId, role, password)))
      return RequestResponse.failure('user name or password is incorrect!');
    _userModelSubject.add(userModel);
    return RequestResponse.success('signed in successfully!');
  }

  Future<RequestResponse> signUp({
    required String email,
    required String password,
    required String name,
    required String phoneNumber,
    required RoleType role,
    LatLng? location,
    String? locationName,
    String? carLicense,
    int? carColor,
  }) async {
    email = email.toLowerCase();
    var res = validation(email, password, name, phoneNumber);
    if (res != null) return res;

    if ((role == RoleType.SUPPLIER || role == RoleType.CUSTOMER) &&
        location == null)
      return RequestResponse.failure('please select your location');

    if(role == RoleType.DRIVER){
      if(carLicense == null || carLicense.isEmpty)
        return RequestResponse.failure('please enter your car license');
      if(carColor == null)
        return RequestResponse.failure('please select your car color');
    }

    var docId = await _getUserDocumentId(email, role);
    if (docId != null) return RequestResponse.failure('user already exists!');

    var countFieldName;
    if (role == RoleType.CUSTOMER)
      countFieldName = 'customer';
    else if (role == RoleType.DRIVER)
      countFieldName = 'driver';
    else
      countFieldName = 'supplier';
    int id = await IncrementCountAndGet(countFieldName);

    var data = <String, dynamic>{
      'name': name,
      'password': password,
      'phoneNumber': phoneNumber,
      'email': email,
    };
    if (role == RoleType.CUSTOMER)
      data.addAll({
        'serviceId': 0,
        'latitude': location!.latitude,
        'longitude': location.longitude,
        'locationName': locationName!
      });
    else if (role == RoleType.DRIVER)
      data.addAll({
        'orderId': 0,
        'servicesId': <int>[],
        'remainingServices': 0,
        'totalServices': 0,
        'carLicense': carLicense!,
        'carColor': carColor!,
      });
    else
      data.addAll({
        'orderId': 0,
        'latitude': location!.latitude,
        'longitude': location.longitude,
        'myCustomersId': <String>[],
        'myDriversId': <String>[]
      });

    var tableName = castRoleTypeToTableString(role);
    await FirebaseFirestore.instance
        .collection(tableName)
        .doc(id.toString())
        .set(data);
    return RequestResponse.success("signed up successfully!");
  }

  Future<bool> checkPassword(String id, RoleType type, String password) async {
    var tableName = castRoleTypeToTableString(type);
    var res =
        await FirebaseFirestore.instance.collection(tableName).doc(id).get();
    return res['password'] == password;
  }

  Future<String?> _getUserDocumentId(String email, RoleType type) async {
    var tableName = castRoleTypeToTableString(type);
    var res = await FirebaseFirestore.instance
        .collection(tableName)
        .where('email', isEqualTo: email)
        .limit(1)
        .get();
    if (res.size == 0) return null;
    return res.docs[0].id;
  }

  RequestResponse? validation(
      String email, String password, String name, String phoneNumber) {
    var results = [
      validateEmail(email),
      validatePassword(password),
      validateUserName(name),
      validatePhoneNumber(phoneNumber),
    ];
    var res =
        results.firstWhere((element) => element != null, orElse: () => null);
    if (res != null) return RequestResponse.failure(res);
    return null;
  }
}