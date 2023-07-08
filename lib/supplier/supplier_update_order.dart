import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_login_architecture/supplier/utils.dart';
import 'package:flutter_login_architecture/utils/loading_task.dart';

import '../firebase_backend/supplier_service.dart';
import '../firebase_backend/utils.dart';
import '../model.dart';
import '../utils/global_views.dart';

class SupplierUpdateOrder extends StatefulWidget {
  final SupplierFirebaseService supplierFirebaseService;

  SupplierUpdateOrder(this.supplierFirebaseService);

  @override
  State<StatefulWidget> createState() =>
      _SupplierUpdateOrder(supplierFirebaseService);
}

class _SupplierUpdateOrder extends State {
  final SupplierFirebaseService supplierFirebaseService;
  StreamSubscription<Supplier?>? supplierSubscription = null;
  StreamSubscription<OrderModelFullData?>? orderModelFullDataSubscription =
      null;

  Supplier? supplier;
  OrderModelFullData? orderModelFullData;
  int numberOfOrders = 0;
  int numberOfVehicles = 0;
  List<String>? remainingCustomersId;
  List<String> selectedCustomersId = [];
  List<bool> isCustomersLocked = [];
  List<int> customersDemandMin = [];
  List<int> customersDemandMax = [];
  List<int> deletedCustomersId = [];
  List<String> newSelectedCustomersId = [];
  List<String> newCustomersDemandMin = [];
  List<String> newCustomersDemandMax = [];
  List<int> deletedNewCustomersId = [];
  List<bool> isAddRecently = [];

  List<TextEditingController> newCustomersDemandMinEditable = [];
  List<TextEditingController> newCustomersDemandMaxEditable = [];
  List<String> selectedDriversId = [];
  List<int> vehiclesCapacity = [];
  var isLocked = false;
  var _isLoading = false;

  _SupplierUpdateOrder(this.supplierFirebaseService) {
    supplierSubscription = supplierFirebaseService.supplierStream
        .listen((event) => supplier = event);
    orderModelFullDataSubscription =
        supplierFirebaseService.getOrderFullDataStream().listen((event) {
      setState(() {
        orderModelFullData = event;
        if (orderModelFullData != null) _reset();
      });
    });
  }

  _reset() {
    var data = orderModelFullData;
    if (data == null) return;

    isLocked = data.isLocked;
    if (!isLocked) supplierFirebaseService.lockOrder();

    numberOfOrders = data.numberOfServices;
    numberOfVehicles = data.numberOfVehicles;

    selectedCustomersId =
        encodeNamesWithId(data.customersId, supplier!.myCustomersId);
    isCustomersLocked = data.isServicesLocked.toList();
    customersDemandMax = data.maxDemands.toList();
    customersDemandMin = data.minDemands.toList();
    deletedCustomersId = [];

    newSelectedCustomersId =
        encodeNamesWithId(data.newCustomersId, supplier!.myCustomersId);
    isAddRecently =
        List.generate(newSelectedCustomersId.length, (index) => false);

    if (isLocked) {
      newCustomersDemandMax =
          data.newMaxDemands.map((e) => e.toString()).toList();
      newCustomersDemandMin =
          data.newMinDemands.map((e) => e.toString()).toList();
      newCustomersDemandMaxEditable = [];
      newCustomersDemandMinEditable = [];
    } else {
      newCustomersDemandMaxEditable = data.newMaxDemands
          .map((e) => TextEditingController(text: e.toString()))
          .toList();
      newCustomersDemandMinEditable = data.newMinDemands
          .map((e) => TextEditingController(text: e.toString()))
          .toList();
      newCustomersDemandMax = [];
      newCustomersDemandMin = [];
    }
    deletedNewCustomersId = [];

    selectedDriversId =
        encodeNamesWithId(data.driversId, supplier!.myDriversId);
    vehiclesCapacity = data.vehiclesCapacity;

    remainingCustomersId = supplier!.myCustomersId.toList();
    remainingCustomersId!
        .removeWhere((element) => selectedCustomersId.contains(element));
    remainingCustomersId!
        .removeWhere((element) => newSelectedCustomersId.contains(element));
  }

  @override
  void dispose() {
    super.dispose();
    supplierSubscription?.cancel();
    orderModelFullDataSubscription?.cancel();
    if (!isLocked) supplierFirebaseService.unLockOrder();
  }

  @override
  Widget build(BuildContext context) {
    var currentSupplier = supplier;
    var currentOrder = orderModelFullData;
    if (currentSupplier == null ||
        currentSupplier.id == 0 ||
        currentOrder == null) return loadingScreen();
    var title = isLocked ? 'Update Order (Locked)' : 'Update Order';
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: ProvideLoadingTask(
        isLoading: _isLoading,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: _mainWidget(currentSupplier, currentOrder),
        ),
      ),
    );
  }

  Widget _mainWidget(
      Supplier currentSupplier, OrderModelFullData currentOrder) {
    if (currentSupplier.orderId == 0)
      return _noOrderWidget(context);
    else if (isLocked) return _updateLockedWidget(context);
    return _updateAvailableWidget(context);
  }

  Widget _noOrderWidget(BuildContext context) {
    return Center(
      child: Text(
        'you have no order, go back and replace one',
      ),
    );
  }

  Widget _updateAvailableWidget(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        twoHeadWidget(
          head1: 'Customer Id',
          head2: 'Customer Demand min-max',
        ),
        SizedBox(height: 12),
        customersInfoWidget(
          names: itemsNameWidget(
            names: selectedCustomersId,
            onSelect: _showUnselectCustomer,
            encodeName: shortenName,
            isClickable: (index) => !isCustomersLocked[index],
          ),
          minDemand: listTextWidget(customersDemandMin),
          maxDemand: listTextWidget(customersDemandMax),
        ),
        SizedBox(height: 18),
        customersInfoWidget(
          names: itemsNameWidget(
            names: newSelectedCustomersId,
            onSelect: _showUnselectNewCustomer,
            encodeName: shortenName,
          ),
          minDemand: getInputControllerWidget(newCustomersDemandMinEditable),
          maxDemand: getInputControllerWidget(newCustomersDemandMaxEditable),
        ),
        ElevatedButton.icon(
          onPressed: _showSelectNewCustomerDialog,
          icon: Icon(Icons.add),
          label: Text('Add'),
        ),
        SizedBox(height: 18),
        _theRemainingBottomPart(),
        SizedBox(height: 18),
        Align(
          alignment: Alignment.bottomCenter,
          child: ElevatedButton(
            onPressed: _updateOrder,
            child: Text(
              'Update Order',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _updateLockedWidget(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        twoHeadWidget(
          head1: 'Customer Id',
          head2: 'Customer Demand min-max',
        ),
        SizedBox(height: 12),
        customersInfoWidget(
          names: itemsNameWidget(
            names: selectedCustomersId,
            encodeName: shortenName,
            isClickable: allNotClickable,
          ),
          minDemand: listTextWidget(customersDemandMin),
          maxDemand: listTextWidget(customersDemandMax),
        ),
        SizedBox(height: 18),
        customersInfoWidget(
          names: itemsNameWidget(
            names: newSelectedCustomersId,
            encodeName: shortenName,
            isClickable: allNotClickable,
          ),
          minDemand: listTextWidget(newCustomersDemandMin),
          maxDemand: listTextWidget(newCustomersDemandMax),
        ),
        SizedBox(height: 18),
        _theRemainingBottomPart(),
        SizedBox(height: 18),
      ],
    );
  }

  Widget _theRemainingBottomPart() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        vehiclesInfoWithHeaderWidget(
          names: listTextWidget(List.generate(
              vehiclesCapacity.length, (index) => 'Vehicle ${index + 1}')),
          capacity: listTextWidget(vehiclesCapacity),
        ),
        SizedBox(height: 18),
        driversInfoWithHeader(
          names: listTextWidget(
            selectedDriversId,
            encodeName: shortenName,
          ),
        ),
      ],
    );
  }

  _showSelectNewCustomerDialog() {
    showSelectItemDialog(
      context,
      title: 'Select Customer',
      msgOnEmpty: 'you have no remaining customers, please add more',
      list: remainingCustomersId!,
      selectFunction: _selectNewCustomer,
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

  _showUnselectNewCustomer(int index, String name) {
    showRemoveConfirmationDialog(
      context,
      title: 'Remove Order?',
      content: 'Are you sure you want to remove order of $name?',
      unselectFunction: () => _unselectNewCustomer(index),
    );
  }

  _selectNewCustomer(int index) {
    setState(() {
      isAddRecently.add(true);
      newSelectedCustomersId.add(remainingCustomersId![index]);
      newCustomersDemandMinEditable.add(TextEditingController(text: '0'));
      newCustomersDemandMaxEditable.add(TextEditingController(text: '0'));
      remainingCustomersId!.removeAt(index);
      numberOfOrders++;
    });
  }

  _unselectCustomer(int index) {
    setState(() {
      var id = selectedCustomersId[index];
      var idPart = int.parse(id.substring(id.indexOf('#') + 1));
      deletedCustomersId.add(idPart);
      remainingCustomersId!.add(selectedCustomersId[index]);
      selectedCustomersId.removeAt(index);
      customersDemandMax.removeAt(index);
      customersDemandMin.removeAt(index);
      numberOfOrders--;
    });
  }

  _unselectNewCustomer(int index) {
    setState(() {
      if (!isAddRecently[index]) {
        var id = newSelectedCustomersId[index];
        var idPart = int.parse(id.substring(id.indexOf('#') + 1));
        deletedNewCustomersId.add(idPart);
      }
      remainingCustomersId!.add(newSelectedCustomersId[index]);
      newSelectedCustomersId.removeAt(index);
      newCustomersDemandMinEditable.removeAt(index);
      newCustomersDemandMaxEditable.removeAt(index);
      numberOfOrders--;
    });
  }

  _updateOrder() async {
    setState(() => _isLoading = true);
    var result = await supplierFirebaseService.updateOrder(
      newCustomersId: decodeIds(newSelectedCustomersId),
      newDemandsMin:
          newCustomersDemandMinEditable.map((e) => int.parse(e.text)).toList(),
      newDemandsMax:
          newCustomersDemandMaxEditable.map((e) => int.parse(e.text)).toList(),
      deletedCustomersId: deletedCustomersId,
      deletedNewCustomersId: deletedNewCustomersId,
    );
    setState(() => _isLoading = false);
    if (result.type == RequestResponseType.SUCCESS) {
      showSnackBarMessage(context, result.message, Colors.blue);
      supplierFirebaseService.unLockOrder();
      Navigator.of(context).pop();
    } else
      showSnackBarMessage(context, result.message, Colors.red);
  }
}
