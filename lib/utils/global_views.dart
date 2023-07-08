import 'package:flutter/material.dart';
import 'package:flutter_login_architecture/authentication/login_page.dart';
import 'package:provider/provider.dart';

import '../firebase_backend/authentication_services.dart';

AppBar dashboardAppBar(BuildContext context, String title) {
  return AppBar(
    title: Text(title),
    actions: [
      IconButton(
        icon: Icon(Icons.logout),
        onPressed: () {
          context.read<AuthenticationService>().signOut();
          Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => LoginPage()));
        },
      ),
    ],
  );
}

Widget noDriverWidget() {
  return Center(
    child: Text(
      'you have no driver yet',
    ),
  );
}

Widget noOrderWidget() {
  return Center(
    child: Text(
      'you have no order yet',
    ),
  );
}

Widget orderDeliveredCustomer() {
  return Center(
    child: Text(
      'your order has been delivered to you successfully',
    ),
  );
}

Widget orderDeliveredDriver() {
  return Center(
    child: Text(
      'you have delivered the order to the customer successfully',
    ),
  );
}

Widget loadingScreen() {
  return Center(
    child: CircularProgressIndicator(
      color: Colors.blue,
    ),
  );
}

showErrorSnackBarMessage(BuildContext context, String content) {
  return showSnackBarMessage(context, content, Colors.red);
}

showSnackBarMessage(BuildContext context, String content, Color color) {
  ScaffoldMessenger.of(context).clearSnackBars();
  return ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(content),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
    ),
  );
}
