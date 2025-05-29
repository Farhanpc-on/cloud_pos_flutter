import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../apis/field_force.dart';
import '../apis/follow_up.dart';
import '../helpers/AppTheme.dart';
import '../helpers/SizeConfig.dart';
import '../helpers/otherHelpers.dart';
import '../locale/MyLocalizations.dart';
import '../models/contact_model.dart';

class VisitForm extends StatefulWidget {
  const VisitForm({Key? key, required this.visit}) : super(key: key);
  final Map<String, dynamic> visit;

  @override
  _VisitFormState createState() => _VisitFormState();
}

class _VisitFormState extends State<VisitForm> {
  String visitStatus = '', location = '';
  XFile? _image;
  bool isLoading = false, showMeet2 = false, showMeet3 = false;
  final ImagePicker _picker = ImagePicker();
  final _formKey = GlobalKey<FormState>();
  LatLng? currentLoc;

  TextEditingController reasonController = TextEditingController(),
      meetWith = TextEditingController(),
      meetMobile = TextEditingController(),
      meetDesignation = TextEditingController(),
      meetWith2 = TextEditingController(),
      meetMobile2 = TextEditingController(),
      meetDesignation2 = TextEditingController(),
      meetWith3 = TextEditingController(),
      meetMobile3 = TextEditingController(),
      meetDesignation3 = TextEditingController(),
      discussionController = TextEditingController();

  static int themeType = 1;
  ThemeData themeData = AppTheme.getThemeFromThemeMode(themeType);
  CustomAppTheme customAppTheme = AppTheme.getCustomAppTheme(themeType);

  @override
  void initState() {
    super.initState();
    visitStatus = widget.visit['status'];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(
          "${widget.visit['visit_id']}",
          style: AppTheme.getTextStyle(
            themeData.textTheme.titleMedium,
            fontWeight: 600,
            color: themeData.colorScheme.primaryContainer,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(top: 8, bottom: 8, left: 16, right: 16),
        child: (isLoading)
            ? Helper().loadingIndicator(context)
            : Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Row(
                      children: [
                        Text(
                          AppLocalizations.of(context)
                              .translate('Did_you_meet_with_the_contact'),
                          style: AppTheme.getTextStyle(
                            themeData.textTheme.titleLarge,
                            fontWeight: 600,
                            color: themeData.colorScheme.primaryContainer,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Radio(
                          value: 'met_contact',
                          groupValue: visitStatus,
                          onChanged: (String? value) {
                            setState(() {
                              visitStatus = value!;
                            });
                          },
                          toggleable: true,
                        ),
                        Padding(
                          padding: EdgeInsets.all(MySize.size6!),
                          child: Text(
                            AppLocalizations.of(context).translate('yes'),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(MySize.size14!),
                        ),
                        Radio(
                          value: 'did_not_meet_contact',
                          groupValue: visitStatus,
                          onChanged: (String? value) {
                            setState(() {
                              visitStatus = value!;
                            });
                          },
                          toggleable: true,
                        ),
                        Padding(
                          padding: EdgeInsets.all(MySize.size6!),
                          child: Text(
                              AppLocalizations.of(context).translate('no')),
                        )
                      ],
                    ),
                    Visibility(
                      visible: (visitStatus == 'did_not_meet_contact'),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${AppLocalizations.of(context).translate('reason')} : ",
                            style: AppTheme.getTextStyle(
                              themeData.textTheme.titleMedium,
                              fontWeight: 600,
                              color: themeData.colorScheme.primaryContainer,
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.only(
                                top: MySize.size4!, bottom: MySize.size10!),
                            child: TextFormField(
                              controller: reasonController,
                              validator: (value) {
                                if (visitStatus == "did_not_meet_contact" &&
                                    reasonController.text.trim() == "") {
                                  return "${AppLocalizations.of(context).translate('please_provide_reason')}";
                                } else {
                                  return null;
                                }
                              },
                              minLines: 2,
                              maxLines: 6,
                              decoration: InputDecoration(
                                border: themeData.inputDecorationTheme.border,
                                enabledBorder:
                                    themeData.inputDecorationTheme.border,
                                focusedBorder: themeData
                                    .inputDecorationTheme.focusedBorder,
                              ),
                              textCapitalization: TextCapitalization.sentences,
                              style: AppTheme.getTextStyle(
                                themeData.textTheme.bodyLarge,
                                fontWeight: 500,
                                color: themeData.colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          "${AppLocalizations.of(context).translate('take_photo_of_the_contact_or_visited_place')}",
                          style: AppTheme.getTextStyle(
                            themeData.textTheme.bodyLarge,
                            fontWeight: 600,
                            color: themeData.colorScheme.primaryContainer,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        OutlinedButton(
                          onPressed: () async {
                            await _imgFromCamera();
                          },
                          child: Text(
                            "${AppLocalizations.of(context).translate('choose_file')}",
                            style: AppTheme.getTextStyle(
                              themeData.textTheme.bodyMedium,
                              fontWeight: 600,
                              color: themeData.colorScheme.onSurface,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Visibility(
                            visible: _image != null,
                            child: Padding(
                              padding: EdgeInsets.all(MySize.size4!),
                              child: Text(
                                (_image != null) ? "${_image!.name}" : '',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          "${AppLocalizations.of(context).translate('meet_with')} :* ",
                          style: AppTheme.getTextStyle(
                            themeData.textTheme.titleMedium,
                            fontWeight: 600,
                            color: themeData.colorScheme.primaryContainer,
                          ),
                        )
                      ],
                    ),
                    ListView(
                      physics: NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      children: [
                        Container(
                          margin: EdgeInsets.symmetric(vertical: MySize.size4!),
                          height: MySize.size60,
                          child: TextFormField(
                            controller: meetWith,
                            decoration: InputDecoration(
                              labelText:
                                  "${AppLocalizations.of(context).translate('name')}",
                              border: themeData.inputDecorationTheme.border,
                              enabledBorder:
                                  themeData.inputDecorationTheme.border,
                              focusedBorder:
                                  themeData.inputDecorationTheme.focusedBorder,
                            ),
                            validator: (value) {
                              if (meetWith.text.trim() == "") {
                                return "${AppLocalizations.of(context).translate('please_provide_meet_with')}";
                              } else {
                                return null;
                              }
                            },
                            style: AppTheme.getTextStyle(
                              themeData.textTheme.bodyLarge,
                              fontWeight: 500,
                              color: themeData.colorScheme.onSurface,
                            ),
                          ),
                        ),
                        Container(
                            margin:
                                EdgeInsets.symmetric(vertical: MySize.size4!),
                            height: MySize.size60,
                            child: TextFormField(
                              controller: meetMobile,
                              decoration: InputDecoration(
                                labelText:
                                    "${AppLocalizations.of(context).translate('mobile_no')}",
                                border: themeData.inputDecorationTheme.border,
                                enabledBorder:
                                    themeData.inputDecorationTheme.border,
                                focusedBorder: themeData
                                    .inputDecorationTheme.focusedBorder,
                              ),
                              validator: (value) {
                                if (meetMobile.text.trim() == "") {
                                  return "${AppLocalizations.of(context).translate('please_provide_meet_with_mobile_no')}";
                                } else {
                                  return null;
                                }
                              },
                              keyboardType: TextInputType.number,
                              inputFormatters: <TextInputFormatter>[
                                FilteringTextInputFormatter.digitsOnly
                              ],
                              style: AppTheme.getTextStyle(
                                themeData.textTheme.bodyLarge,
                                fontWeight: 500,
                                color: themeData.colorScheme.onSurface,
                              ),
                            )),
                        Container(
                          margin: EdgeInsets.symmetric(vertical: MySize.size4!),
                          height: MySize.size60,
                          child: TextFormField(
                            controller: meetDesignation,
                            decoration: InputDecoration(
                              labelText:
                                  "${AppLocalizations.of(context).translate('designation')}",
                              border: themeData.inputDecorationTheme.border,
                              enabledBorder:
                                  themeData.inputDecorationTheme.border,
                              focusedBorder:
                                  themeData.inputDecorationTheme.focusedBorder,
                            ),
                            validator: (value) {
                              if (meetDesignation.text.trim() == "") {
                                return "${AppLocalizations.of(context).translate('please_provide_designation')}";
                              } else {
                                return null;
                              }
                            },
                            textCapitalization: TextCapitalization.sentences,
                            style: AppTheme.getTextStyle(
                              themeData.textTheme.bodyLarge,
                              fontWeight: 500,
                              color: themeData.colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                    ListTile(
                      leading: Icon(
                        (showMeet2)
                            ? MdiIcons.minusCircle
                            : MdiIcons.plusCircle,
                        color: themeData.colorScheme.primary,
                      ),
                      title: Text(
                          "${AppLocalizations.of(context).translate('add_meet')} 2"),
                      onTap: () {
                        setState(() {
                          showMeet2 = !showMeet2;
                        });
                      },
                    ),
                    Visibility(
                      visible: showMeet2,
                      child: ListView(
                        physics: NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        children: [
                          Container(
                            margin:
                                EdgeInsets.symmetric(vertical: MySize.size4!),
                            height: MySize.size60,
                            child: TextFormField(
                              controller: meetWith2,
                              decoration: InputDecoration(
                                labelText:
                                    "${AppLocalizations.of(context).translate('name')}",
                                border: themeData.inputDecorationTheme.border,
                                enabledBorder:
                                    themeData.inputDecorationTheme.border,
                                focusedBorder: themeData
                                    .inputDecorationTheme.focusedBorder,
                              ),
                              style: AppTheme.getTextStyle(
                                themeData.textTheme.bodyLarge,
                                fontWeight: 500,
                                color: themeData.colorScheme.onSurface,
                              ),
                            ),
                          ),
                          Container(
                              margin:
                                  EdgeInsets.symmetric(vertical: MySize.size4!),
                              height: MySize.size60,
                              child: TextFormField(
                                controller: meetMobile2,
                                decoration: InputDecoration(
                                  labelText:
                                      "${AppLocalizations.of(context).translate('mobile_no')}",
                                  border: themeData.inputDecorationTheme.border,
                                  enabledBorder:
                                      themeData.inputDecorationTheme.border,
                                  focusedBorder: themeData
                                      .inputDecorationTheme.focusedBorder,
                                ),
                                keyboardType: TextInputType.number,
                                inputFormatters: <TextInputFormatter>[
                                  FilteringTextInputFormatter.digitsOnly
                                ],
                                style: AppTheme.getTextStyle(
                                  themeData.textTheme.bodyLarge,
                                  fontWeight: 500,
                                  color: themeData.colorScheme.onSurface,
                                ),
                              )),
                          Container(
                            margin:
                                EdgeInsets.symmetric(vertical: MySize.size4!),
                            height: MySize.size60,
                            child: TextFormField(
                              controller: meetDesignation2,
                              decoration: InputDecoration(
                                labelText:
                                    "${AppLocalizations.of(context).translate('designation')}",
                                border: themeData.inputDecorationTheme.border,
                                enabledBorder:
                                    themeData.inputDecorationTheme.border,
                                focusedBorder: themeData
                                    .inputDecorationTheme.focusedBorder,
                              ),
                              textCapitalization: TextCapitalization.sentences,
                              style: AppTheme.getTextStyle(
                                themeData.textTheme.bodyLarge,
                                fontWeight: 500,
                                color: themeData.colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    ListTile(
                      leading: Icon(
                        (showMeet3)
                            ? MdiIcons.minusCircle
                            : MdiIcons.plusCircle,
                        color: themeData.colorScheme.primary,
                      ),
                      title: Text(
                          "${AppLocalizations.of(context).translate('add_meet')} 3"),
                      onTap: () {
                        setState(() {
                          showMeet3 = !showMeet3;
                        });
                      },
                    ),
                    Visibility(
                      visible: (showMeet3),
                      child: ListView(
                        padding: EdgeInsets.symmetric(vertical: MySize.size8!),
                        physics: NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        children: [
                          Container(
                            margin:
                                EdgeInsets.symmetric(vertical: MySize.size4!),
                            height: MySize.size60,
                            child: TextFormField(
                              controller: meetWith3,
                              decoration: InputDecoration(
                                labelText:
                                    "${AppLocalizations.of(context).translate('name')}",
                                border: themeData.inputDecorationTheme.border,
                                enabledBorder:
                                    themeData.inputDecorationTheme.border,
                                focusedBorder: themeData
                                    .inputDecorationTheme.focusedBorder,
                              ),
                              style: AppTheme.getTextStyle(
                                themeData.textTheme.bodyLarge,
                                fontWeight: 500,
                                color: themeData.colorScheme.onSurface,
                              ),
                            ),
                          ),
                          Container(
                              margin:
                                  EdgeInsets.symmetric(vertical: MySize.size4!),
                              height: MySize.size60,
                              child: TextFormField(
                                controller: meetMobile3,
                                decoration: InputDecoration(
                                  labelText:
                                      "${AppLocalizations.of(context).translate('mobile_no')}",
                                  border: themeData.inputDecorationTheme.border,
                                  enabledBorder:
                                      themeData.inputDecorationTheme.border,
                                  focusedBorder: themeData
                                      .inputDecorationTheme.focusedBorder,
                                ),
                                keyboardType: TextInputType.number,
                                inputFormatters: <TextInputFormatter>[
                                  FilteringTextInputFormatter.digitsOnly
                                ],
                                style: AppTheme.getTextStyle(
                                  themeData.textTheme.bodyLarge,
                                  fontWeight: 500,
                                  color: themeData.colorScheme.onSurface,
                                ),
                              )),
                          Container(
                            margin:
                                EdgeInsets.symmetric(vertical: MySize.size4!),
                            height: MySize.size60,
                            child: TextFormField(
                              controller: meetDesignation3,
                              decoration: InputDecoration(
                                labelText:
                                    "${AppLocalizations.of(context).translate('designation')}",
                                border: themeData.inputDecorationTheme.border,
                                enabledBorder:
                                    themeData.inputDecorationTheme.border,
                                focusedBorder: themeData
                                    .inputDecorationTheme.focusedBorder,
                              ),
                              textCapitalization: TextCapitalization.sentences,
                              style: AppTheme.getTextStyle(
                                themeData.textTheme.bodyLarge,
                                fontWeight: 500,
                                color: themeData.colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          "${AppLocalizations.of(context).translate('visited_address')} : ",
                          style: AppTheme.getTextStyle(
                            themeData.textTheme.titleMedium,
                            fontWeight: 600,
                            color: themeData.colorScheme.primaryContainer,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () async {
                            //get current location
                            try {
                              await Geolocator.getCurrentPosition(
                                      desiredAccuracy: LocationAccuracy.high)
                                  .then((Position position) {
                                currentLoc = LatLng(
                                    position.latitude, position.longitude);
                                if (currentLoc != null) {
                                  setState(() {
                                    location =
                                        "longitude: ${currentLoc!.longitude.toString()},"
                                        " latitude: ${currentLoc!.latitude.toString()}";
                                  });
                                }
                              }).catchError((e) { // Added catchError for the Future
                                print("Error getting location: $e");
                                Fluttertoast.showToast(msg: AppLocalizations.of(context).translate('could_not_get_location_please_try_again') ?? "Could not get location. Please try again.");
                              });
                            } catch (e) { // General catch for other potential synchronous errors
                                print("Error in location button: $e");
                                Fluttertoast.showToast(msg: AppLocalizations.of(context).translate('could_not_get_location_please_try_again') ?? "Could not get location. Please try again.");
                            }
                          },
                          icon: Icon(MdiIcons.mapMarker),
                          label: Text(
                              "${AppLocalizations.of(context).translate('get_current_location')}"),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '$location',
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        )
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${AppLocalizations.of(context).translate('discussions_with_the_contact')} : ",
                          style: AppTheme.getTextStyle(
                            themeData.textTheme.titleMedium,
                            fontWeight: 600,
                            color: themeData.colorScheme.primaryContainer,
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(
                              top: MySize.size4!, bottom: MySize.size10!),
                          child: TextFormField(
                            controller: discussionController,
                            minLines: 2,
                            maxLines: 6,
                            decoration: InputDecoration(
                              border: themeData.inputDecorationTheme.border,
                              enabledBorder:
                                  themeData.inputDecorationTheme.border,
                              focusedBorder:
                                  themeData.inputDecorationTheme.focusedBorder,
                            ),
                            textCapitalization: TextCapitalization.sentences,
                            style: AppTheme.getTextStyle(
                              themeData.textTheme.bodyLarge,
                              fontWeight: 500,
                              color: themeData.colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ],
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
                          bool validated = true;
                          String? placeImage;
                          if (await Helper().checkConnectivity()) {
                            if (visitStatus == "assigned") {
                              validated = false;
                              Fluttertoast.showToast(
                                  msg: AppLocalizations.of(context)
                                      .translate('please_enter_visit_status'));
                            }

                            if (_image == null) {
                              validated = false;
                              Fluttertoast.showToast(
                                  msg: AppLocalizations.of(context).translate(
                                      'please_upload_image_of_visited_place'));
                            } else {
                          File imageFile = File(_image!.path);
                              List<int> imageBytes = await imageFile.readAsBytes(); // Changed to async
                              placeImage = base64Encode(imageBytes);
                            }

                            if (currentLoc == null) {
                              validated = false;
                              Fluttertoast.showToast(
                                  msg: AppLocalizations.of(context).translate(
                                      'please_add_current_location'));
                            }

                            if (_formKey.currentState!.validate() &&
                                validated) {
                              setState(() {
                                isLoading = true;
                              });
                              Map visitDetails = {
                                'status': '$visitStatus',
                                if (visitStatus == "did_not_meet_contact")
                                  'reason_to_not_meet_contact':
                                      reasonController.text,
                                'visited_on': DateFormat('yyyy-MM-dd HH:mm:ss')
                                    .format(DateTime.now()),
                                'meet_with': meetWith.text,
                                'meet_with_mobileno': meetMobile.text,
                                'meet_with_designation': meetDesignation.text,
                                'meet_with2': meetWith2.text,
                                'meet_with_mobileno2': meetMobile2.text,
                                'meet_with_designation2': meetDesignation2.text,
                                'meet_with3': meetWith3.text,
                                'meet_with_mobileno3': meetMobile3.text,
                                'meet_with_designation3': meetDesignation3.text,
                                'latitude': currentLoc!.latitude.toString(),
                                'longitude': currentLoc!.longitude.toString(),
                                'comments': discussionController.text,
                                'photo': placeImage
                              };
                              FieldForceApi()
                                  .update(visitDetails, widget.visit['id'])
                                  .then((value) {
                                if (value != null) {
                                  Fluttertoast.showToast(
                                      msg: AppLocalizations.of(context)
                                          .translate('status_updated'));
                                }
                                Navigator.pop(context);
                              });
                            }
                          }
                        },
                        child: Text(
                            AppLocalizations.of(context).translate('update'),
                            style: AppTheme.getTextStyle(
                                themeData.textTheme.bodyLarge,
                                color: themeData.colorScheme.onPrimary,
                                letterSpacing: 0.3)),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  //image from camera
  _imgFromCamera() async {
    XFile? image = await _picker.pickImage(
        source: ImageSource.camera); //, imageQuality: 50);
    setState(() {
      _image = image;
    });
  }
}

class FollowUpForm extends StatefulWidget {
  final Map<String, dynamic> customerDetails;
  final bool? edit;

  const FollowUpForm(this.customerDetails, {Key? key, this.edit}) : super(key: key);

  @override
  _FollowUpFormState createState() => _FollowUpFormState();
}

class _FollowUpFormState extends State<FollowUpForm> {
  List<String> statusList = ['scheduled', 'open', 'cancelled', 'completed'],
      followUpTypeList = ['call', 'sms', 'meeting', 'email'];
  List<Map<String, dynamic>> followUpCategory = [
    {'id': 0, 'name': 'Please select'}
  ];
  String selectedStatus = 'completed',
      selectedFollowUpType = 'call',
      duration = ''; // This seems to be for call duration, ensure it's handled if getCallLogDetails is removed
  Map<String, dynamic> selectedFollowUpCategory = {
    'id': 0,
    'name': '' // Will be localized in initState/didChangeDependencies
  };

  bool showError = false;

  TextEditingController titleController = TextEditingController(),
      startDateController = TextEditingController(),
      endDateController = TextEditingController(),
      descriptionController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  static int themeType = 1;
  ThemeData themeData = AppTheme.getThemeFromThemeMode(themeType);
  CustomAppTheme customAppTheme = AppTheme.getCustomAppTheme(themeType);

  @override
  void initState() {
    super.initState();
    // Initialize names for default categories after context is available.
    // Actual localization happens in didChangeDependencies or _loadAsyncData.
    _loadAsyncData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Ensure default category names are localized as context is now available.
    final localizedPleaseSelect = AppLocalizations.of(context).translate('please_select');
    if (followUpCategory.isNotEmpty && followUpCategory.first['id'] == 0) {
      followUpCategory.first['name'] = localizedPleaseSelect;
    }
    if (selectedFollowUpCategory['id'] == 0) {
      selectedFollowUpCategory['name'] = localizedPleaseSelect;
    }
  }

  Future<void> _loadAsyncData() async {
    // Ensure context is available for localization if needed for default category name
    if (mounted) {
      final localizedPleaseSelect = AppLocalizations.of(context).translate('please_select');
      setState(() {
        // Initialize followUpCategory with a localized "Please select" option
        followUpCategory = [{'id': 0, 'name': localizedPleaseSelect}];
        selectedFollowUpCategory = {'id': 0, 'name': localizedPleaseSelect};
      });
    }
    await _getFollowUpCategories();
    if (widget.edit == true) {
      _initializeFormForEdit();
    }
  }

  void _initializeFormForEdit() {
    titleController.text = widget.customerDetails['title'] ?? '';
    selectedStatus = widget.customerDetails['status']?.toString() ?? 'scheduled';
    selectedFollowUpType = widget.customerDetails['schedule_type']?.toString() ?? 'call';
    startDateController.text = widget.customerDetails['start_datetime']?.toString() ?? '';
    endDateController.text = widget.customerDetails['end_datetime']?.toString() ?? '';
    descriptionController.text = widget.customerDetails['description']?.toString() ?? '';

    Map<String, dynamic> categoryToSet = followUpCategory.first; // Default to "Please select"

    final dynamic rawFollowupCategory = widget.customerDetails['followup_category'];
    if (rawFollowupCategory != null && rawFollowupCategory is Map) {
      final categoryId = rawFollowupCategory['id'];
      if (categoryId != null) {
        try {
          categoryToSet = followUpCategory.firstWhere((element) => element['id'] == categoryId);
        } catch (e) {
          print("Follow-up category with ID $categoryId not found. Defaulting.");
          // categoryToSet remains the default "Please select" (the first item)
        }
      }
    }
    if (mounted) {
      setState(() {
        selectedFollowUpCategory = categoryToSet;
      });
    }
  }

  Future<void> _getFollowUpCategories() async {
    try {
      var categoriesData = await FollowUpApi().getFollowUpCategories();
      List<Map<String, dynamic>> newApiCategories = [];
      for (var element in categoriesData) {
        if (element is Map && element.containsKey('id') && element.containsKey('name')) {
          newApiCategories.add({
            'id': int.parse(element['id'].toString()),
            'name': element['name'].toString(),
          });
        }
      }
      if (mounted) {
        final localizedPleaseSelect = AppLocalizations.of(context).translate('please_select');
        setState(() {
          // The first item is always the localized "Please select"
          followUpCategory = [{'id': 0, 'name': localizedPleaseSelect}, ...newApiCategories];
        });
      }
        } catch (e) {
      print("Error fetching follow-up categories: $e");
      if (mounted) {
        Fluttertoast.showToast(msg: AppLocalizations.of(context).translate('error_fetching_categories_toast') ?? "Error fetching categories");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(
            (widget.edit == true)
                ? "${AppLocalizations.of(context).translate('edit_follow_up')}"
                : "${AppLocalizations.of(context).translate('add_follow_up')}",
            style: AppTheme.getTextStyle(themeData.textTheme.titleLarge,
                fontWeight: 600)), // Changed to titleLarge and used AppTheme helper
      ),
      body: Container(
        height: MySize.screenHeight,
        padding: EdgeInsets.all(MySize.size12!),
        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              Row(
                children: [
                  Text(
                    "${AppLocalizations.of(context).translate('customer_name')}:",
                    style: AppTheme.getTextStyle(
                      themeData.textTheme.bodyMedium,
                      fontWeight: 500,
                      color: themeData.colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    widget.customerDetails['name'] ?? '',
                    style: AppTheme.getTextStyle(
                      themeData.textTheme.bodyLarge,
                      fontWeight: 600,
                      color: themeData.colorScheme.onSurface,
                    ),
                  )
                ],
              ),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.only(top: MySize.size16!),
                      child: TextFormField(
                        onEditingComplete: () {
                          FocusScope.of(context).unfocus();
                        },
                        style: AppTheme.getTextStyle(
                          themeData.textTheme.bodyLarge,
                          fontWeight: 500,
                          color: themeData.colorScheme.onSurface,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "${AppLocalizations.of(context).translate('title')} "
                                "${AppLocalizations.of(context).translate('required')}";
                          } else {
                            return null;
                          }
                        },
                        decoration: InputDecoration(
                          labelText:
                              "${AppLocalizations.of(context).translate('title')}:",
                          hintText:
                              "${AppLocalizations.of(context).translate('title')}",
                          border: themeData.inputDecorationTheme.border,
                          enabledBorder: themeData.inputDecorationTheme.border,
                          focusedBorder:
                              themeData.inputDecorationTheme.focusedBorder,
                        ),
                        controller: titleController,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: MySize.size16!),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "${AppLocalizations.of(context).translate('status')}:",
                                style: AppTheme.getTextStyle(
                                  themeData.textTheme.bodyMedium,
                                  fontWeight: 500,
                                  color: themeData.colorScheme.onSurface,
                                ),
                              ),
                              Container(
                                width: MySize.screenWidth! * 0.45,
                                child: DropdownButtonFormField<String>(
                                  value: selectedStatus,
                                  dropdownColor: themeData.colorScheme.surface,
                                  icon: Icon(
                                    Icons.arrow_drop_down,
                                    color: themeData.colorScheme.onSurface,
                                  ),
                                  items: statusList
                                      .map<DropdownMenuItem<String>>(
                                          (String value) {
                                    return DropdownMenuItem<String>(
                                        value: value,
                                        child: Text(value,
                                            style: AppTheme.getTextStyle(
                                                themeData.textTheme.bodyLarge,
                                                color: themeData.colorScheme
                                                    .onSurface)));
                                  }).toList(),
                                  onChanged: (String? newValue) {
                                    if (newValue != null) {
                                      setState(() {
                                        selectedStatus = newValue;
                                      });
                                    }
                                  },
                                  validator: (value) {
                                    if (value == null)
                                      return "${AppLocalizations.of(context).translate('status')} "
                                          "${AppLocalizations.of(context).translate('required')}";
                                    else
                                      return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "${AppLocalizations.of(context).translate('follow_up_type')}:",
                                style: AppTheme.getTextStyle(
                                  themeData.textTheme.bodyMedium,
                                  fontWeight: 500,
                                  color: themeData.colorScheme.onSurface,
                                ),
                              ),
                              Container(
                                width: MySize.screenWidth! * 0.45,
                                child: DropdownButtonFormField<String>(
                                  value: selectedFollowUpType,
                                  hint: Text(
                                    "${AppLocalizations.of(context).translate('please_select')}",
                                    style: AppTheme.getTextStyle(
                                      themeData.textTheme.bodyLarge,
                                      fontWeight: 500,
                                      color: themeData.colorScheme.onSurface,
                                    ),
                                  ),
                                  dropdownColor: themeData.colorScheme.surface,
                                  icon: Icon(
                                    Icons.arrow_drop_down,
                                    color: themeData.colorScheme.onSurface,
                                  ),
                                  items: followUpTypeList
                                      .map<DropdownMenuItem<String>>(
                                          (String value) {
                                    return DropdownMenuItem<String>(
                                        value: value,
                                        child: Text(value,
                                            style: AppTheme.getTextStyle(
                                                themeData.textTheme.bodyLarge,
                                                color: themeData.colorScheme
                                                    .onSurface)));
                                  }).toList(),
                                  onChanged: (String? newValue) {
                                    if (newValue != null) {
                                      setState(() {
                                        selectedFollowUpType = newValue;
                                        if ((newValue.toLowerCase() == 'call' &&
                                            selectedStatus == 'completed')) {
                                          // Original logic for getCallLogDetails was here
                                        } else {
                                          // This nested setState is fine for simple cases
                                          // but consider if showError logic can be simplified.
                                          showError = false; 
                                        }
                                      });
                                    }
                                  },
                                  validator: (value) {
                                    if (value == null)
                                      return "${AppLocalizations.of(context).translate('follow_up_type')} "
                                          "${AppLocalizations.of(context).translate('required')}";
                                    else
                                      return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: MySize.size16!),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "${AppLocalizations.of(context).translate('follow_up_category')}:",
                            style: AppTheme.getTextStyle(
                              themeData.textTheme.bodyMedium,
                              fontWeight: 500,
                              color: themeData.colorScheme.onSurface,
                            ),
                          ),
                          SizedBox(
                            // width: MySize.screenWidth! * 0.8,
                            child: DropdownButtonFormField<Map<String, dynamic>>(
                              value: followUpCategory.firstWhere(
                                (item) => item['id'] == selectedFollowUpCategory['id'],
                                orElse: () => followUpCategory.isNotEmpty ? followUpCategory.first : selectedFollowUpCategory,
                              ),
                              hint: Text(
                                AppLocalizations.of(context).translate('please_select'),
                                style: AppTheme.getTextStyle(
                                  themeData.textTheme.bodyLarge,
                                  fontWeight: 500,
                                  color: themeData.colorScheme.onSurface,
                                ),
                              ),
                              dropdownColor: themeData.colorScheme.surface,
                              icon: Icon(
                                Icons.arrow_drop_down,
                                color: themeData.colorScheme.onSurface,
                              ),
                              items: followUpCategory
                                  .map<DropdownMenuItem<Map<String, dynamic>>>(
                                      (Map<String, dynamic> value) {
                                return DropdownMenuItem<Map<String, dynamic>>(
                                    value: value, // The object itself
                                    child: Text(value['name'],
                                        style: AppTheme.getTextStyle(
                                            themeData.textTheme.bodyLarge,
                                            color: themeData
                                                .colorScheme.onSurface)));
                              }).toList(),
                              onChanged: (Map<String, dynamic>? newValue) {
                                setState(() {
                                  selectedFollowUpCategory = newValue!;
                                });
                              },
                              validator: (value) {
                                if (value == null || value['id'] == 0)
                                  return "${AppLocalizations.of(context).translate('follow_up_category')} "
                                      "${AppLocalizations.of(context).translate('required')}";
                                else
                                  return null;
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: MySize.size16!),
                      // Replaced DateTimePicker with TextFormField and Flutter's built-in pickers
                      child: TextFormField(
                        controller: startDateController,
                        decoration: InputDecoration(
                          labelText:
                            "${AppLocalizations.of(context).translate('start_datetime')}:",
                          border: themeData.inputDecorationTheme.border,
                          enabledBorder: themeData.inputDecorationTheme.border,
                          focusedBorder:
                              themeData.inputDecorationTheme.focusedBorder,
                        ),
                        readOnly: true,
                        onTap: () async {
                          DateTime initialStartDate = DateTime.now();
                          try {
                            if (startDateController.text.isNotEmpty) {
                              initialStartDate = DateFormat('yyyy-MM-dd hh:mm a').parse(startDateController.text);
                            }
                          } catch (e) {
                            // Ignore parsing error, use current date
                            print("Error parsing start date: $e");
                          }
                          DateTime? pickedDate = await showDatePicker(
                              context: context,
                              initialDate: initialStartDate,
                              firstDate: DateTime.now().subtract(Duration(days: 366)),
                              lastDate: DateTime.now().add(Duration(days: 3650))); // Increased lastDate range
                          TimeOfDay? pickedTime = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.fromDateTime(initialStartDate));
                          if (pickedTime != null) {
                            final DateTime finalDateTime = DateTime(
                                pickedDate.year, pickedDate.month, pickedDate.day,
                                pickedTime.hour, pickedTime.minute);
                            if(mounted) {
                              setState(() {
                                startDateController.text = DateFormat('yyyy-MM-dd hh:mm a').format(finalDateTime);
                              });
                            }
                          }
                                                                        },
                        validator: (value) {
                          if (value == null || value.isEmpty)
                            return "${AppLocalizations.of(context).translate('start_datetime')} "
                                "${AppLocalizations.of(context).translate('required')}";
                          else
                            return null;
                        },
                        style: AppTheme.getTextStyle(
                          themeData.textTheme.bodyLarge,
                          fontWeight: 500,
                          color: themeData.colorScheme.onSurface,
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: MySize.size16!),
                      // Replaced DateTimePicker with TextFormField and Flutter's built-in pickers
                      child: TextFormField(
                        controller: endDateController,
                        decoration: InputDecoration(
                          labelText:
                            "${AppLocalizations.of(context).translate('end_datetime')}:",
                          border: themeData.inputDecorationTheme.border,
                          enabledBorder: themeData.inputDecorationTheme.border,
                          focusedBorder:
                              themeData.inputDecorationTheme.focusedBorder,
                        ),
                        readOnly: true,
                        onTap: () async {
                          DateTime initialEndDate = DateTime.now();
                           try {
                            if (endDateController.text.isNotEmpty) {
                              initialEndDate = DateFormat('yyyy-MM-dd hh:mm a').parse(endDateController.text);
                            }
                          } catch (e) {
                            // Ignore parsing error, use current date
                            print("Error parsing end date: $e");
                          }

                          DateTime? pickedDate = await showDatePicker(
                              context: context,
                              initialDate: initialEndDate,
                              firstDate: DateTime.now().subtract(Duration(days: 366)),
                              lastDate: DateTime.now().add(Duration(days: 3650))); 
                          TimeOfDay? pickedTime = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.fromDateTime(initialEndDate));
                          if (pickedTime != null) {
                            final DateTime finalDateTime = DateTime(
                                pickedDate.year, pickedDate.month, pickedDate.day,
                                pickedTime.hour, pickedTime.minute);
                            if (mounted) {
                              setState(() {
                                endDateController.text = DateFormat('yyyy-MM-dd hh:mm a').format(finalDateTime);
                              });
                            }
                          }
                                                                        },
                        validator: (value) {
                          if (value == null || value.isEmpty)
                            return "${AppLocalizations.of(context).translate('end_datetime')} "
                                "${AppLocalizations.of(context).translate('required')}";
                          else
                            return null;
                        },
                        style: AppTheme.getTextStyle(
                          themeData.textTheme.bodyLarge,
                          fontWeight: 500,
                          color: themeData.colorScheme.onSurface,
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: MySize.size16!),
                      child: TextFormField(
                        minLines: 2,
                        maxLines: 6,
                        decoration: InputDecoration(
                          alignLabelWithHint: true,
                          labelText:
                              "${AppLocalizations.of(context).translate('description')}:",
                          hintText:
                              "${AppLocalizations.of(context).translate('description')}",
                          border: themeData.inputDecorationTheme.border,
                          enabledBorder: themeData.inputDecorationTheme.border,
                          focusedBorder:
                              themeData.inputDecorationTheme.focusedBorder,
                        ),
                        controller: descriptionController,
                        textCapitalization: TextCapitalization.sentences,
                        style: AppTheme.getTextStyle(
                          themeData.textTheme.bodyLarge,
                          fontWeight: 500,
                          color: themeData.colorScheme.onSurface,
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: MySize.size8!),
                      child: Visibility(
                        visible: showError,
                        child: Row(
                          children: [
                            Container(
                              width: MySize.screenWidth! * 0.7,
                              child: Text(
                                "${AppLocalizations.of(context).translate('call_log_not_found')}*",
                                style: AppTheme.getTextStyle(
                                  themeData.textTheme.titleSmall,
                                  fontWeight: 500,
                                  color: themeData.colorScheme.error,
                                ),
                              ),
                            ),
                            Helper().callDropdown(
                                context,
                                widget.customerDetails,
                                [
                                  widget.customerDetails['mobile'],
                                  widget.customerDetails['landline'],
                                  widget.customerDetails['alternate_number']
                                ],
                                type: 'call')
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: MySize.size8!),
                      child: ElevatedButton(
                          child: Text(
                            AppLocalizations.of(context).translate('submit'),
                            style: AppTheme.getTextStyle(
                              themeData.textTheme.bodyLarge,
                              fontWeight: 600,
                              color: themeData.colorScheme.onPrimary,
                            ),
                          ),
                          onPressed: () async {
                            //form validation
                            if (selectedFollowUpType.toLowerCase() == 'call' &&
                                selectedStatus == 'completed') {
                              onSubmit();
                              // getCallLogDetails().then((value) async {
                              //   onSubmit();
                              // });
                            } else {
                              onSubmit();
                            }
                          }),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  //on submit
  onSubmit() async {
    if (_formKey.currentState!.validate() && showError == false) {
      Map followUp = FollowUpModel().submitFollowUp(
          title: titleController.text,
          description: '${descriptionController.text}',
          contactId: widget.customerDetails['id'],
          followUpCategoryId: selectedFollowUpCategory['id'],
          endDate: endDateController.text,
          startDate: startDateController.text,
          duration: (duration != '') ? '$duration' : null,
          scheduleType: selectedFollowUpType,
          status: selectedStatus);
      int response = (widget.edit == true)
          ? await FollowUpApi()
              .update(followUp, widget.customerDetails['followUpId'])
          : await FollowUpApi().addFollowUp(followUp);
      if (response == 201 || response == 200) {
        Navigator.pop(context);
        (widget.edit == true)
            ? Navigator.pushReplacementNamed(context, '/followUp')
            : Navigator.pushReplacementNamed(context, '/leads');
      } else {
        Fluttertoast.showToast(
            msg:
                "${AppLocalizations.of(context).translate('something_went_wrong')}");
      }
    }
  }
}
