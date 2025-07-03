import 'package:flutter/material.dart';
import 'package:mapproject/pages/get_location.dart';
import 'package:mapproject/pages/map_page.dart';
import 'package:mapproject/pages/record.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'Poppins'),
      home: Recording()
      );
  }
}

