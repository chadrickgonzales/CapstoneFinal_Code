import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import 'map_picker_screen.dart';

Future<void> displayBottomSheet_place(BuildContext context) async {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Color.fromARGB(225, 19, 20, 40),
    isScrollControlled: true, // Allows the bottom sheet to take more space
    builder: (context) {
      return FractionallySizedBox(
        heightFactor: 0.8, // Set the height as 80% of the screen height
        child: AddPlaceBottomSheet(
          onPlaceAdded: (String placeName, String description, String address,
              LatLng location, File? image, String category) async {
            print('onPlaceAdded called');
            String placeId = Uuid().v4(); // Generate a unique PlaceId
            String userId = FirebaseAuth.instance.currentUser?.uid ?? '';

            if (userId.isNotEmpty) {
              try {
                String? imageUrl;
                if (image != null) {
                  print('Uploading image to Firebase Storage');
                  final storageRef = FirebaseStorage.instance
                      .ref()
                      .child('places')
                      .child('$placeId.jpg');
                  final uploadTask = storageRef.putFile(image);
                  final TaskSnapshot taskSnapshot = await uploadTask;
                  imageUrl = await taskSnapshot.ref.getDownloadURL();
                  print('Image uploaded: $imageUrl');
                }

                print('Adding place to Firestore');
                await FirebaseFirestore.instance
                    .collection('place')
                    .doc(placeId)
                    .set({
                  'placeId': placeId,
                  'placeName': placeName,
                  'description': description,
                  'address': address,
                  'location': GeoPoint(location.latitude, location.longitude),
                  'imageUrl': imageUrl, // Save the image URL
                  'userId': userId,
                  'timestamp': FieldValue.serverTimestamp(),
                  'category': category, // Save the selected category
                });
                print('Place added successfully');
              } catch (e) {
                print('Failed to add place: $e');
              }
            } else {
              print('User is not logged in');
            }
          },
        ),
      );
    },
  );
}

class AddPlaceBottomSheet extends StatefulWidget {
  final Function(String, String, String, LatLng, File?, String) onPlaceAdded;

  AddPlaceBottomSheet({required this.onPlaceAdded});

  @override
  _AddPlaceBottomSheetState createState() => _AddPlaceBottomSheetState();
}

class _AddPlaceBottomSheetState extends State<AddPlaceBottomSheet> {
  final TextEditingController _placeNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  LatLng? _selectedLocation;
  File? _selectedImage;
  String _selectedCategory = 'Sights'; // Default category

  void _pickLocation(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MapPickerScreen()),
    );

    if (result != null) {
      setState(() {
        _selectedLocation = result; // Set the selected location
        _addressController.text =
            'Lat: ${result.latitude}, Lng: ${result.longitude}';
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Add the drag indicator at the top
          Center(
            child: Container(
              width: 40.0, // Width of the drag indicator
              height: 5.0, // Height of the drag indicator
              decoration: BoxDecoration(
                color: Colors.grey[600], // Color of the drag indicator
                borderRadius: BorderRadius.circular(10.0),
              ),
            ),
          ),
          SizedBox(height: 12.0), // Space below the drag indicator

          // "Add a place" header
          Row(
            children: [
              Text(
                "Add a place",
                style: TextStyle(
                  fontSize: 32.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.white, // Customize color if needed
                ),
              ),
            ],
          ),
          SizedBox(height: 16.0), // Space between headers

          // "Place details" smaller header with padding and larger font
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 24.0), // Left-right space
            child: Text(
              "Place details",
              style: TextStyle(
                fontSize: 18.0, // Increase font size for emphasis
                fontWeight: FontWeight.w600,
                color:
                    Colors.white, // Slightly lighter color for smaller header
              ),
            ),
          ),
          SizedBox(height: 8.0),

          // Informational text with padding and larger font
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 24.0), // Left-right space
            child: Text(
              "Provide some information about this place. If this place is added to Maps, it will appear publicly.",
              style: TextStyle(
                fontSize: 18.0, // Increase font size
                color: Colors.white70, // Normal white text
              ),
            ),
          ),
          SizedBox(height: 40.0), // Space before the input fields

          // Input fields for place details
// Place name TextField
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 24.0), // Horizontal padding to center the input
            child: Container(
              width: MediaQuery.of(context).size.width *
                  0.75, // 75% of screen width
              child: TextField(
                controller: _placeNameController,
                decoration: InputDecoration(
                  hintText: 'Random',
                  hintStyle: TextStyle(color: Colors.white70),
                  labelText: 'Place name (required)*',
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  labelStyle: TextStyle(
                    color: Colors.white, // Label color
                  ),
                  filled: true,
                  fillColor: Colors.black.withOpacity(0.2), // Background color
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: BorderSide(
                      color: Colors.white, // Border color
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: BorderSide(
                      color: Colors.white, // Border color
                    ),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 12.0), // Padding inside the field
                ),
                style: TextStyle(color: Colors.white), // Input text color
              ),
            ),
          ),
          SizedBox(height: 16.0),

// Description TextField
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Container(
              width: MediaQuery.of(context).size.width *
                  0.75, // 75% of screen width
              child: TextField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  hintText: 'Description',
                  hintStyle: TextStyle(color: Colors.white70),
                  labelText: 'Description',
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  labelStyle: TextStyle(
                    color: Colors.white,
                  ),
                  filled: true,
                  fillColor: Colors.black.withOpacity(0.2),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: BorderSide(
                      color: Colors.white,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: BorderSide(
                      color: Colors.white,
                    ),
                  ),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                ),
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
          SizedBox(height: 16.0),

// Address TextField
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Container(
              width: MediaQuery.of(context).size.width *
                  0.75, // 75% of screen width
              child: TextField(
                controller: _addressController,
                decoration: InputDecoration(
                  hintText: 'Address',
                  hintStyle: TextStyle(color: Colors.white70),
                  labelText: 'Address (required)*',
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  labelStyle: TextStyle(
                    color: Colors.white,
                  ),
                  filled: true,
                  fillColor: Colors.black.withOpacity(0.2),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: BorderSide(
                      color: Colors.white,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: BorderSide(
                      color: Colors.white,
                    ),
                  ),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                ),
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
          SizedBox(height: 16.0),

// Category DropdownButtonFormField
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Container(
              width: MediaQuery.of(context).size.width *
                  0.75, // 75% of screen width
              child: DropdownButtonFormField<String>(
                value: _selectedCategory,
                items: [
                  'Sights',
                  'Parks',
                  'Stations',
                  'Food',
                  'Hotel',
                  'Other',
                ].map((category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child:
                        Text(category, style: TextStyle(color: Colors.white)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value!;
                  });
                },
                decoration: InputDecoration(
                  labelText: 'Select Category',
                  labelStyle: TextStyle(
                    color: Colors.white,
                  ),
                  filled: true,
                  fillColor: Colors.black.withOpacity(0.2),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: BorderSide(
                      color: Colors.white,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: BorderSide(
                      color: Colors.white,
                    ),
                  ),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                ),
                dropdownColor: Color.fromARGB(
                    225, 19, 20, 40), // Dropdown background color
              ),
            ),
          ),
          SizedBox(height: 16.0),

          // Pick Location button
          Row(
            mainAxisAlignment: MainAxisAlignment
                .spaceBetween, // Ensures the buttons are spaced out
            children: [
              // Pick Location button without outline and with icon
              Expanded(
                child: TextButton.icon(
                  onPressed: () => _pickLocation(context),
                  icon: Icon(Icons.location_on,
                      color: Colors.white), // Icon on the left
                  label: Text(
                    _selectedLocation == null
                        ? 'Pick Location'
                        : 'Change Location',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  style: ButtonStyle(
                    padding: MaterialStateProperty.all<EdgeInsets>(
                      EdgeInsets.symmetric(vertical: 16.0),
                    ),
                    backgroundColor: MaterialStateProperty.all<Color>(
                      Colors.black.withOpacity(0.0), // Background color
                    ),
                  ),
                ),
              ),
              SizedBox(width: 16.0), // Space between the buttons

              // Pick Image button without outline and with icon
              Expanded(
                child: TextButton.icon(
                  onPressed: () => _pickImage(),
                  icon: Icon(Icons.image,
                      color: Colors.white), // Icon on the left
                  label: Text(
                    _selectedImage == null ? 'Add Image' : 'Change Image',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  style: ButtonStyle(
                    padding: MaterialStateProperty.all<EdgeInsets>(
                      EdgeInsets.symmetric(vertical: 16.0),
                    ),
                    backgroundColor: MaterialStateProperty.all<Color>(
                      Colors.black.withOpacity(0.0), // Background color
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 30.0),

          // Bottom section with Cancel and Submit buttons
          Row(
            mainAxisAlignment: MainAxisAlignment
                .spaceBetween, // Positions buttons at opposite ends
            children: [
              // Cancel button at the bottom left
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(
                        context); // Close the bottom sheet without any action
                  },
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ButtonStyle(
                    padding: MaterialStateProperty.all<EdgeInsets>(
                      EdgeInsets.symmetric(vertical: 16.0),
                    ),
                    side: MaterialStateProperty.all<BorderSide>(
                      BorderSide(
                          color:
                              Color.fromARGB(255, 177, 55, 78)), // Border color
                    ),
                    backgroundColor: MaterialStateProperty.all<Color>(
                      Color.fromARGB(
                          255, 177, 55, 78), // Transparent background
                    ),
                  ),
                ),
              ),
              SizedBox(width: 16.0), // Space between buttons

              // Submit button at the bottom right
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    if (_placeNameController.text.isNotEmpty &&
                        _descriptionController.text.isNotEmpty &&
                        _addressController.text.isNotEmpty &&
                        _selectedLocation != null) {
                      widget.onPlaceAdded(
                        _placeNameController.text,
                        _descriptionController.text,
                        _addressController.text,
                        _selectedLocation!,
                        _selectedImage,
                        _selectedCategory,
                      );
                      Navigator.pop(
                          context); // Close the bottom sheet after submission
                    } else {
                      // Show error message or handle empty fields
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text('Error'),
                            content: Text(
                                'Please fill in all fields and select a location.'),
                            actions: <Widget>[
                              TextButton(
                                child: Text('OK'),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                              ),
                            ],
                          );
                        },
                      );
                    }
                  },
                  child: Text(
                    'Submit',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ButtonStyle(
                    padding: MaterialStateProperty.all<EdgeInsets>(
                      EdgeInsets.symmetric(vertical: 16.0),
                    ),
                    backgroundColor: MaterialStateProperty.all<Color>(
                      Color.fromARGB(255, 132, 143,
                          200), // Custom color for the Submit button
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}