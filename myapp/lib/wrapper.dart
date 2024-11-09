import 'package:flutter/material.dart';
import 'package:myapp/authenticate/authenticate.dart';
import 'package:myapp/pages/google_map_page.dart';

class Wrapper extends StatelessWidget {
  const Wrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Authenticate();
    //return MapSample(); // Assuming Authenticate is a widget in authenticate.dart
  }
}
