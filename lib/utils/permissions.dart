import 'package:flutter/cupertino.dart';
import 'package:flutter_login_architecture/utils/global_views.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';



Future<bool> requestLocationPermission(BuildContext context) async {
  var permission = await GeolocatorPlatform.instance.checkPermission();

  if (permission == LocationPermission.always ||
      permission == LocationPermission.whileInUse) return true;

  permission = await GeolocatorPlatform.instance.requestPermission();

  if (permission == LocationPermission.always ||
      permission == LocationPermission.whileInUse) return true;

  _onLocationPermissionDenied(context);
  openAppSettings();

  return false;
}

void _onLocationPermissionDenied(BuildContext context) {
  showErrorSnackBarMessage(context,
      "location permission need to be granted to track order in the map");
}
