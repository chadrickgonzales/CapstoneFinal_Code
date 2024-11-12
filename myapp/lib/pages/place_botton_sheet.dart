import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:carousel_slider/carousel_slider.dart';

import 'map_picker_screen.dart';

Future<void> displayBottomSheet_place(BuildContext context) async {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Color.fromARGB(225, 19, 20, 40),
    isScrollControlled: true,
    builder: (context) {
      return FractionallySizedBox(
        heightFactor: 0.8,
        child: AddPlaceBottomSheet(
          onPlaceAdded: (String placeName, String description, String address,
              String address1, LatLng location, List<File> images, String category, String contactNumber) async {
            String placeId = Uuid().v4();
            String userId = FirebaseAuth.instance.currentUser?.uid ?? '';

            if (userId.isNotEmpty) {
              try {
                List<String> imageUrls = [];
                for (File image in images) {
                  final storageRef = FirebaseStorage.instance
                      .ref()
                      .child('places')
                      .child('$placeId/${Uuid().v4()}.jpg');
                  final uploadTask = storageRef.putFile(image);
                  final TaskSnapshot taskSnapshot = await uploadTask;
                  String imageUrl = await taskSnapshot.ref.getDownloadURL();
                  imageUrls.add(imageUrl);
                }

                await FirebaseFirestore.instance
                    .collection('place')
                    .doc(placeId)
                    .set({
                  'placeId': placeId,
                  'placeName': placeName,
                  'description': description,
                  'address': address,
                  'address1': address1,
                  'location': GeoPoint(location.latitude, location.longitude),
                  'imageUrls': imageUrls,
                  'userId': userId,
                  'timestamp': FieldValue.serverTimestamp(),
                  'category': category,
                  'contactNumber': contactNumber,
                });
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
  final Function(String, String, String, String, LatLng, List<File>, String, String) onPlaceAdded;

  AddPlaceBottomSheet({required this.onPlaceAdded});

  @override
  _AddPlaceBottomSheetState createState() => _AddPlaceBottomSheetState();
}

class _AddPlaceBottomSheetState extends State<AddPlaceBottomSheet> {
  final TextEditingController _placeNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _address1Controller = TextEditingController(); // New controller for address1
  final TextEditingController _contactNumberController = TextEditingController();
  LatLng? _selectedLocation;
  List<File> _selectedImages = [];
  String _selectedCategory = 'Sights';

  void _pickLocation(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MapPickerScreen()),
    );

    if (result != null) {
      setState(() {
        _selectedLocation = result;
        _addressController.text =
            'Lat: ${result.latitude}, Lng: ${result.longitude}';
      });
    }
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage(); // Allows multiple image selection
    if (pickedFiles != null) {
      setState(() {
        _selectedImages = pickedFiles.map((file) => File(file.path)).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView( // Wrapping the content inside a SingleChildScrollView to make it scrollable
      child: Container(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40.0,
                height: 5.0,
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
            ),
            SizedBox(height: 12.0),

            Row(
              children: [
                Text(
                  "Add a place",
                  style: TextStyle(
                    fontSize: 32.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.0),

            _buildTextFieldDialog(
              context,
              _placeNameController,
              'Place name (required)*',
              'Place Name',
            ),
            SizedBox(height: 16.0),

            _buildTextFieldDialog(
              context,
              _descriptionController,
              'Description',
              'Description',
            ),
            SizedBox(height: 16.0),

            _buildTextFieldDialog(
              context,
              _addressController,
              'Address (required)*',
              'Address',
            ),
            SizedBox(height: 16.0),

            _buildTextFieldDialog(
              context,
              _address1Controller, // New address1 text field
              'Address Line 2 (optional)',
              'Address Line 2',
            ),
            SizedBox(height: 16.0),

            _buildTextFieldDialog(
              context,
              _contactNumberController,
              'Contact Number (optional)',
              'Contact Number',
              keyboardType: TextInputType.phone,
            ),
            SizedBox(height: 16.0),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.75,
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
                      child: Text(
                        category,
                        style: TextStyle(color: Colors.white),
                      ),
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
                  dropdownColor: Color.fromARGB(225, 19, 20, 40),
                ),
              ),
            ),
            SizedBox(height: 16.0),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: () => _pickLocation(context),
                    icon: Icon(Icons.location_on, color: Colors.white),
                    label: Text(
                      _selectedLocation == null ? 'Pick Location' : 'Change Location',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    style: ButtonStyle(
                      padding: MaterialStateProperty.all<EdgeInsets>(
                        EdgeInsets.symmetric(vertical: 16.0),
                      ),
                      backgroundColor: MaterialStateProperty.all<Color>(
                        Colors.black.withOpacity(0.0),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16.0),

                Expanded(
                  child: TextButton.icon(
                    onPressed: () => _pickImages(),
                    icon: Icon(Icons.image, color: Colors.white),
                    label: Text(
                      _selectedImages.isEmpty ? 'Add Images' : 'Change Images',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    style: ButtonStyle(
                      padding: MaterialStateProperty.all<EdgeInsets>(
                        EdgeInsets.symmetric(vertical: 16.0),
                      ),
                      backgroundColor: MaterialStateProperty.all<Color>(
                        Colors.black.withOpacity(0.0),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10.0),

            // Image Slider to Preview Selected Images
            if (_selectedImages.isNotEmpty)
             CarouselSlider(
  items: _selectedImages
      .map(
        (image) {
          int index = _selectedImages.indexOf(image); // Get index of the image
          return Stack(
            children: [
              // Image preview
              Container(
                margin: EdgeInsets.all(8.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10.0),
                  child: Image.file(
                    image,
                    fit: BoxFit.cover,
                    width: MediaQuery.of(context).size.width,
                    height: 200,
                  ),
                ),
              ),
              // Delete button for the image
              Positioned(
                right: 5,
                top: 5,
                child: IconButton(
                  icon: Icon(Icons.delete, color: Colors.white),
                  onPressed: () {
                    setState(() {
                      _selectedImages.removeAt(index); // Remove image on delete button click
                    });
                  },
                ),
              ),
            ],
          );
        },
      )
      .toList(),
  options: CarouselOptions(
    height: 200,
    viewportFraction: 1.0,
    enableInfiniteScroll: false,
    initialPage: 0,
  ),
),
            SizedBox(height: 24.0),

            ElevatedButton(
              onPressed: () {
                if (_placeNameController.text.isEmpty || _addressController.text.isEmpty || _selectedLocation == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please fill in all required fields')),
                  );
                } else {
                  widget.onPlaceAdded(
                    _placeNameController.text,
                    _descriptionController.text,
                    _addressController.text,
                    _address1Controller.text,
                    _selectedLocation!,
                    _selectedImages,
                    _selectedCategory,
                    _contactNumberController.text,
                  );
                  Navigator.pop(context);
                }
              },
              child: Text('Add Place'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextFieldDialog(
      BuildContext context, TextEditingController controller, String hint, String label, {
        TextInputType keyboardType = TextInputType.text,
      }) {
    return TextFormField(
      controller: controller,
      style: TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white),
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.black.withOpacity(0.2),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide(color: Colors.white),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide(color: Colors.white),
        ),
      ),
      keyboardType: keyboardType,
    );
  }
}
