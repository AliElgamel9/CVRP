import 'package:flutter/material.dart';

class CollapsibleWidget extends StatefulWidget {
  final String headerTitle;
  final Widget child;
  final Function() onActionClick;

  CollapsibleWidget({
    required this.headerTitle,
    required this.child,
    required this.onActionClick,
  });

  @override
  _CollapsibleWidgetState createState() => _CollapsibleWidgetState(onActionClick: onActionClick);
}

class _CollapsibleWidgetState extends State<CollapsibleWidget> {

  final Function() onActionClick;
  bool _isExpanded = false;

  _CollapsibleWidgetState({required this.onActionClick});


  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
          child: Container(
            color: Colors.blue[300],
            padding: EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Expanded(child: Text(
                  widget.headerTitle,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),),
                SizedBox(width: 16.0,),
              GestureDetector(
                onTap: onActionClick,
                child: Image.asset(
                  'assets/images/navigation_icon.png',
                  width: 32,
                  height: 32,
                )
              ),
                SizedBox(width: 16.0,),
                Icon(
                  _isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: Colors.white,
                  size: 32,
                ),
              ],
            ),
          ),
        ),
        if (_isExpanded) Container(
          child: Padding(
            padding: EdgeInsets.all(12),
            child: widget.child,
          ),
          color: Colors.blueGrey[50],
        ),
      ],
    );
  }
}
