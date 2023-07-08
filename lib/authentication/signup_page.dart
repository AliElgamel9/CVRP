import 'dart:convert';
import 'dart:math';

import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_login_architecture/utils/loading_task.dart';
import 'package:flutter_login_architecture/maps_services/pick_location.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

import '../firebase_backend/authentication_services.dart';
import '../firebase_backend/utils.dart';
import '../model.dart';
import '../utils/global_views.dart';
import '../maps_services/pick_location_web.dart';
import 'login_page.dart';

class SignUpPage extends StatefulWidget {
  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  RoleType _selectedRole = RoleType.DRIVER;
  LatLng? _selectedLocation;
  String? _locationName;
  Color _carColor = Colors.green;

  final TextEditingController emailController = TextEditingController();
  final TextEditingController userNameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController phoneNumberController = TextEditingController();
  final TextEditingController carLicenseController = TextEditingController();
  var _isLoading = false;


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Sign up')),
      body: ProvideLoadingTask(
        isLoading: _isLoading,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  child: Image.asset('assets/images/app_logo.png'),
                  margin: EdgeInsets.only(bottom: 20),
                ),
                Text('Welcome, glade to have you!'),
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(labelText: 'Email'),
                ),
                TextField(
                  controller: userNameController,
                  decoration: InputDecoration(labelText: 'User Name'),
                ),
                TextField(
                  controller: passwordController,
                  decoration: InputDecoration(labelText: 'Password'),
                  obscureText: true,
                  enableSuggestions: false,
                  autocorrect: false,
                ),
                TextField(
                  controller: phoneNumberController,
                  decoration: InputDecoration(
                      labelText: 'phone number ex) 201114649310'),
                ),
                SizedBox(height: 10),
                if (_selectedRole == RoleType.SUPPLIER ||
                    _selectedRole == RoleType.CUSTOMER)
                  Row(
                    children: [
                      if (_selectedLocation != null) Text('$_locationName'),
                      SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () => _pickLocation(),
                        child: Text('Pick Location'),
                      )
                    ],
                  ),
                if (_selectedRole == RoleType.DRIVER)
                  Column(
                    children: [
                      TextField(
                        controller: carLicenseController,
                        decoration:
                            InputDecoration(labelText: 'Car License Plate'),
                      ),
                      SizedBox(width: 10),
                      Row(
                        children: [
                          Text('Car Color'),
                          SizedBox(width: 10),
                          OutlinedButton(
                            onPressed: () => _showColorPickerDialog(context),
                            style: OutlinedButton.styleFrom(
                              fixedSize: Size(32, 32),
                              minimumSize: Size(32, 32),
                              backgroundColor: _carColor,
                            ),
                            child: null,
                          ),
                        ],
                      ),
                    ],
                  ),
                DropdownButtonFormField2<RoleType>(
                  decoration: InputDecoration(labelText: 'Role Type'),
                  iconStyleData:
                      IconStyleData(icon: const Icon(Icons.arrow_drop_down)),
                  value: _selectedRole,
                  items: RoleType.values.map((role) {
                    return DropdownMenuItem<RoleType>(
                      value: role,
                      child: Text(role.name),
                    );
                  }).toList(),
                  onChanged: (RoleType? newValue) {
                    setState(() {
                      if (newValue != null) _selectedRole = newValue;
                    });
                  },
                ),
                Container(
                  child: ElevatedButton(
                    onPressed: () => handleSignUp(),
                    child: Text('Sign up'),
                  ),
                  margin: EdgeInsets.only(top: 10),
                ),
                TextButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (context) => LoginPage()));
                    },
                    child: Text('Already registered? Sign in')),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showColorPickerDialog(BuildContext context) {
    Color selectedColor = _carColor;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select a color'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: selectedColor,
              onColorChanged: (color) =>
                setState(() => selectedColor = color),
              pickerAreaHeightPercent: 0.8,
            ),
          ),
          actions: [
            ElevatedButton(
              child: const Text('OK'),
              onPressed: () {
                setState(() => _carColor = selectedColor);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  _pickLocation() async {
    LatLng? receivedResult = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) {
            if(kIsWeb) return PickLocationWeb(initialLocation: _selectedLocation);
            return PickLocation(initialLocation: _selectedLocation);
          }),
    );
    if(receivedResult == null) return;

    var locationName = 'unknown';
    if(kIsWeb)
      locationName = await _getLocationNameForWeb(receivedResult);
    else
      locationName = await _getLocationName(receivedResult);

    locationName = locationName.substring(0, min(locationName.length, 50));

    setState(() {
      _locationName = locationName;
      _selectedLocation = receivedResult;
    });
  }

  Future<String> _getLocationName(LatLng location) async {
    List<Placemark> placeMarks = await placemarkFromCoordinates(
      location.latitude,
      location.longitude,
    );
    if (placeMarks.isNotEmpty)
      return placeMarks.first.street ?? placeMarks.first.name!;
    return 'unknown';
  }
  
  Future<String> _getLocationNameForWeb(LatLng location) async {
    var api = Uri.parse('http://dev.virtualearth.net/REST/v1/Locations/${location.latitude},${location.longitude}?key=Ahgy2ECRAum11hzsnfaSr28NcoZi-9Oz1ArAKmwAbpC9SfaTkz0mq57ZYek5Ssyk');
    var response = await http.get(api);
    var data = jsonDecode(response.body);

    if (data['statusDescription'] == 'OK') 
      return data['resourceSets'][0]['resources'][0]['address']['formattedAddress'];
    return 'unknown';
  }

  handleSignUp() async {
    setState(() => _isLoading = true);
    showSnackBarMessage(context, 'signing up...', Colors.blue);
    var res = await context.read<AuthenticationService>().signUp(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
          name: userNameController.text.trim(),
          phoneNumber: phoneNumberController.text.trim(),
          role: _selectedRole,
          location: _selectedLocation,
          locationName: _locationName,
          carLicense: carLicenseController.text.trim(),
          carColor: _carColor.value,
        );
    setState(() => _isLoading = false);
    var msgColor = Colors.red;
    if (res.type == RequestResponseType.SUCCESS) {
      msgColor = Colors.blue;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => LoginPage(),
        ),
      );
    }
    showSnackBarMessage(context, res.message, msgColor);
  }
}
