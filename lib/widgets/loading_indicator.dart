// lib/widgets/loading_indicator.dart
import 'package:flutter/material.dart';

class CustomLoadingIndicator extends StatelessWidget {final String message;

const CustomLoadingIndicator({
  super.key,
  this.message = 'Cargando...',
});

@override
Widget build(BuildContext context) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
        ),
        const SizedBox(height: 20),
        Text(
          message,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade700,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}
}
