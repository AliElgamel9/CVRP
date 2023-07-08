import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_login_architecture/supplier/utils.dart';
import 'package:flutter_login_architecture/utils/loading_task.dart';

import '../firebase_backend/supplier_service.dart';
import '../firebase_backend/utils.dart';
import '../model.dart';
import '../utils/global_views.dart';

class SupplierPlaceOrder extends StatefulWidget {
  final SupplierFirebaseService supplierFirebaseService;

  SupplierPlaceOrder(this.supplierFirebaseService);

  @override
  State<StatefulWidget> createState() =>
      _SupplierPlaceOrder(supplierFirebaseService);
}

class _SupplierPlaceOrder extends State {
  final SupplierFirebaseService supplierFirebaseService;
  StreamSubscription<Supplier?>? subscription = null;

  Supplier? supplier;
  List<String>? remainingCustomersId;
  List<String>? remainingDriversId;
  List<String> selectedCustomersId = [];
  List<String> selectedDriversId = [];
  int numberOfOrders = 0;
  int numberOfVehicles = 0;
  List<TextEditingController> customersDemandMin = [];
  List<TextEditingController> customersDemandMax = [];
  List<TextEditingController> vehiclesCapacity = [];
  var _isLoading = false;

  _SupplierPlaceOrder(this.supplierFirebaseService) {
    subscription = supplierFirebaseService.supplierStream.listen((event) {
      setState(() {
        supplier = event;
        if (supplier != null) _reset();
      });
    });
  }

  _reset() {
    remainingCustomersId = supplier!.myCustomersId.toList();
    remainingDriversId = supplier!.myDriversId.toList();
    numberOfOrders = 0;
    numberOfVehicles = 0;
    selectedCustomersId = [];
    customersDemandMin = [];
    customersDemandMax = [];
    vehiclesCapacity = [];
    selectedDriversId = [];
  }

  @override
  void dispose() {
    super.dispose();
    subscription?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    var currentSupplier = supplier;
    if (currentSupplier == null || currentSupplier.id == 0)
      return loadingScreen();
    if (currentSupplier.orderId != 0) return _onOrderExist(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Place Order'),
      ),
      body: ProvideLoadingTask(
        isLoading: _isLoading,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              twoHeadWidget(
                head1: 'Customer Id',
                head2: 'Customer Demand min-max',
              ),
              SizedBox(height: 18),
              customersInfoWidget(
                names: itemsNameWidget(
                  names: selectedCustomersId,
                  onSelect: _showUnselectCustomer,
                  encodeName: shortenName,
                ),
                minDemand: getInputControllerWidget(customersDemandMin),
                maxDemand: getInputControllerWidget(customersDemandMax),
              ),
              ElevatedButton.icon(
                onPressed: _showSelectCustomerDialog,
                icon: Icon(Icons.add),
                label: Text('Add'),
              ),
              SizedBox(height: 18),
              vehiclesInfoWithHeaderWidget(
                names: itemsNameWidget(
                  names: List<String>.generate(
                      numberOfVehicles, (index) => "Vehicle ${index + 1}"),
                  onSelect: _showUnselectVehicle,
                ),
                capacity: getInputControllerWidget(vehiclesCapacity),
              ),
              ElevatedButton.icon(
                onPressed: _addVehicle,
                icon: Icon(Icons.add),
                label: Text('Add'),
              ),
              SizedBox(height: 18),
              driversInfoWithHeader(
                names: itemsNameWidget(
                  names: selectedDriversId,
                  onSelect: _showUnselectDriver,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _showSelectDriverDialog,
                icon: Icon(Icons.add),
                label: Text('Add'),
              ),
              SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: _placeOrder,
                    child: Text(
                      'Place Order',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _onOrderExist(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.onPrimary,
      appBar: AppBar(
        title: Text('Place Order'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'you can have at most one order at a time, wait until the current order is finished',
          ),
        ),
      ),
    );
  }

  _showSelectCustomerDialog() {
    showSelectItemDialog(
      context,
      title: 'Select Customer',
      msgOnEmpty: 'you have no remaining customers, please add more',
      list: remainingCustomersId!,
      selectFunction: _selectCustomer,
    );
  }

  _showSelectDriverDialog() {
    showSelectItemDialog(
      context,
      title: 'Select Driver',
      msgOnEmpty: 'you have no remaining drivers, please add more',
      list: remainingDriversId!,
      selectFunction: _selectDriver,
    );
  }

  _showUnselectCustomer(int index, String name) {
    showRemoveConfirmationDialog(
      context,
      title: 'Remove Order?',
      content: 'Are you sure you want to remove order of $name?',
      unselectFunction: () => _unselectCustomer(index),
    );
  }

  _showUnselectDriver(int index, String name) {
    showRemoveConfirmationDialog(
      context,
      title: 'Remove Driver?',
      content: 'Are you sure you want to remove $name?',
      unselectFunction: () => _unselectDriver(index),
    );
  }

  _showUnselectVehicle(int index, String name) {
    showRemoveConfirmationDialog(
      context,
      title: 'Remove Vehicle?',
      content: 'Are you sure you want to remove $name?',
      unselectFunction: () => _unselectVehicle(index),
    );
  }

  _selectCustomer(int index) {
    setState(() {
      selectedCustomersId.add(remainingCustomersId![index]);
      customersDemandMin.add(TextEditingController(text: '0'));
      customersDemandMax.add(TextEditingController(text: '0'));
      remainingCustomersId!.removeAt(index);
      numberOfOrders++;
    });
  }

  _unselectCustomer(int index) {
    setState(() {
      remainingCustomersId!.add(selectedCustomersId[index]);
      selectedCustomersId.removeAt(index);
      customersDemandMin.removeAt(index);
      customersDemandMax.removeAt(index);
      numberOfOrders--;
    });
  }

  _addVehicle() {
    setState(() {
      numberOfVehicles++;
      vehiclesCapacity.add(TextEditingController(text: '0'));
    });
  }

  _unselectVehicle(int index) {
    setState(() {
      numberOfVehicles--;
      vehiclesCapacity.removeAt(index);
    });
  }

  _selectDriver(int index) {
    setState(() {
      selectedDriversId.add(remainingDriversId![index]);
      remainingDriversId!.removeAt(index);
    });
  }

  _unselectDriver(int index) {
    setState(() {
      remainingDriversId!.add(selectedDriversId[index]);
      selectedDriversId.removeAt(index);
    });
  }

  _placeOrder() async {
    setState(() => _isLoading = true);
    var result = await supplierFirebaseService.placeOrder(
      customersId: selectedCustomersId
          .map((e) => int.parse(e.substring(e.indexOf('#') + 1)))
          .toList(),
      driversId: selectedDriversId
          .map((e) => int.parse(e.substring(e.indexOf('#') + 1)))
          .toList(),
      customersDemandMin:
          customersDemandMin.map((e) => int.parse(e.text)).toList(),
      customersDemandMax:
          customersDemandMax.map((e) => int.parse(e.text)).toList(),
      vehiclesCapacity: vehiclesCapacity.map((e) => int.parse(e.text)).toList(),
    );
    setState(() => _isLoading = false);
    if (result.type == RequestResponseType.SUCCESS) {
      showSnackBarMessage(context, result.message, Colors.blue);
      Navigator.of(context).pop();
    } else
      showSnackBarMessage(context, result.message, Colors.red);
  }
}