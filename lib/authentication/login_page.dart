import 'dart:async';

import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_login_architecture/authentication/signup_page.dart';
import 'package:flutter_login_architecture/customer/customer_dashboard.dart';
import 'package:flutter_login_architecture/supplier/supplier_dashboard.dart';
import 'package:flutter_login_architecture/utils/global_views.dart';
import 'package:flutter_login_architecture/utils/loading_task.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../driver/driver_dashboard.dart';
import '../firebase_backend/authentication_services.dart';
import '../firebase_backend/customer_service.dart';
import '../firebase_backend/driver_service.dart';
import '../firebase_backend/supplier_service.dart';
import '../firebase_backend/utils.dart';
import '../model.dart';
import '../utils/firebase_helper.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  RoleType _selectedRole = RoleType.DRIVER;

  late AuthenticationService auth;
  UserModel? user;
  StreamSubscription<UserModel?>? subscription = null;
  var _isLoading = false;
  var _isAutoLogin = false;
  var currentPassword = "";

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    auth = context.read<AuthenticationService>();
    subscription = auth.userModelStream.listen((event) async {
      user = event;
      await _saveAuth();
      _startLogin();
    });
    _checkCredentials();
  }

  @override
  void dispose() {
    super.dispose();
    subscription?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Sign in')),
      body: ProvideLoadingTask(
        isLoading: _isLoading,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                child: Image.asset('assets/images/app_logo.png'),
                margin: EdgeInsets.only(bottom: 20),
              ),
              Text('Welcome back!'),
              TextField(
                controller: emailController,
                decoration: InputDecoration(labelText: 'Email'),
              ),
              TextField(
                controller: passwordController,
                decoration: InputDecoration(labelText: 'Password'),
                obscureText: true,
                enableSuggestions: false,
                autocorrect: false,
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
                  onPressed: () => handleLogin(context),
                  child: Text('Sign in'),
                ),
                margin: EdgeInsets.only(top: 10),
              ),
              TextButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (context) => SignUpPage()));
                  },
                  child: Text("Don't have an account? Sign up")),
            ],
          ),
        ),
      ),
    );
  }

  handleLogin(BuildContext context) async {
    // await clearFirebase();
    // await addData(
    //   customersCount: 30,
    //   driversCount: 10,
    //   suppliersCount: 5,
    // );
    setState(() => _isLoading = true);
    showSnackBarMessage(context, "logging in...", Colors.blue);
    currentPassword = passwordController.text.trim();
    var res = await context.read<AuthenticationService>().signIn(
          email: emailController.text.trim(),
          password: currentPassword,
          role: _selectedRole,
        );
    setState(() => _isLoading = false);
    if (res.type == RequestResponseType.FAILURE)
      showSnackBarMessage(context, res.message, Colors.red);
  }

  _checkCredentials() async {
    _isAutoLogin = true;
    var date = DateTime.now().millisecondsSinceEpoch;
    var pref = await SharedPreferences.getInstance();
    var diff = date - (pref.getDouble('last_time_login') ?? date);
    if (diff != 0 && diff < 3e8) {
      var email = await pref.getString('email')!;
      var password = await pref.getString('password')!;
      var roleTypeName = await pref.getString('role_type')!;

      var roleType;
      if (roleTypeName == 'customer')
        roleType = RoleType.CUSTOMER;
      else if (roleTypeName == 'driver')
        roleType = RoleType.DRIVER;
      else
        roleType = RoleType.SUPPLIER;

      var res = await auth.signIn(
        email: email,
        password: password,
        role: roleType,
      );
      if (res == RequestResponseType.FAILURE) _isAutoLogin = false;
    } else
      _isAutoLogin = false;
  }

  _saveAuth() async {
    var currentUser = user;
    if (currentUser == null) return;
    var pref = await SharedPreferences.getInstance();
    await pref.setInt("userId", currentUser.id);
    if (!_isAutoLogin) {
      await pref.setDouble(
          "last_time_login", DateTime.now().millisecondsSinceEpoch.toDouble());
      await pref.setString("email", currentUser.email);
      await pref.setString("password", currentPassword);
      if (currentUser.roleType == RoleType.CUSTOMER)
        await pref.setString("role_type", "customer");
      else if (currentUser.roleType == RoleType.DRIVER)
        await pref.setString("role_type", "driver");
      else if (currentUser.roleType == RoleType.SUPPLIER)
        await pref.setString("role_type", "supplier");
    }
  }

  _startLogin() {
    var currentUser = user;
    if (currentUser == null) return;
    switch (currentUser.roleType) {
      case RoleType.DRIVER:
        return _navigateToDriver();
      case RoleType.CUSTOMER:
        return _navigateToCustomer();
      case RoleType.SUPPLIER:
        return _navigateToSupplier();
    }
  }

  _navigateToDriver() {
    var driverService = DriverFirebaseService(auth);
    Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (context) => DriverDashboard(driverService)));
  }

  _navigateToCustomer() {
    var customerService = CustomerFirebaseService(auth);
    Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (context) => CustomerDashboard(customerService)));
  }

  _navigateToSupplier() {
    var supplierService = SupplierFirebaseService(auth);
    Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (context) => SupplierDashboard(supplierService)));
  }
}
