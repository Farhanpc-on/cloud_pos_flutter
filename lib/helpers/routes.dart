import 'package:flutter/widgets.dart';
import '../pages/cart.dart';
import '../pages/contact_payment.dart';
import '../pages/contacts.dart';
import '../pages/customer.dart';
import '../pages/expenses.dart';
import '../pages/follow_up.dart';
import '../pages/field_force.dart';
import '../pages/home.dart';
import '../pages/login.dart';
import '../pages/products.dart';
import '../pages/sales.dart';
import '../pages/shipment.dart';
import '../pages/splash.dart';
// Added this import

class Routes {
  static const String splash = '/splash';
  static const String login = '/login';
  static const String home = '/home';
  static const String products = '/products';
  static const String sale = '/sale';
  static const String cart = '/cart';
  static const String customer = '/customer';
  static const String checkout = '/checkout';
  static const String expense = '/expense';
  static const String contactPayment = '/contactPayment';
  static const String shipment = '/shipment';
  static const String leads = '/leads';
  static const String followUp = '/followUp';
  static const String fieldForce = '/fieldForce';

  static Map<String, WidgetBuilder> generateRoute() {
    return <String, WidgetBuilder>{
      splash: (BuildContext context) => Splash(),
      login: (BuildContext context) => Login(),
      home: (BuildContext context) => Home(),
      products: (BuildContext context) => Products(),
      sale: (BuildContext context) => Sales(),
      cart: (BuildContext context) => Cart(),
      customer: (BuildContext context) => Customer(),
      checkout: (BuildContext context) => CheckOut(),
      expense: (BuildContext context) => Expense(),
      contactPayment: (BuildContext context) => ContactPayment(),
      shipment: (BuildContext context) => Shipment(),
      leads: (BuildContext context) => Contacts(),
      followUp: (BuildContext context) => FollowUp(),
      fieldForce: (BuildContext context) => FieldForce()
    };
  }
  
  static CheckOut() {}
}
