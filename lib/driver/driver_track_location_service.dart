import 'dart:async';
import 'dart:math';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_login_architecture/utils/global_views.dart';
import 'package:flutter_login_architecture/utils/permissions.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';


class TrackDriverLocationService{

  late DatabaseReference locationRef;
  final driverId;

  var _driverPositionSubject = BehaviorSubject<Position>();
  ValueStream<Position> get driverPositionStream => _driverPositionSubject.stream;
  
  StreamSubscription<Position>? positionSubscription;
  Timer? timer;

  TrackDriverLocationService(this.driverId){
    locationRef = FirebaseDatabase.instance.ref(driverId);
  }

  startTracking(BuildContext context) async {
    if(!(await requestLocationPermission(context))) return;
    _observeLocationUpdates();
    timer = Timer.periodic(const Duration(seconds: 10), (timer) => _updateLocationOnFirebase());
  }

  cancelTracking(){
    positionSubscription?.cancel();
    timer?.cancel();
  }

  _updateLocationOnFirebase() {
    var position = driverPositionStream.valueOrNull;
    if(position == null) return;
    var v = Random().nextInt(100)*1e-9;
    locationRef.set({
      'latitude': position.latitude+v,
      'longitude': position.longitude+v,
    });
  }

  _observeLocationUpdates(){
    positionSubscription = GeolocatorPlatform.instance
        .getPositionStream()
        .listen((position) {
          print('ggggggggggggggggggggg');
          _driverPositionSubject.add(position);
    });
  }
}

void startAndroidLiveTrackingInBackground() async {
  if(kIsWeb) return;
  AndroidAlarmManager.initialize();
  await AndroidAlarmManager.periodic(
    Duration(seconds: 20),
    10,
    updateLocationOnFirebase,
    exact: true,
  );
}

void stopAndroidLiveTrackingInBackground() async {
  if(kIsWeb) return;
  await AndroidAlarmManager.cancel(10);
}

@pragma('vm:entry-point')
Future<void> updateLocationOnFirebase() async {
  PermissionStatus status = await Permission.location.request();
  if(!status.isGranted) return;
  final prefs = await SharedPreferences.getInstance();
  final driverId = prefs.getString("userId") ?? null;
  if(driverId == null) return;

  var locationRef = FirebaseDatabase.instance.ref(driverId);
  var currentPosition = await Geolocator.getCurrentPosition();
  var v = Random().nextInt(100)*1e-9;
  locationRef.update({
    'latitude': currentPosition.latitude+v,
    'longitude': currentPosition.longitude+v,
  });
}