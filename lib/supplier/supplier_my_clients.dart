import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_login_architecture/utils/loading_task.dart';

import '../firebase_backend/utils.dart';
import '../utils/global_views.dart';

class SupplierMyClients extends StatefulWidget {
  final List<String> _clientsId;
  final String _title;
  final Future<RequestResponse> Function(String) _addClientFunction;

  SupplierMyClients(this._clientsId, this._title, this._addClientFunction);

  @override
  State<StatefulWidget> createState() =>
      _SupplierMyClients(_clientsId, _title, _addClientFunction);
}

class _SupplierMyClients extends State {
  final List<String> _clientsId;
  final String _title;
  late final String _content;
  final TextEditingController _clientIdController = TextEditingController();
  final Future<RequestResponse> Function(String) _addClientFunction;

  var _isLoading = false;

  _SupplierMyClients(this._clientsId, this._title, this._addClientFunction) {
    _content = _title.toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My $_title'),
      ),
      body: ProvideLoadingTask(
        isLoading: _isLoading,
        child: Container(
          padding: EdgeInsets.all(16),
          child: Stack(
            children: [
              SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your ${_title}s Name',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 12),
                    if (_clientsId.length == 0)
                      Text('You have no ${_content}s yet, add some!'),
                    for (int i = 1; i <= _clientsId.length; i++)
                      Column(
                        children: [
                          Text(
                            '$i. ${_clientsId[i - 1]}',
                            style: TextStyle(fontSize: 16),
                          ),
                          SizedBox(height: 12),
                        ],
                      ),
                    SizedBox(height: 80),
                  ],
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  color: Colors.white,
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _clientIdController,
                          decoration: InputDecoration(
                            labelText: '$_title Id',
                          ),
                        ),
                      ),
                      FloatingActionButton(
                        onPressed: () => _addClient(_clientIdController.text),
                        child: Icon(Icons.add),
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _addClient(String clientId) async {
    setState(() => _isLoading = true);
    var res = await _addClientFunction(clientId);
    setState(() => _isLoading = false);
    if (res.type == RequestResponseType.SUCCESS) {
      showSnackBarMessage(context, res.message, Colors.blue);
      setState(() => _clientIdController.text = '');
    } else
      showSnackBarMessage(context, res.message, Colors.red);
  }
}
