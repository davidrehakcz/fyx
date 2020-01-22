import 'package:flutter/cupertino.dart';
import 'package:fyx/FyxApp.dart';
import 'package:fyx/controllers/ApiController.dart';

void main() async {
  FyxApp.init();
  try {
    var credentials = await ApiController().provider.getCredentials();
    return runApp(FyxApp(credentials)..setEnv(Environment.dev));
  } catch (error) {
    return runApp(FyxApp(null)..setEnv(Environment.dev));
  }
}
