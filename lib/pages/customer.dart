import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:search_choices/search_choices.dart';

import '../apis/contact.dart';
import '../helpers/AppTheme.dart';
import '../helpers/SizeConfig.dart';
import '../helpers/otherHelpers.dart';
import '../helpers/style.dart' as style;
import '../locale/MyLocalizations.dart';
import '../models/contact_model.dart';
import '../models/sell.dart';
import '../models/sellDatabase.dart';
import 'elements.dart';
import 'login.dart';

class Customer extends StatefulWidget {
  @override
  _CustomerState createState() => _CustomerState();
}

class _CustomerState extends State<Customer> {
  Map? argument;
  final _formKey = GlobalKey<FormState>();

  String transactionDate =
      DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now());
  List<Map<String, dynamic>> customerListMap = [];
  Map<String, dynamic> selectedCustomer = {
    'id': 0,
    'name': 'select customer',
    'mobile': ' - '
  };
  TextEditingController prefix = TextEditingController(),
      firstName = TextEditingController(),
      middleName = TextEditingController(),
      lastName = TextEditingController(),
      mobile = TextEditingController(),
      addressLine1 = TextEditingController(),
      addressLine2 = TextEditingController(),
      city = TextEditingController(),
      state = TextEditingController(),
      country = TextEditingController(),
      zip = TextEditingController();

  static int themeType = 1;
  ThemeData themeData = AppTheme.getThemeFromThemeMode(themeType);
  CustomAppTheme customAppTheme = AppTheme.getCustomAppTheme(themeType);

  @override
  void initState() {
    super.initState();
    selectCustomer();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newArguments = ModalRoute.of(context)?.settings.arguments as Map?;
    if (newArguments != null) {
      argument = newArguments;
      final customerId = argument?['customerId'];
      if (customerId != null) {
        Future.delayed(Duration(milliseconds: 400), () async {
          try {
            final value = await Contact().getCustomerDetailById(customerId);
            if (this.mounted) {
              setState(() {
                selectedCustomer = {
                  'id': customerId,
                  'name': value['name'],
                  'mobile': value['mobile'] ?? ' - ' // Provide default for mobile
                };
              });
            }
          } catch (e) {
            if (mounted) Fluttertoast.showToast(msg: "Error fetching customer: $e");
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          elevation: 0,
          title: Text(AppLocalizations.of(context).translate('customer'),
              style: AppTheme.getTextStyle(themeData.textTheme.titleLarge,
                  fontWeight: 600)),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.of(context).push(MaterialPageRoute<Null>(
                builder: (BuildContext context) {
                  return newCustomer();
                },
                fullscreenDialog: true));
          },
          child: Icon(MdiIcons.accountPlus),
          elevation: 2,
        ),
        body: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              Padding(
                padding:
                    EdgeInsets.only(top: MySize.size120!, left: MySize.size20!),
                child: Card(child: customerList()),
              ),
              Center(
                child: Visibility(
                  visible: (selectedCustomer['id'] == 0),
                  child: Text(
                      AppLocalizations.of(context).translate(
                          'please_select_a_customer_for_checkout_option'),
                      style: TextStyle(color: Colors.red)),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: Visibility(
          visible: (selectedCustomer['id'] != 0),
          child: argument == null 
              ? SizedBox.shrink() // Handle if arguments are not yet available
              : Row(
            mainAxisAlignment: (argument?['is_quotation'] == null)
                  ? MainAxisAlignment.spaceAround
                  : MainAxisAlignment.center,
            children: [
              if (argument?['is_quotation'] == null) // More direct conditional rendering
                  TextButton(
                  onPressed: addQuotation, // Corrected onPressed syntax
                  style: TextButton.styleFrom(
                      foregroundColor: Colors.black, backgroundColor: style.StyleColors().mainColor(1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(40.0),
                      )),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(
                        Icons.add,
                        color: Theme.of(context).colorScheme.surface,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Text(
                          AppLocalizations.of(context).translate('add_quotation'),
                          style: AppTheme.getTextStyle(
                              Theme.of(context).textTheme.bodyLarge,
                              color: Theme.of(context).colorScheme.surface),
                        ),
                      ),
                    ],
                  ),
                ),
              cartBottomBar(
                  '/checkout',
                  AppLocalizations.of(context).translate('pay_&_checkout'),
                  context,
                  Helper().argument(
                      locId: argument?['locationId'],
                      taxId: argument?['taxId'],
                      discountType: argument?['discountType'],
                      discountAmount: argument?['discountAmount'],
                      invoiceAmount: argument?['invoiceAmount'],
                      customerId: selectedCustomer['id'],
                      sellId: argument?['sellId'])),
            ],
          ),
        ));
  }

  //add quotation
  addQuotation() async {
    if (argument == null) {
      Fluttertoast.showToast(msg: "Cannot add quotation: missing arguments.");
      return;
    }
    Map sell = await Sell().createSell(
        changeReturn: 0.00,
        transactionDate: transactionDate,
        pending: argument?['invoiceAmount'] ?? 0.0,
        shippingCharges: 0.00,
        shippingDetails: '',
        invoiceNo: "${USERID}_${DateFormat('yMdHm').format(DateTime.now())}", // String interpolation
        contactId: selectedCustomer['id'],
        discountAmount: argument?['discountAmount'] ?? 0.0,
        discountType: argument?['discountType'] ?? 'fixed', // Default if null
        invoiceAmount: argument?['invoiceAmount'] ?? 0.0,
        locId: argument?['locationId'],
        saleStatus: 'draft',
        sellId: argument?['sellId'],
        taxId: argument?['taxId'],
        isQuotation: 1);
    confirmDialog(sell);
  }

  //confirmation dialogBox
  confirmDialog(sell) {
    showDialog(
      barrierDismissible: true,
      context: context,
      builder: (BuildContext context) {
        final currentSellId = argument?['sellId'];
        final currentTaxId = argument?['taxId'];

        return AlertDialog(
          backgroundColor: customAppTheme.bgLayer1,
          title: Text(AppLocalizations.of(context).translate('quotation'),
              style: AppTheme.getTextStyle(themeData.textTheme.titleLarge,
                  color: themeData.colorScheme.onSurface, fontWeight: 700)),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: themeData.colorScheme.primary,
              ),
              onPressed: () async {
                Navigator.pop(context); // Close dialog first
                if (currentSellId != null) {
                  //update sell
                  // Placeholder for update logic
                  _navigateToProducts();
                } else {
                  await SellDatabase().storeSell(sell).then((value) async {
                    SellDatabase()
                        .updateSellLine({'sell_id': value, 'is_completed': 1});
                    if (await Helper().checkConnectivity()) {
                      await Sell().createApiSell(sellId: value);
                    }
                    _navigateToProducts();
                  });
                }
              },
              child: Text(AppLocalizations.of(context).translate('save')),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: themeData.colorScheme.primary,
              ),
              onPressed: () async {
                Navigator.pop(context); // Close dialog first
                await SellDatabase().storeSell(sell).then((value) async {
                  SellDatabase()
                      .updateSellLine({'sell_id': value, 'is_completed': 1});
                  if (await Helper().checkConnectivity()) {
                    await Sell().createApiSell(sellId: value);
                  }
                  if (currentTaxId != null) {
                    await Helper().printDocument(value, currentTaxId, context);
                  } else {
                     Fluttertoast.showToast(msg: "Tax ID not found for printing.");
                  }
                  _navigateToProducts();
                  Fluttertoast.showToast(
                      msg: AppLocalizations.of(context)
                          .translate('quotation_added'));
                });
              },
              child:
                  Text(AppLocalizations.of(context).translate('save_n_print')),
            )
          ],
        );
      },
    );
  }

  void _navigateToProducts() {
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(
          context, '/products', ModalRoute.withName('/home'));
    }
  }

  //show add customer alert box
  Widget newCustomer() {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            AppLocalizations.of(context).translate('create_contact'),
            style: AppTheme.getTextStyle(themeData.textTheme.titleLarge, fontWeight: 600)), // Changed to titleLarge
      ),
      body: Container(
        height: MediaQuery.of(context).size.height,
        padding: EdgeInsets.only(top: 8, bottom: 8, left: 16, right: 16),
        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        Container(
                          width: 64,
                          child: Center(
                            child: Icon(
                              MdiIcons.accountChildCircle,
                              color: themeData.colorScheme.onSurface,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Container(
                            margin: EdgeInsets.only(left: 16),
                            child: Column(
                              children: <Widget>[
                                Row(
                                  children: <Widget>[
                                    Container(
                                      width: 50,
                                      child: TextFormField(
                                        controller: prefix,
                                        style: themeData.textTheme.titleSmall!
                                            .merge(TextStyle(
                                                color: themeData
                                                    .colorScheme.onSurface)),
                                        decoration: InputDecoration(
                                          hintStyle: themeData
                                              .textTheme.titleSmall!
                                              .merge(TextStyle(
                                                  color: themeData.colorScheme
                                                      .onSurface)),
                                          hintText: AppLocalizations.of(context)
                                              .translate('prefix'),
                                          border: UnderlineInputBorder(
                                            borderSide: BorderSide(
                                                color: themeData
                                                    .inputDecorationTheme
                                                    .border!
                                                    .borderSide
                                                    .color),
                                          ),
                                          enabledBorder: UnderlineInputBorder(
                                            borderSide: BorderSide(
                                                color: themeData
                                                    .inputDecorationTheme
                                                    .enabledBorder!
                                                    .borderSide
                                                    .color),
                                          ),
                                          focusedBorder: UnderlineInputBorder(
                                            borderSide: BorderSide(
                                                color: themeData
                                                    .inputDecorationTheme
                                                    .focusedBorder!
                                                    .borderSide
                                                    .color),
                                          ),
                                        ),
                                        textCapitalization:
                                            TextCapitalization.sentences,
                                      ),
                                    ),
                                    Padding(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 4)),
                                    Expanded(
                                      child: TextFormField(
                                        controller: firstName,
                                        validator: (value) {
                                          if (value!.length < 1) {
                                            return AppLocalizations.of(context)
                                                .translate(
                                                    'please_enter_your_name');
                                          } else {
                                            return null;
                                          }
                                        },
                                        style: themeData.textTheme.titleSmall!
                                            .merge(TextStyle(
                                                color: themeData
                                                    .colorScheme.onSurface)),
                                        decoration: InputDecoration(
                                          hintStyle: themeData
                                              .textTheme.titleSmall!
                                              .merge(TextStyle(
                                                  color: themeData.colorScheme
                                                      .onSurface)),
                                          hintText: AppLocalizations.of(context)
                                              .translate('first_name'),
                                          border: UnderlineInputBorder(
                                            borderSide: BorderSide(
                                                color: themeData
                                                    .inputDecorationTheme
                                                    .border!
                                                    .borderSide
                                                    .color),
                                          ),
                                          enabledBorder: UnderlineInputBorder(
                                            borderSide: BorderSide(
                                                color: themeData
                                                    .inputDecorationTheme
                                                    .enabledBorder!
                                                    .borderSide
                                                    .color),
                                          ),
                                          focusedBorder: UnderlineInputBorder(
                                            borderSide: BorderSide(
                                                color: themeData
                                                    .inputDecorationTheme
                                                    .focusedBorder!
                                                    .borderSide
                                                    .color),
                                          ),
                                        ),
                                        textCapitalization:
                                            TextCapitalization.sentences,
                                      ),
                                    )
                                  ],
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: <Widget>[
                                    Container(
                                      width: MySize.screenWidth! * 0.35,
                                      child: TextFormField(
                                        controller: middleName,
                                        style: themeData.textTheme.titleSmall!
                                            .merge(TextStyle(
                                                color: themeData
                                                    .colorScheme.onSurface)),
                                        decoration: InputDecoration(
                                          hintStyle: themeData
                                              .textTheme.titleSmall!
                                              .merge(TextStyle(
                                                  color: themeData.colorScheme
                                                      .onSurface)),
                                          hintText: AppLocalizations.of(context)
                                              .translate('middle_name'),
                                          border: UnderlineInputBorder(
                                            borderSide: BorderSide(
                                                color: themeData
                                                    .inputDecorationTheme
                                                    .border!
                                                    .borderSide
                                                    .color),
                                          ),
                                          enabledBorder: UnderlineInputBorder(
                                            borderSide: BorderSide(
                                                color: themeData
                                                    .inputDecorationTheme
                                                    .enabledBorder!
                                                    .borderSide
                                                    .color),
                                          ),
                                          focusedBorder: UnderlineInputBorder(
                                            borderSide: BorderSide(
                                                color: themeData
                                                    .inputDecorationTheme
                                                    .focusedBorder!
                                                    .borderSide
                                                    .color),
                                          ),
                                        ),
                                        textCapitalization:
                                            TextCapitalization.sentences,
                                      ),
                                    ),
                                    Container(
                                      width: MySize.screenWidth! * 0.35,
                                      child: TextFormField(
                                        controller: lastName,
                                        style: themeData.textTheme.titleSmall!
                                            .merge(TextStyle(
                                                color: themeData
                                                    .colorScheme.onSurface)),
                                        decoration: InputDecoration(
                                          hintStyle: themeData
                                              .textTheme.titleSmall!
                                              .merge(TextStyle(
                                                  color: themeData.colorScheme
                                                      .onSurface)),
                                          hintText: AppLocalizations.of(context)
                                              .translate('last_name'),
                                          border: UnderlineInputBorder(
                                            borderSide: BorderSide(
                                                color: themeData
                                                    .inputDecorationTheme
                                                    .border!
                                                    .borderSide
                                                    .color),
                                          ),
                                          enabledBorder: UnderlineInputBorder(
                                            borderSide: BorderSide(
                                                color: themeData
                                                    .inputDecorationTheme
                                                    .enabledBorder!
                                                    .borderSide
                                                    .color),
                                          ),
                                          focusedBorder: UnderlineInputBorder(
                                            borderSide: BorderSide(
                                                color: themeData
                                                    .inputDecorationTheme
                                                    .focusedBorder!
                                                    .borderSide
                                                    .color),
                                          ),
                                        ),
                                        textCapitalization:
                                            TextCapitalization.sentences,
                                      ),
                                    )
                                  ],
                                ),
                              ],
                            ),
                          ),
                        )
                      ],
                    ),
                    Container(
                      margin: EdgeInsets.only(top: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          Container(
                            width: 64,
                            child: Center(
                              child: Icon(
                                MdiIcons.homeCityOutline,
                                color: themeData.colorScheme.onSurface,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Container(
                              margin: EdgeInsets.only(left: 16),
                              child: Column(
                                children: <Widget>[
                                  TextFormField(
                                    controller: addressLine1,
                                    style: themeData.textTheme.titleSmall!.merge(
                                        TextStyle(
                                            color: themeData
                                                .colorScheme.onSurface)),
                                    decoration: InputDecoration(
                                      hintStyle: themeData.textTheme.titleSmall!
                                          .merge(TextStyle(
                                              color: themeData
                                                  .colorScheme.onSurface)),
                                      hintText: AppLocalizations.of(context)
                                          .translate('address_line_1'),
                                      border: UnderlineInputBorder(
                                        borderSide: BorderSide(
                                            color: themeData
                                                .inputDecorationTheme
                                                .border!
                                                .borderSide
                                                .color),
                                      ),
                                      enabledBorder: UnderlineInputBorder(
                                        borderSide: BorderSide(
                                            color: themeData
                                                .inputDecorationTheme
                                                .enabledBorder!
                                                .borderSide
                                                .color),
                                      ),
                                      focusedBorder: UnderlineInputBorder(
                                        borderSide: BorderSide(
                                            color: themeData
                                                .inputDecorationTheme
                                                .focusedBorder!
                                                .borderSide
                                                .color),
                                      ),
                                    ),
                                    textCapitalization:
                                        TextCapitalization.sentences,
                                  ),
                                  TextFormField(
                                    controller: addressLine2,
                                    style: themeData.textTheme.titleSmall!.merge(
                                        TextStyle(
                                            color: themeData
                                                .colorScheme.onSurface)),
                                    decoration: InputDecoration(
                                      hintStyle: themeData.textTheme.titleSmall!
                                          .merge(TextStyle(
                                              color: themeData
                                                  .colorScheme.onSurface)),
                                      hintText: AppLocalizations.of(context)
                                          .translate('address_line_2'),
                                      border: UnderlineInputBorder(
                                        borderSide: BorderSide(
                                            color: themeData
                                                .inputDecorationTheme
                                                .border!
                                                .borderSide
                                                .color),
                                      ),
                                      enabledBorder: UnderlineInputBorder(
                                        borderSide: BorderSide(
                                            color: themeData
                                                .inputDecorationTheme
                                                .enabledBorder!
                                                .borderSide
                                                .color),
                                      ),
                                      focusedBorder: UnderlineInputBorder(
                                        borderSide: BorderSide(
                                            color: themeData
                                                .inputDecorationTheme
                                                .focusedBorder!
                                                .borderSide
                                                .color),
                                      ),
                                    ),
                                    textCapitalization:
                                        TextCapitalization.sentences,
                                  )
                                ],
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.only(top: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          Container(
                            width: 64,
                            child: Center(
                              child: Icon(
                                MdiIcons.phoneOutline,
                                color: themeData.colorScheme.onSurface,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Container(
                              margin: EdgeInsets.only(left: 16),
                              child: Column(
                                children: <Widget>[
                                  TextFormField(
                                    controller: mobile,
                                    keyboardType: TextInputType.number,
                                    validator: (value) {
                                      if (value!.length < 1) {
                                        return AppLocalizations.of(context)
                                            .translate(
                                                'please_enter_your_number');
                                      } else {
                                        return null;
                                      }
                                    },
                                    style: themeData.textTheme.titleSmall!.merge(
                                        TextStyle(
                                            color: themeData
                                                .colorScheme.onSurface)),
                                    decoration: InputDecoration(
                                      hintStyle: themeData.textTheme.titleSmall!
                                          .merge(TextStyle(
                                              color: themeData
                                                  .colorScheme.onSurface)),
                                      hintText: AppLocalizations.of(context)
                                          .translate('phone'),
                                      border: UnderlineInputBorder(
                                        borderSide: BorderSide(
                                            color: themeData
                                                .inputDecorationTheme
                                                .border!
                                                .borderSide
                                                .color),
                                      ),
                                      enabledBorder: UnderlineInputBorder(
                                        borderSide: BorderSide(
                                            color: themeData
                                                .inputDecorationTheme
                                                .enabledBorder!
                                                .borderSide
                                                .color),
                                      ),
                                      focusedBorder: UnderlineInputBorder(
                                        borderSide: BorderSide(
                                            color: themeData
                                                .inputDecorationTheme
                                                .focusedBorder!
                                                .borderSide
                                                .color),
                                      ),
                                    ),
                                    textCapitalization:
                                        TextCapitalization.sentences,
                                  ),
                                ],
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.only(top: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          Container(
                            width: 64,
                            child: Center(
                              child: Icon(
                                MdiIcons.homeCityOutline,
                                color: themeData.colorScheme.onSurface,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Container(
                              margin: EdgeInsets.only(left: 16),
                              child: Column(
                                children: <Widget>[
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: <Widget>[
                                      Container(
                                        width: MySize.screenWidth! * 0.35,
                                        child: TextFormField(
                                          controller: city,
                                          style: themeData.textTheme.titleSmall!
                                              .merge(TextStyle(
                                                  color: themeData.colorScheme
                                                      .onSurface)),
                                          decoration: InputDecoration(
                                            hintStyle: themeData
                                                .textTheme.titleSmall!
                                                .merge(TextStyle(
                                                    color: themeData.colorScheme
                                                        .onSurface)),
                                            hintText:
                                                AppLocalizations.of(context)
                                                    .translate('city'),
                                            border: UnderlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: themeData
                                                      .inputDecorationTheme
                                                      .border!
                                                      .borderSide
                                                      .color),
                                            ),
                                            enabledBorder: UnderlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: themeData
                                                      .inputDecorationTheme
                                                      .enabledBorder!
                                                      .borderSide
                                                      .color),
                                            ),
                                            focusedBorder: UnderlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: themeData
                                                      .inputDecorationTheme
                                                      .focusedBorder!
                                                      .borderSide
                                                      .color),
                                            ),
                                          ),
                                          textCapitalization:
                                              TextCapitalization.sentences,
                                        ),
                                      ),
                                      Container(
                                        width: MySize.screenWidth! * 0.35,
                                        child: TextFormField(
                                          controller: state,
                                          style: themeData.textTheme.titleSmall!
                                              .merge(TextStyle(
                                                  color: themeData.colorScheme
                                                      .onSurface)),
                                          decoration: InputDecoration(
                                            hintStyle: themeData
                                                .textTheme.titleSmall!
                                                .merge(TextStyle(
                                                    color: themeData.colorScheme
                                                        .onSurface)),
                                            hintText:
                                                AppLocalizations.of(context)
                                                    .translate('state'),
                                            border: UnderlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: themeData
                                                      .inputDecorationTheme
                                                      .border!
                                                      .borderSide
                                                      .color),
                                            ),
                                            enabledBorder: UnderlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: themeData
                                                      .inputDecorationTheme
                                                      .enabledBorder!
                                                      .borderSide
                                                      .color),
                                            ),
                                            focusedBorder: UnderlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: themeData
                                                      .inputDecorationTheme
                                                      .focusedBorder!
                                                      .borderSide
                                                      .color),
                                            ),
                                          ),
                                          textCapitalization:
                                              TextCapitalization.sentences,
                                        ),
                                      )
                                    ],
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: <Widget>[
                                      Container(
                                        width: MySize.screenWidth! * 0.35,
                                        child: TextFormField(
                                          controller: country,
                                          style: themeData.textTheme.titleSmall!
                                              .merge(TextStyle(
                                                  color: themeData.colorScheme
                                                      .onSurface)),
                                          decoration: InputDecoration(
                                            hintStyle: themeData
                                                .textTheme.titleSmall!
                                                .merge(TextStyle(
                                                    color: themeData.colorScheme
                                                        .onSurface)),
                                            hintText:
                                                AppLocalizations.of(context)
                                                    .translate('country'),
                                            border: UnderlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: themeData
                                                      .inputDecorationTheme
                                                      .border!
                                                      .borderSide
                                                      .color),
                                            ),
                                            enabledBorder: UnderlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: themeData
                                                      .inputDecorationTheme
                                                      .enabledBorder!
                                                      .borderSide
                                                      .color),
                                            ),
                                            focusedBorder: UnderlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: themeData
                                                      .inputDecorationTheme
                                                      .focusedBorder!
                                                      .borderSide
                                                      .color),
                                            ),
                                          ),
                                          textCapitalization:
                                              TextCapitalization.sentences,
                                        ),
                                      ),
                                      Container(
                                        width: MySize.screenWidth! * 0.35,
                                        child: TextFormField(
                                          controller: zip,
                                          keyboardType: TextInputType.number,
                                          style: themeData.textTheme.titleSmall!
                                              .merge(TextStyle(
                                                  color: themeData.colorScheme
                                                      .onSurface)),
                                          decoration: InputDecoration(
                                            hintStyle: themeData
                                                .textTheme.titleSmall!
                                                .merge(TextStyle(
                                                    color: themeData.colorScheme
                                                        .onSurface)),
                                            hintText:
                                                AppLocalizations.of(context)
                                                    .translate('zip_code'),
                                            border: UnderlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: themeData
                                                      .inputDecorationTheme
                                                      .border!
                                                      .borderSide
                                                      .color),
                                            ),
                                            enabledBorder: UnderlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: themeData
                                                      .inputDecorationTheme
                                                      .enabledBorder!
                                                      .borderSide
                                                      .color),
                                            ),
                                            focusedBorder: UnderlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: themeData
                                                      .inputDecorationTheme
                                                      .focusedBorder!
                                                      .borderSide
                                                      .color),
                                            ),
                                          ),
                                          textCapitalization:
                                              TextCapitalization.sentences,
                                        ),
                                      )
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.only(top: 16),
                      child: TextButton(
                        style: TextButton.styleFrom(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4)),
                          padding:
                              EdgeInsets.symmetric(vertical: 8, horizontal: 48),
                          backgroundColor: themeData.colorScheme.primary,
                        ),
                        onPressed: () async {
                          if (await Helper().checkConnectivity()) {
                            if (_formKey.currentState!.validate()) {
                              Map newCustomer = {
                                'type': 'customer',
                                'prefix': prefix.text,
                                'first_name': firstName.text,
                                'middle_name': middleName.text,
                                'last_name': lastName.text,
                                'mobile': mobile.text,
                                'address_line_1': addressLine1.text,
                                'address_line_2': addressLine2.text,
                                'city': city.text,
                                'state': state.text,
                                'country': country.text,
                                'zip_code': zip.text
                              };
                              await CustomerApi()
                                  .add(newCustomer)
                                  .then((value) {
                                if (value['data'] != null) {
                                  Contact()
                                      .insertContact(
                                          Contact().contactModel(value['data']))
                                      .then((value) {
                                    selectCustomer();
                                    selectedCustomer = customerListMap[0];
                                    Navigator.pop(context);
                                    _formKey.currentState!.reset();
                                  });
                                }
                              });
                            }
                          } else {
                            Fluttertoast.showToast(
                                msg: AppLocalizations.of(context)
                                    .translate('check_connectivity'));
                          }
                        },
                        child: Text(
                            AppLocalizations.of(context)
                                .translate('add_to_contact')
                                .toUpperCase(),
                            style: AppTheme.getTextStyle(
                                themeData.textTheme.bodyLarge,
                                color: themeData.colorScheme.onPrimary,
                                letterSpacing: 0.3)),
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  //dropdown widget for selecting customer
  Widget customerList() {
    return SearchChoices.single(
      underline: SizedBox.shrink(), // Or Container(height: 0)
      displayClearIcon: false,
      value: jsonEncode(selectedCustomer),
      items: customerListMap.map<DropdownMenuItem<String>>((Map value) {
        return DropdownMenuItem<String>(
            value: jsonEncode(value),
            child: Container(
              width: MySize.screenWidth! * 0.8,
              child: Text("${value['name']} (${value['mobile'] ?? ' - '})",
                  softWrap: true,
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.getTextStyle(themeData.textTheme.bodyMedium,
                      color: themeData.colorScheme.onSurface)),
            ));
      }).toList(),
      iconEnabledColor: Colors.blue,
      iconDisabledColor: Colors.black,
      onChanged: (newValue) {
        setState(() {
          selectedCustomer = jsonDecode(newValue);
        });
      },
      isExpanded: true,
    );
  }

  selectCustomer() async {
    customerListMap = [
      {'id': 0, 'name': 'select customer', 'mobile': ' - '}
    ];
    List customers = await Contact().get();

    customers.forEach((value) {
      setState(() {
        customerListMap.add({
          'id': value['id'],
          'name': value['name'],
          'mobile': value['mobile']
        });
      });
      if (value['name'] == 'Walk-In Customer') {
        selectedCustomer = {
          'id': value['id'],
          'name': value['name'],
          'mobile': value['mobile']
        };
      }
    });
  }
}
