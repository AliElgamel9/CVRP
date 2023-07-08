import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Widget twoHeadWidget({required String head1, required String head2}) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        head1,
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      Text(
        head2,
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    ],
  );
}

Widget twoItemListWidget({required Widget item1, required Widget item2}) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Expanded(
        child: item1,
      ),
      SizedBox(width: 18),
      item2,
    ],
  );
}

Widget itemsNameWidget({
  required List<String> names,
  Function(int, String) onSelect = noneOnSelect,
  bool Function(int) isClickable = allClickable,
  String Function(String) encodeName = theSame,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisAlignment: MainAxisAlignment.start,
    children: [
      for (int i = 0; i < names.length; i++)
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            getNameWidget(encodeName(names[i]), i, isClickable(i), onSelect),
            SizedBox(height: 12),
          ],
        ),
    ],
  );
}

Widget getNameWidget(
    String name, int index, bool isClickable, Function(int, String) onSelect) {
    return Container(
      height: 35,
      child: ElevatedButton(
        onPressed: () => isClickable? onSelect(index, name) : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: isClickable? Colors.blue : Colors.blueGrey[300],
        ),
        child: Container(
          alignment: Alignment.centerLeft,
          child: Text(
            name,
            style: TextStyle(fontSize: 14),
            textAlign: TextAlign.start,
          ),
        ),
      ),
    );
}

Widget listTextWidget(List<dynamic> list, {String Function(String) encodeName = theSame}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisAlignment: MainAxisAlignment.start,
    children: [
      for (var item in list)
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              height: 35,
              alignment: Alignment.centerLeft,
              child: Text(
                encodeName(item.toString()),
                style: TextStyle(fontSize: 14),
                textAlign: TextAlign.start,
              ),
            ),
            SizedBox(height: 12),
          ],
        ),
    ],
  );
}

void showSelectItemDialog(
  BuildContext context, {
  required String title,
  required String msgOnEmpty,
  required List<String> list,
  required Function(int) selectFunction,
}) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (list.isEmpty) Text(msgOnEmpty),
            for (int i = 0; i < list.length; i++)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        selectFunction(i);
                        Navigator.of(context).pop();
                      },
                      child: Container(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          list[i].substring(0, min(list[i].length, 30)),
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    ),
  );
}

void showRemoveConfirmationDialog(
  BuildContext context, {
  required String title,
  required String content,
  required Function() unselectFunction,
}) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            unselectFunction();
            Navigator.of(context).pop();
          },
          child: Text('Remove'),
        ),
      ],
    ),
  );
}

Widget getInputControllerWidget(List<TextEditingController> controllers) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisAlignment: MainAxisAlignment.start,
    children: [
      for (var controller in controllers)
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              width: 70,
              height: 35,
              alignment: Alignment.centerLeft,
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  counterText: '',
                ),
                textAlign: TextAlign.start,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                maxLength: 5,
                maxLines: 1,
                style: TextStyle(fontSize: 14),
              ),
            ),
            SizedBox(height: 12),
          ],
        ),
    ],
  );
}

Widget vehiclesInfoWithHeaderWidget(
    {required Widget names, required Widget capacity}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisAlignment: MainAxisAlignment.start,
    children: [
      twoHeadWidget(
        head1: 'Vehicle',
        head2: 'Capacity',
      ),
      SizedBox(height: 18),
      twoItemListWidget(
        item1: names,
        item2: capacity,
      ),
    ],
  );
}

Widget customersInfoWidget(
    {required Widget names,
    required Widget minDemand,
    required Widget maxDemand}) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisAlignment: MainAxisAlignment.start,
    children: [
      Expanded(child: names),
      SizedBox(width: 12),
      minDemand,
      SizedBox(width: 8),
      maxDemand,
    ],
  );
}

Widget driversInfoWithHeader({required Widget names}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisAlignment: MainAxisAlignment.start,
    children: [
      Text(
        'Driver Id',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      SizedBox(height: 18),
      names,
    ],
  );
}

List<String> encodeNamesWithId(List<int> ids, List<String> namesWithId) {
  var encoded = <String>[];
  for (var id in ids) {
    encoded.add(encodeNameWithId(id, namesWithId));
  }
  return encoded;
}

String encodeNameWithId(int id, List<String> namesWithId) {
  for (var name in namesWithId) {
    if (name.contains('#$id')) return name;
  }
  return "";
}

String shortenName(String name) {
  var i = name.indexOf('#');
  if(i == -1) return name;
  return name.substring(0, min(i, 20)) + name.substring(i);
}

String theSame(String name) {
  return name;
}

bool allClickable(int index) {
  return true;
}

bool allNotClickable(int index) {
  return false;
}

void noneOnSelect(int index, String name) {}

List<int> decodeIds(List<String> idsEncoded) {
  return idsEncoded
      .map((e) => int.parse(e.substring(e.indexOf('#') + 1)))
      .toList();
}
