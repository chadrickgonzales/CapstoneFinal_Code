import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import FirebaseAuth
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:myapp/pages/map_picker_screen.dart';
import 'package:myapp/pages/other_profile_bottom_sheet.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('Flutter Demo'),
        ),
        body: Center(
          child: ElevatedButton(
            onPressed: () {
              displayBottomSheet_hub(context);
            },
            child: Text('Open Bottom Sheet'),
          ),
        ),
      ),
    );
  }
}

void displayBottomSheet_hub(BuildContext context) {
  bool showAlternateContent = true; // Initially show alternate content
  File? pickedImage; // Store the picked image file
  TextEditingController captionController = TextEditingController();
  TextEditingController locationController = TextEditingController();
  TextEditingController routeController = TextEditingController();
  bool showIcons = false; // Toggle view flag
  FocusNode captionFocusNode = FocusNode();

  showModalBottomSheet(
    context: context,
    backgroundColor: Color.fromARGB(225, 41, 42, 60),
    isScrollControlled: true,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          void _setImage(File? image) {
            setState(() {
              pickedImage = image; // Update pickedImage state
            });
          }

          void toggleContent() {
            setState(() {
              showAlternateContent = !showAlternateContent; // Toggle content
            });
          }

          void toggleView() {
            setState(() {
              showIcons = !showIcons; // Toggle between default and icon view
            });
          }

          return FractionallySizedBox(
            heightFactor: 0.95,
            widthFactor: 1.0,
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16.0),
                      topRight: Radius.circular(16.0),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              showAlternateContent ? 'Hub' : 'Create Post',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                              ),
                            ),
                            SizedBox(height: 16.0),
                          ],
                        ),
                      ),
                      SizedBox(height: 16),
                      Expanded(
                        child: Container(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16.0, vertical: 8.0),
                            child: showAlternateContent
                                ? _buildAlternateContent(context, toggleContent)
                                : _buildMainContent(
                                    context,
                                    pickedImage,
                                    captionController,
                                    locationController,
                                    routeController,
                                    toggleContent,
                                    _setImage,
                                    toggleView,
                                    showIcons,
                                    captionFocusNode,
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

LatLng? selectedLocation;
Widget _buildMainContent(
  BuildContext context,
  File? pickedImage,
  TextEditingController captionController,
  TextEditingController locationController,
  TextEditingController routeController,
  VoidCallback toggleContent,
  Function(File?) setImage,
  VoidCallback toggleView,
  bool showIcons,
  FocusNode captionFocusNode,
) {
  return SingleChildScrollView(
    child: Container(
      padding: EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Color.fromARGB(255, 80, 96, 116),
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.white),
                onPressed: toggleContent, // Toggle to show alternate content
              ),
              ElevatedButton(
                onPressed: () async {
                  // Handle form data
                  String caption = captionController.text;

                  // Fetch current user
                  User? user = FirebaseAuth.instance.currentUser;

                  if (user != null) {
                    // Fetch username from Firestore
                    DocumentSnapshot userDoc = await FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid)
                        .get();

                    String username =
                        userDoc.exists ? userDoc['username'] : 'Unknown';

                    String? imageUrl;
                    if (pickedImage != null) {
                      imageUrl = await _uploadImage(pickedImage);
                    }

                    // Prepare data to upload to Firestore
                    Map<String, dynamic> postData = {
                      'userId': user.uid,
                      'username': username,
                      'imageUrl': imageUrl,
                      'caption': caption,
                      'location': selectedLocation != null
                          ? GeoPoint(selectedLocation!.latitude,
                              selectedLocation!.longitude)
                          : null,
                      'timestamp': Timestamp.now(),
                    };

                    // Debugging: Print postData to ensure it's correct
                    print('Post Data: $postData');

                    try {
                      // Add data to Firestore collection
                      await FirebaseFirestore.instance
                          .collection('post')
                          .add(postData);

                      // Show success dialog
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text('Post Uploaded!'),
                            actions: [
                              TextButton(
                                child: Text('OK'),
                                onPressed: () {
                                  Navigator.of(context)
                                      .pop(); // Close the dialog
                                },
                              ),
                            ],
                          );
                        },
                      );

                      // Switch to the alternate content
                      toggleContent();
                    } catch (e) {
                      // Show error message
                      print('Error uploading post: $e');
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('Failed to upload post'),
                      ));
                    }
                  } else {
                    // Handle case where the user is null
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('User not authenticated'),
                    ));
                  }
                },
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all<Color>(
                    Color.fromARGB(255, 80, 96, 116),
                  ),
                  foregroundColor: MaterialStateProperty.all<Color>(
                    Colors.white,
                  ),
                  shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.0),
                      side: BorderSide(color: Colors.blue, width: 2.0),
                    ),
                  ),
                ),
                child: Text('Post'),
              ),
            ],
          ),
          SizedBox(height: 16),
          FutureBuilder(
            future: FirebaseAuth.instance.authStateChanges().first,
            builder: (context, AsyncSnapshot<User?> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return CircularProgressIndicator();
              }
              if (!snapshot.hasData) {
                return Text('Not authenticated');
              }
              return Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white,
                    radius: 20,
                    child: Icon(
                      Icons.person,
                      color: Colors.grey,
                    ), // Placeholder icon for profile picture
                  ),
                  SizedBox(width: 8),
                  Text(
                    snapshot.data!.displayName ?? 'Unknown',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              );
            },
          ),
          SizedBox(height: 16),
          TextFormField(
            controller: captionController,
            maxLines: 5,
            style: TextStyle(color: Colors.white, fontSize: 24),
            focusNode: captionFocusNode,
            decoration: InputDecoration(
              hintText: 'Got something interesting?',
              hintStyle: TextStyle(color: Colors.white70, fontSize: 24),
              border: InputBorder.none,
            ),
          ),
          if (pickedImage != null)
            Container(
              margin: EdgeInsets.only(top: 16.0),
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: Image.file(
                pickedImage,
                fit: BoxFit.cover,
              ),
            ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                icon: Icon(Icons.photo, color: Colors.white),
                onPressed: () {
                  _pickImageFromGallery(setImage);
                },
              ),
             
            ],
          ),
        ],
      ),
    ),
  );
}

Widget _buildImageSection(BuildContext context, Function(File?) setImage) {
  return GestureDetector(
    onTap: () {
      _pickImageFromGallery(setImage);
    },
    child: Container(
      alignment: Alignment.centerLeft,
      padding: EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Color.fromARGB(255, 80, 96, 116),
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Row(
        children: [
          Icon(Icons.photo, color: Colors.white),
          SizedBox(width: 8),
          Text('Photo/Video', style: TextStyle(color: Colors.white)),
        ],
      ),
    ),
  );
}

Widget _buildLocationSection(BuildContext context) {
  return Container(
    alignment: Alignment.centerLeft,
    padding: EdgeInsets.all(8.0),
    decoration: BoxDecoration(
      color: Color.fromARGB(255, 80, 96, 116),
      borderRadius: BorderRadius.circular(10.0),
    ),
    child: Row(
      children: [
        Icon(Icons.location_on, color: Colors.white),
        SizedBox(width: 8),
        Text('Location', style: TextStyle(color: Colors.white)),
      ],
    ),
  );
}

Widget _buildRouteSection(BuildContext context) {
  return Container(
    alignment: Alignment.centerLeft,
    padding: EdgeInsets.all(8.0),
    decoration: BoxDecoration(
      color: Color.fromARGB(255, 80, 96, 116),
      borderRadius: BorderRadius.circular(10.0),
    ),
    child: Row(
      children: [
        Icon(Icons.alt_route, color: Colors.white),
        SizedBox(width: 8),
        Text('Route', style: TextStyle(color: Colors.white)),
      ],
    ),
  );
}

Widget _buildAlternateContent(
    BuildContext context, VoidCallback toggleContent) {
  return Stack(
    children: [
      Container(
       height: MediaQuery.of(context).size.height * 0.73,
  margin: const EdgeInsets.only(bottom: 20.0), // Set specific margin here
  child: StreamBuilder(
    stream: FirebaseFirestore.instance.collection('post').snapshots(),
    builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return Center(child: CircularProgressIndicator());
      }

      if (snapshot.hasError) {
        return Center(child: Text('Error: ${snapshot.error}'));
      }

      if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (BuildContext context, int index) {
                  var post = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                  var postId = snapshot.data!.docs[index].id;
                  var username = post.containsKey('username') ? post['username'] : 'Unknown';
                  var imageUrl = post.containsKey('imageUrl') ? post['imageUrl'] : null;
                  var caption = post.containsKey('caption') ? post['caption'] : 'No Caption';
                  int likes = post.containsKey('likes') ? post['likes'] : 0;
                  List<dynamic> likedBy = post.containsKey('likedBy') ? post['likedBy'] : [];
                  List<dynamic> comments = post.containsKey('comments') ? post['comments'] : [];

                  return PostItem(
                    postId: postId,
                    username: username,
                    caption: caption,
                    likes: likes,
                    likedBy: likedBy,
                    comments: comments,
                    imageUrl: imageUrl,
                  );
                },
              ),
            ),
          ],
        );
      }

      return Center(child: Text('No posts found.'));
    },
  ),
),
      Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.92,
          height: 70,
          margin: EdgeInsets.all(8.0),
          child: ElevatedButton(
            onPressed: toggleContent, // Toggle to show main content
            style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all<Color>(
                Color.fromARGB(255, 132, 143, 200),
              ), // Button color
              foregroundColor: MaterialStateProperty.all<Color>(
                Colors.white,
              ), // Text color
              shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100.0),
                ),
              ),
            ),
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 1.0),
                    child: CircleAvatar(
                      backgroundColor: Colors.white,
                      radius: 20, // Adjust radius as needed
                      child: Icon(
                        Icons.person,
                        color: Colors.grey,
                      ), // Placeholder icon for profile picture
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.center,
                  child: Text(
                    'Got something interesting?',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ],
  );
}

class PostItem extends StatefulWidget {
  final String postId;
  final String username;
  final String caption;
  final int likes;
  final List<dynamic> likedBy;
  final List<dynamic> comments;
  final String? imageUrl;

  const PostItem({
    required this.postId,
    required this.username,
    required this.caption,
    required this.likes,
    required this.likedBy,
    required this.comments,
    this.imageUrl,
  });

  @override
  _PostItemState createState() => _PostItemState();
}

class _PostItemState extends State<PostItem> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8.0),
      padding: EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Color.fromARGB(255, 80, 96, 116),
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () async {
              // Call the function to open the bottom sheet
              GoogleMapController? mapController;
              Set<Marker> markers = {};
              Set<Polyline> polylines = {};
              List<LatLng> routePoints = [];
              String userId =
                  widget.username; // Assuming userId is part of the post data

              await displayBottomSheet_otherprofile(
                context,
                mapController,
                markers,
                polylines,
                routePoints,
                userId,
              );
            },
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: 16,
                  child: Icon(
                    Icons.person,
                    color: Colors.grey,
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  widget.username,
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
          SizedBox(height: 8),
          isExpanded
              ? Column(
                  children: [
                    Text(
                      widget.caption,
                      style: TextStyle(color: Colors.white),
                    ),
                    InkWell(
                      onTap: () {
                        setState(() {
                          isExpanded = false;
                        });
                      },
                      child: Text(
                        'Show less',
                        style: TextStyle(color: Colors.blue),
                      ),
                    ),
                  ],
                )
              : Column(
                  children: [
                    Text(
                      widget.caption.length > 100
                          ? '${widget.caption.substring(0, 100)}...'
                          : widget.caption,
                      style: TextStyle(color: Colors.white),
                    ),
                    if (widget.caption.length > 100)
                      InkWell(
                        onTap: () {
                          setState(() {
                            isExpanded = true;
                          });
                        },
                        child: Text(
                          'Show more',
                          style: TextStyle(color: Colors.blue),
                        ),
                      ),
                  ],
                ),
          SizedBox(height: 8),
          widget.imageUrl != null
              ? Container(
                  height: 200,
                  color: Colors.grey,
                  child: Image.network(
                    widget.imageUrl!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                )
              : Container(
                  height: 200,
                  color: Colors.grey,
                  child: Center(
                    child: Text(
                      'No Image',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              InkWell(
                onTap: () async {
                  // Fetch current user
                  User? user = FirebaseAuth.instance.currentUser;
                  if (user != null) {
                    // Check if the user has already liked the post
                    if (!widget.likedBy.contains(user.uid)) {
                      // Increment likes and add user to likedBy list
                      await FirebaseFirestore.instance
                          .collection('post')
                          .doc(widget.postId)
                          .update({
                        'likes': FieldValue.increment(1),
                        'likedBy': FieldValue.arrayUnion([user.uid])
                      });
                    } else {
                      // User already liked the post, remove like
                      await FirebaseFirestore.instance
                          .collection('post')
                          .doc(widget.postId)
                          .update({
                        'likes': FieldValue.increment(-1),
                        'likedBy': FieldValue.arrayRemove([user.uid])
                      });
                    }
                  }
                },
                child: Row(
                  children: [
                    Icon(
                      Icons.thumb_up,
                      color: widget.likedBy
                              .contains(FirebaseAuth.instance.currentUser?.uid)
                          ? Colors.blue
                          : Colors.white,
                    ),
                    SizedBox(width: 4),
                    Text(
                      '${widget.likes} Like${widget.likes == 1 ? '' : 's'}',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () {
                  _showCommentDialog(context, widget.postId);
                },
                child: Row(
                  children: [
                    Icon(Icons.comment, color: Colors.white),
                    SizedBox(width: 4),
                    Text('Comment', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ],
          ),
          if (widget.comments.isNotEmpty)
            Column(
              children: widget.comments.map<Widget>((comment) {
                return ListTile(
                  title: Text(comment['username']),
                  subtitle: Text(comment['text']),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  void _showCommentDialog(BuildContext context, String postId) {
    TextEditingController _commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add a Comment'),
          content: TextField(
            controller: _commentController,
            decoration: InputDecoration(hintText: 'Write your comment...'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (_commentController.text.isNotEmpty) {
                  await FirebaseFirestore.instance
                      .collection('post')
                      .doc(postId)
                      .update({
                    'comments': FieldValue.arrayUnion([
                      {
                        'username':
                            FirebaseAuth.instance.currentUser?.displayName ??
                                'Unknown',
                        'text': _commentController.text,
                      }
                    ])
                  });
                  Navigator.of(context).pop();
                }
              },
              child: Text('Post Comment'),
            ),
          ],
        );
      },
    );
  }
}

void _pickImageFromGallery(Function(File?) setImage) async {
  final ImagePicker _picker = ImagePicker();
  XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
  if (pickedFile != null) {
    setImage(File(pickedFile.path));
    _uploadImage(File(pickedFile.path)); // Upload image to Firebase Storage
  }
}

Future<String?> _uploadImage(File imageFile) async {
  String storageFolder = 'hubimages';
  var storageRef = FirebaseStorage.instance
      .ref()
      .child(storageFolder)
      .child(imageFile.path.split('/').last);

  try {
    await storageRef.putFile(imageFile);
    String imageUrl = await storageRef.getDownloadURL();
    return imageUrl;
  } catch (e) {
    print('Failed to upload image to Firebase Storage: $e');
    return null;
  }
}
