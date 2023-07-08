import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';


addData({
  required int customersCount,
  required int driversCount,
  required int suppliersCount,
}) async {
  await addCustomers(customersCount);
  await addDrivers(driversCount);
  await addSuppliers(suppliersCount);
}

addCustomers(int count, {int start = 0}) async {
  // names with length greater than 8
  var names = [
    'John',
    'Doe',
    'Jane',
    'Smith',
    'James',
    'Brown',
    'Robert',
    'Wilson',
    'David',
    'Taylor',
    'Richard',
    'Anderson',
    'Thomas'
  ];
  var latitude = [
    29.9976,
    29.9862,
    29.9970,
    29.9859,
    29.9991,
    29.9842,
    29.9799
  ];
  var longitude = [31.1704, 31.1634, 31.1566, 31.1523, 31.1702, 31.1722];

  var collection = FirebaseFirestore.instance.collection('Customer');
  for (int i = start; i < start + count; i++) {
    var latlng = LatLng(latitude[Random().nextInt(latitude.length)],
        longitude[Random().nextInt(longitude.length)]);
    var locationName = await _pickLocation(latlng);
    locationName = locationName.substring(0, min(locationName.length, 50));
    var name = names[Random().nextInt(names.length)] +
        names[Random().nextInt(names.length)];
    var data = {
      'id': i + 1,
      'name': name,
      'email': (name + "@gmail.com").toLowerCase(),
      'phoneNumber': '201014623848',
      'password': '1234',
      'serviceId': 0,
      'latitude': latlng.latitude,
      'longitude': latlng.longitude,
      'locationName': locationName,
    };
    collection.doc((i + 1).toString()).set(data);
  }
}

addDrivers(int count, {int start = 0}) {
  // names looks to driver name with length greater than 8
  var names = [
    'John',
    'Doe',
    'Jane',
    'Smith',
    'James',
    'Brown',
    'Robert',
    'Wilson',
    'David',
    'Taylor',
    'Richard',
    'Anderson',
    'Thomas'
  ];
  var carLicenses = [
    '123456',
    '654321',
    '123654',
    '654123',
    '321654',
    '321456',
    '456321',
    '456123'
  ];
  var carColorValues = [
    Colors.red.value,
    Colors.blue.value,
    Colors.green.value,
    Colors.yellow.value,
    Colors.purple.value,
    Colors.orange.value,
    Colors.pink.value,
    Colors.teal.value
  ];
  var collection = FirebaseFirestore.instance.collection('Driver');

  for (int i = start; i < start + count; i++) {
    var name = names[Random().nextInt(names.length)] +
        names[Random().nextInt(names.length)];
    var data = {
      'id': i + 1,
      'name': name,
      'email': (name + "@gmail.com").toLowerCase(),
      'phoneNumber': '201014623848',
      'password': '1234',
      'servicesId': <int>[],
      'remainingServices': 0,
      'totalServices': 0,
      'carLicense': carLicenses[Random().nextInt(carLicenses.length)],
      'carColor': carColorValues[Random().nextInt(carColorValues.length)],
    };
    collection.doc((i + 1).toString()).set(data);
  }
}

addSuppliers(int count, {int start = 0}) {
  // names with length greater than 8
  var names = [
    'John',
    'Doe',
    'Jane',
    'Smith',
    'James',
    'Brown',
    'Robert',
    'Wilson',
    'David',
    'Taylor',
    'Richard',
    'Anderson',
    'Thomas'
  ];
  var latitude = [
    29.9976,
    29.9862,
    29.9970,
    29.9859,
    29.9991,
    29.9842,
    29.9799
  ];
  var longitude = [31.1704, 31.1634, 31.1566, 31.1523, 31.1702, 31.1722];

  var collection = FirebaseFirestore.instance.collection('Supplier');
  for (int i = start; i < start + count; i++) {
    var name = names[Random().nextInt(names.length)] +
        names[Random().nextInt(names.length)];
    var latlng = LatLng(latitude[Random().nextInt(latitude.length)],
        longitude[Random().nextInt(longitude.length)]);
    var data = {
      'id': i + 1,
      'name': name,
      'email': (name + "@gmail.com").toLowerCase(),
      'phoneNumber': '201014623848',
      'password': '1234',
      'orderId': 0,
      'latitude': latlng.latitude,
      'longitude': latlng.longitude,
      'myCustomersId': <String>[],
      'myDriversId': <String>[],
    };
    collection.doc((i + 1).toString()).set(data);
  }
}

clearFirebase() async {
  await clearCollection('Customer');
  await clearCollection('Driver');
  await clearCollection('Supplier');
  await clearCollection('order');
  await clearCollection('service');
  await FirebaseFirestore.instance
      .collection('counters')
      .doc('counters')
      .update({
    'customer': 0,
    'driver': 0,
    'supplier': 0,
    'order': 0,
    'service': 0,
  });
}

clearCollection(String collectionName) async {
  await FirebaseFirestore.instance
      .collection(collectionName)
      .get()
      .then((snapshot) {
    for (DocumentSnapshot ds in snapshot.docs) {
      ds.reference.delete();
    }
  });
}

Future<String> _pickLocation(LatLng latlng) async {
  if(kIsWeb)
    return await _getLocationNameForWeb(latlng);
  List<Placemark> placemarks = await placemarkFromCoordinates(
    latlng.latitude,
    latlng.longitude,
  );
  var locationName = 'unknown';
  if (placemarks.isNotEmpty) {
    locationName = placemarks.first.name ?? 'unknown';
  }
  return locationName;
}

Future<String> _getLocationNameForWeb(LatLng location) async {
  var api = Uri.parse('http://dev.virtualearth.net/REST/v1/Locations/${location.latitude},${location.longitude}?key=Ahgy2ECRAum11hzsnfaSr28NcoZi-9Oz1ArAKmwAbpC9SfaTkz0mq57ZYek5Ssyk');
  var response = await http.get(api);
  var data = jsonDecode(response.body);

  if (data['statusDescription'] == 'OK')
    return data['resourceSets'][0]['resources'][0]['address']['formattedAddress'];
  return 'unknown';
}
