import 'dart:async';
import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:myapp/pages/itinerary_info_bottom_sheet.dart';
import 'package:myapp/services/routeservice.dart';
import 'package:myapp/pages/other_profile_bottom_sheet.dart';
import 'package:myapp/authenticate/sign_in.dart';

Future<void> displayBottomSheet_profile(
    BuildContext context,
    GoogleMapController mapController,
    Set<Marker> markers,
    Set<Polyline> polylines,
    List<LatLng> routePoints) async {
  String selectedButton = 'Uploads'; // Default selected button
  bool showAlternateContent = false;
  bool showListSampleContent = false; // New state for List Sample content
  bool showAddToListContent = false; // New state for Add to this List content
  bool showEditListContent = false; // New state for Edit List content lol
  bool showSettingsContent = false;

  final Function showOverlay;

  // Fetch user data from Firestore
  User? user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    DocumentSnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore
        .instance
        .collection('users')
        .doc(user.uid)
        .get();

    String username = snapshot.data()?['username'] ??
        'Username'; // Default to 'Username' if username not found

    showModalBottomSheet(
      context: context,
      backgroundColor: Color.fromARGB(225, 41, 42, 60),
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            void toggleContent() {
              setState(() {
                showAlternateContent = !showAlternateContent; // Toggle content
                showListSampleContent = false; // Ensure other content is hidden
                showAddToListContent = false; // Ensure other content is hidden
                showEditListContent = false; // Ensure other content is hidden
                showSettingsContent = false;
              });
            }

            void toggleListSampleContent() {
              setState(() {
                showListSampleContent =
                    !showListSampleContent; // Toggle List Sample content
                showAlternateContent = false; // Ensure other content is hidden
                showAddToListContent = false; // Ensure other content is hidden
                showEditListContent = false; // Ensure other content is hidden
                showSettingsContent = false;
              });
            }

            void toggleAddToListContent() {
              setState(() {
                showAddToListContent =
                    !showAddToListContent; // Toggle Add to List content
                showAlternateContent = false; // Ensure other content is hidden
                showListSampleContent = false; // Ensure other content is hidden
                showEditListContent = false; // Ensure other content is hidden
                showSettingsContent = false;
              });
            }

            void toggleEditListContent() {
              setState(() {
                showEditListContent =
                    !showEditListContent; // Toggle Edit List content
                showAlternateContent = false; // Ensure other content is hidden
                showListSampleContent = false; // Ensure other content is hidden
                showAddToListContent = false; // Ensure other content is hidden
                showSettingsContent = false;
              });
            }

            void toggleSettingsContent() {
              setState(() {
                showSettingsContent = !showSettingsContent;
                showListSampleContent = false; // Toggle List Sample content
                showAlternateContent = false; // Ensure other content is hidden
                showAddToListContent = false; // Ensure other content is hidden
                showEditListContent = false; // Ensure other content is hidden
              });
            }

            return FractionallySizedBox(
              heightFactor: 0.95,
              widthFactor: 1.0, // 90% of screen height
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              showAlternateContent
                                  ? 'Create A List'
                                  : showListSampleContent
                                      ? ''
                                      : showAddToListContent
                                          ? ''
                                          : showEditListContent
                                              ? ''
                                              : showSettingsContent
                                                  ? ''
                                                  : 'Profile',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                              ),
                            ),
                            IconButton(
                              onPressed: toggleSettingsContent,
                              icon: Icon(Icons.menu, color: Colors.white),
                            ),
                          ],
                        ),
                        SizedBox(height: 16.0),
                        if (!showAlternateContent &&
                            !showListSampleContent &&
                            !showAddToListContent &&
                            !showEditListContent &&
                            !showSettingsContent) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment
                                .center, // Center items vertically
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                ),
                                child: Center(
                                  child: Icon(
                                    Icons.person,
                                    size: 40,
                                    color: Color.fromARGB(225, 41, 42, 60),
                                  ),
                                ),
                              ),
                              SizedBox(width: 16.0),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment
                                    .center, // Center text vertically in the row
                                children: [
                                  Text(
                                    username, // Display fetched username here
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                    ),
                                  ),
                                  SizedBox(height: 4.0),
                                ],
                              ),
                            ],
                          ),
                          SizedBox(height: 16.0),
                          Center(
                            child: ElevatedButton(
                              onPressed: () => _openEditProfileDialog(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Color.fromARGB(225, 41, 42, 60),
                                side: BorderSide(
                                  color: Color.fromARGB(255, 136, 147, 206),
                                ),
                                padding: EdgeInsets.symmetric(
                                    horizontal: 24.0, vertical: 12.0),
                              ),
                              child: Text(
                                'Edit Profile',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                          SizedBox(height: 16.0),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Flexible(
                                child: FittedBox(
                                  child: _buildOutlinedButton(
                                    'Uploads',
                                    Color.fromARGB(255, 177, 55, 78),
                                    selectedButton == 'Uploads',
                                    () {
                                      // Correctly passing a function here
                                      setState(() {
                                        selectedButton = 'Uploads';
                                      });
                                    },
                                    selectedBackgroundColor: Color.fromARGB(
                                        255, 177, 55, 78), // Optional argument
                                  ),
                                ),
                              ),
                              SizedBox(width: 16.0),
                              Flexible(
                                child: FittedBox(
                                  child: _buildOutlinedButton(
                                    'Reviews',
                                    Color.fromARGB(255, 177, 55, 78),
                                    selectedButton == 'Reviews',
                                    () {
                                      // Correctly passing a function here
                                      setState(() {
                                        selectedButton = 'Reviews';
                                      });
                                    },
                                    selectedBackgroundColor: Color.fromARGB(
                                        255, 177, 55, 78), // Optional argument
                                  ),
                                ),
                              ),
                              SizedBox(width: 16.0),
                              Flexible(
                                child: FittedBox(
                                  child: _buildOutlinedButton(
                                    'Library',
                                    Color.fromARGB(255, 177, 55, 78),
                                    selectedButton == 'Library',
                                    () {
                                      // Correctly passing a function here
                                      setState(() {
                                        selectedButton = 'Library';
                                      });
                                    },
                                    selectedBackgroundColor: Color.fromARGB(
                                        255, 177, 55, 78), // Optional argument
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16.0),
                        ] else if (showAlternateContent) ...[
                          _buildAlternateContent(toggleContent),
                        ] else if (showListSampleContent) ...[
                          _buildListSampleContent(
                            context,
                            toggleListSampleContent,
                            toggleAddToListContent,
                            toggleEditListContent,
                            toggleContent,
                          ),
                        ] else if (showEditListContent) ...[
                          _buildEditListContent(toggleEditListContent),
                        ] else if (showSettingsContent) ...[
                          _buildSettingsContent(context, toggleSettingsContent),
                        ]
                      ],
                    ),
                  ),
                  if (!showAlternateContent &&
                      !showListSampleContent &&
                      !showAddToListContent &&
                      !showEditListContent &&
                      !showSettingsContent)
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return SingleChildScrollView(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minWidth: constraints.maxWidth,
                                minHeight: constraints.maxHeight,
                              ),
                              child: IntrinsicHeight(
                                child: Container(
                                  color: Color.fromARGB(255, 22, 23, 43),
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(height: 16.0),
                                      if (selectedButton == 'Uploads')
                                        _buildUploadsContent(context),
                                      if (selectedButton == 'Reviews')
                                        _buildReviewsContent(),
                                      if (selectedButton == 'Library')
                                        _buildLibraryContent(
                                          toggleContent,
                                          toggleListSampleContent,
                                          toggleAddToListContent,
                                          context,
                                          mapController,
                                          markers,
                                          polylines,
                                          routePoints,
                                        )
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
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
}

Widget _buildOutlinedButton(
  String text,
  Color outlineColor,
  bool isSelected,
  Function() onPressed, {
  Color selectedBackgroundColor = Colors.transparent,
}) {
  return OutlinedButton(
    onPressed: onPressed,
    style: OutlinedButton.styleFrom(
      backgroundColor: isSelected
          ? selectedBackgroundColor
          : Colors.transparent, // Background color based on selection
      side: BorderSide(color: outlineColor), // Consistent outline color
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30.0),
      ),
      minimumSize: Size(50, 30), // Minimum button size
    ),
    child: Text(
      text,
      style: TextStyle(
        color: Colors.white, // Text color
        fontSize: 12,
      ),
    ),
  );
}

Widget _buildUploadsContent(BuildContext context) {
  final screenHeight = MediaQuery.of(context).size.height;
  final containerHeight = screenHeight * 0.6;

  return Container(
    height: containerHeight,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StreamBuilder(
          stream: FirebaseFirestore.instance
              .collection('post')
              .where('userId',
                  isEqualTo: FirebaseAuth.instance.currentUser!.uid)
              .snapshots(),
          builder:
              (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
              return Expanded(
                child: ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (BuildContext context, int index) {
                    var postData = snapshot.data!.docs[index].data();
                    // Safely cast post data
                    if (postData == null) {
                      return Center(child: Text('Post data is null'));
                    }
                    var post = postData as Map<String, dynamic>;
                    var postId = snapshot.data!.docs[index].id;
                    var username = post['username'] ?? 'Unknown';
                    var imageUrl = post['imageUrl'] ?? '';
                    var caption = post['caption'] ?? 'No Caption';
                    int likes = post['likes'] ?? 0;
                    List<dynamic> likedBy = post['likedBy'] ?? [];
                    List<dynamic> comments = post['comments'] ?? [];

                    bool isExpanded = false;

                    return StatefulBuilder(
                      builder: (BuildContext context, StateSetter setState) {
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
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: Colors.white,
                                    radius: 16,
                                    child:
                                        Icon(Icons.person, color: Colors.grey),
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      username,
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                  PopupMenuButton<String>(
                                    icon: Icon(Icons.more_vert,
                                        color: Colors.white),
                                    onSelected: (value) async {
                                      if (value == 'edit') {
                                        // Show the edit caption dialog
                                        await showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                            TextEditingController
                                                captionController =
                                                TextEditingController(
                                                    text: caption);

                                            return Dialog(
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10.0),
                                              ),
                                              elevation: 16,
                                              child: Padding(
                                                padding: EdgeInsets.all(16.0),
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    TextField(
                                                      controller:
                                                          captionController,
                                                      decoration:
                                                          InputDecoration(
                                                        labelText:
                                                            'Edit Caption',
                                                        filled: true,
                                                        fillColor: Colors.white,
                                                      ),
                                                      maxLines: 3,
                                                    ),
                                                    SizedBox(height: 8),
                                                    Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .end, // Move buttons to the right
                                                      children: [
                                                        TextButton(
                                                          onPressed: () {
                                                            Navigator.pop(
                                                                context); // Close the dialog without saving
                                                          },
                                                          child: Text(
                                                            'Cancel',
                                                            style: TextStyle(
                                                                color: Colors
                                                                    .red), // Style for Cancel button
                                                          ),
                                                        ),
                                                        SizedBox(
                                                            width:
                                                                8), // Add space between the buttons
                                                        TextButton(
                                                          onPressed: () {
                                                            _updatePost(
                                                                context,
                                                                postId,
                                                                captionController
                                                                    .text);
                                                            Navigator.pop(
                                                                context); // Close the dialog
                                                          },
                                                          child: Text(
                                                            'Save',
                                                            style: TextStyle(
                                                                color: Colors
                                                                    .blue), // Style for Save button
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        );
                                      } else if (value == 'delete') {
                                        _deletePost(context, postId);
                                      }
                                    },
                                    itemBuilder: (BuildContext context) => [
                                      PopupMenuItem<String>(
                                        value: 'edit',
                                        child: Text('Edit Post'),
                                      ),
                                      PopupMenuItem<String>(
                                        value: 'delete',
                                        child: Text('Delete Post'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              Column(
                                children: [
                                  Text(
                                    isExpanded
                                        ? caption
                                        : caption.length > 100
                                            ? '${caption.substring(0, 100)}...'
                                            : caption,
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  if (caption.length > 100)
                                    InkWell(
                                      onTap: () {
                                        setState(() {
                                          isExpanded = !isExpanded;
                                        });
                                      },
                                      child: Text(
                                        isExpanded ? 'Show less' : 'Show more',
                                        style: TextStyle(color: Colors.blue),
                                      ),
                                    ),
                                ],
                              ),
                              SizedBox(height: 8),
                              Container(
                                height: 200,
                                color: Colors.grey,
                                child: imageUrl.isNotEmpty
                                    ? Image.network(
                                        imageUrl,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                      )
                                    : Center(
                                        child: Text(
                                          'No Image',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ),
                              ),
                              SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  InkWell(
                                    onTap: () async {
                                      User? user =
                                          FirebaseAuth.instance.currentUser;
                                      if (user != null) {
                                        if (!likedBy.contains(user.uid)) {
                                          await FirebaseFirestore.instance
                                              .collection('post')
                                              .doc(postId)
                                              .update({
                                            'likes': FieldValue.increment(1),
                                            'likedBy': FieldValue.arrayUnion(
                                                [user.uid])
                                          });
                                        } else {
                                          await FirebaseFirestore.instance
                                              .collection('post')
                                              .doc(postId)
                                              .update({
                                            'likes': FieldValue.increment(-1),
                                            'likedBy': FieldValue.arrayRemove(
                                                [user.uid])
                                          });
                                        }
                                      }
                                    },
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.thumb_up,
                                          color: likedBy.contains(FirebaseAuth
                                                  .instance.currentUser?.uid)
                                              ? Colors.blue
                                              : Colors.white,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                            '$likes Like${likes == 1 ? '' : 's'}',
                                            style:
                                                TextStyle(color: Colors.white)),
                                      ],
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () {
                                      _showCommentDialog(context, postId);
                                    },
                                    child: Row(
                                      children: [
                                        Icon(Icons.comment,
                                            color: Colors.white),
                                        SizedBox(width: 4),
                                        Text('Comment',
                                            style:
                                                TextStyle(color: Colors.white)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              if (comments.isNotEmpty)
                                Column(
                                  children: comments.map<Widget>((comment) {
                                    return ListTile(
                                      title: Text(comment['username']),
                                      subtitle: Text(comment['text']),
                                    );
                                  }).toList(),
                                ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              );
            }

            return Center(
                child: Text(
              'No posts available.',
              style: TextStyle(color: Colors.white),
            ));
          },
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

void _updatePost(BuildContext context, String postId, String newCaption) async {
  try {
    await FirebaseFirestore.instance.collection('post').doc(postId).update({
      'caption': newCaption,
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Post updated successfully')),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error updating post: $e')),
    );
  }
}

void _deletePost(BuildContext context, String postId) async {
  try {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Post'),
        content: Text('Are you sure you want to delete this post?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm) {
      await FirebaseFirestore.instance.collection('post').doc(postId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Post deleted successfully')),
      );
    }
  } catch (e) {
    // Handle the error if necessary
  }
}

Widget _buildReviewsContent() {
  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
        .collection('ratings')
        .where('userId', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
        .snapshots(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return Center(child: CircularProgressIndicator());
      }

      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
        return Center(
          child: Text(
            'No reviews found.',
            style: TextStyle(color: Colors.white), // Set font color to white
          ),
        );
      }

      final reviews = snapshot.data!.docs;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: reviews.map((doc) {
          final data =
              doc.data() as Map<String, dynamic>?; // Safely cast to Map

          // Check for 'placeName' and 'comment' existence and provide defaults
          final placeName = data?['placeName'] ?? 'Unknown Place';
          final comment = data?['comment'] ?? 'No comment';
          final rating = (data?['rating'] as num?)?.toDouble() ?? 0.0;
          final docId = doc.id;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                color: Color.fromRGBO(20, 20, 43, 1),
                padding: const EdgeInsets.all(16.0),
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            placeName,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8.0),
                          Text(
                            comment,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 8.0),
                          Row(
                            children: List.generate(5, (index) {
                              if (index < rating.floor()) {
                                return Icon(
                                  Icons.star,
                                  color: Colors.yellow,
                                  size: 20,
                                );
                              } else if (index < rating) {
                                return Icon(
                                  Icons.star_half,
                                  color: Colors.yellow,
                                  size: 20,
                                );
                              } else {
                                return Icon(
                                  Icons.star_border,
                                  color: Colors.yellow,
                                  size: 20,
                                );
                              }
                            }),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'delete') {
                          _deleteRating(docId);
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem<String>(
                          value: 'delete',
                          child: Text('Delete'),
                        ),
                      ],
                      icon: Icon(
                        Icons.more_vert,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Divider(
                color: Colors.white,
                thickness: 1.0,
                height: 20.0,
              ),
            ],
          );
        }).toList(),
      );
    },
  );
}

void _deleteRating(String docId) async {
  try {
    await FirebaseFirestore.instance.collection('ratings').doc(docId).delete();
  } catch (e) {
    print('Error deleting rating: $e');
  }
}

Widget _buildLibraryContent(
  VoidCallback toggleContent,
  VoidCallback toggleListSampleContent,
  VoidCallback toggleAddToListContent,
  BuildContext context,
  final mapController,
  Set<Marker> markers,
  Set<Polyline> polylines,
  List<LatLng> routePoints,
) {
  String selectedLibraryButton = 'Pins'; // Default selected button for library
  bool isListContentClicked = false; // Track if list content is clicked
  bool isListContentClicked2 = false; // Track if list content is clicked
  String clickedListContent = ''; // Track which list content is clicked
  String selectedListSubButton = ''; // Track the selected sub-button in Lists
  bool isPrivate = false;
  String? selectedListId; // Move this here to be accessible across methods

  // Fetch the current userId
  String userId = FirebaseAuth.instance.currentUser?.uid ?? '';

  return StatefulBuilder(
    builder: (BuildContext context, StateSetter setState) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildOutlinedButton(
                'Pins',
                Color.fromARGB(255, 132, 200, 172),
                selectedLibraryButton == 'Pins',
                () {
                  setState(() {
                    selectedLibraryButton = 'Pins';
                    selectedListSubButton = ''; // Reset when Pins is selected
                    isListContentClicked = false; // Reset list click state
                  });
                },
                selectedBackgroundColor: Color.fromARGB(255, 132, 200, 172),
              ),
              _buildOutlinedButton(
                'Lists',
                Color.fromARGB(255, 132, 200, 172),
                selectedLibraryButton == 'Lists',
                () {
                  setState(() {
                    selectedLibraryButton = 'Lists';
                    selectedListSubButton = '';
                    isListContentClicked = false;
                    isListContentClicked2 = false; // Reset list click state
                  });
                },
                selectedBackgroundColor: Color.fromARGB(255, 132, 200, 172),
              ),
              if (selectedLibraryButton == 'Lists') ...[
                _buildOutlinedButton(
                  'By you',
                  Color.fromARGB(255, 132, 200, 172),
                  selectedListSubButton == 'By you',
                  () {
                    setState(() {
                      selectedLibraryButton = 'Lists';
                      selectedListSubButton = 'By you'; // Select 'By you'
                      isListContentClicked = false; // Reset list click state
                      isListContentClicked2 = false;
                    });
                  },
                  selectedBackgroundColor: Color.fromARGB(255, 132, 200, 172),
                ),
                _buildOutlinedButton(
                  'By others',
                  Color.fromARGB(255, 132, 200, 172),
                  selectedListSubButton == 'By others',
                  () {
                    setState(() {
                      selectedLibraryButton = 'Lists';
                      selectedListSubButton = 'By others'; // Select 'By others'
                      isListContentClicked = false;
                      isListContentClicked2 = false; // Reset list click state
                    });
                  },
                  selectedBackgroundColor: Color.fromARGB(255, 132, 200, 172),
                ),
              ],
            ],
          ),
          SizedBox(height: 16.0),
          if (selectedLibraryButton == 'Pins') ...[
            // Fetch and display the pin content from Firestore
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('place')
                  .where('userId', isEqualTo: userId) // Filter by userId
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                      child: Text(
                    'No pins found.',
                    style: TextStyle(color: Colors.white),
                  ));
                }

                final documents = snapshot.data!.docs;

                return Column(
                  children: documents.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return Container(
                      color: Colors.transparent,
                      padding: const EdgeInsets.all(1.0),
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Icon(Icons.location_pin, color: Colors.white),
                          Text(
                            data['placeName'] ?? 'Unnamed Place',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                          PopupMenuButton<String>(
                            icon: Icon(Icons.more_vert, color: Colors.white),
                            itemBuilder: (BuildContext context) {
                              return [
                                PopupMenuItem<String>(
                                  value: 'delete',
                                  child: Text('Delete Pin'),
                                ),
                              ];
                            },
                            onSelected: (String value) {
                              if (value == 'delete') {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text('Confirm Deletion'),
                                    content: Text(
                                        'Are you sure you want to delete this pin?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          FirebaseFirestore.instance
                                              .collection(
                                                  'place') // Adjust to your collection name
                                              .doc(doc
                                                  .id) // Use the doc ID to delete the specific document
                                              .delete()
                                              .then((_) {
                                            Navigator.of(context)
                                                .pop(); // Close dialog
                                          }).catchError((error) {
                                            print(
                                                'Failed to delete pin: $error');
                                          });
                                        },
                                        child: Text('Yes'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context)
                                              .pop(); // Close dialog
                                        },
                                        child: Text('No'),
                                      ),
                                    ],
                                  ),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ] else if (selectedLibraryButton == 'Lists' &&
              !isListContentClicked &&
              !isListContentClicked2) ...[
            if (selectedListSubButton == 'By you') ...[
              // Show content specific to "By you"
              Row(
                children: [
                  Spacer(), // Push the IconButton to the right
                  IconButton(
                    icon: Icon(Icons.add, color: Colors.white),
                    onPressed: toggleContent,
                  ),
                ],
              ),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('list')
                    .where('userId',
                        isEqualTo: FirebaseAuth
                            .instance.currentUser!.uid) // Filter by user ID
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Text(
                        'No lists found',
                        style: TextStyle(color: Colors.white),
                      ),
                    );
                  }

                  final documents = snapshot.data!.docs;

                  return Column(
                    children: documents.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final String listId = doc.id; // Get the list ID
                      final bool isPremade = data['premade'] ??
                          false; // Check if 'premade' is true

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            isListContentClicked = true;
                            clickedListContent = data['name'] ?? 'Unknown';
                            selectedListId =
                                listId; // Store the selected list ID
                          });
                        },
                        child: Container(
                          color: Colors.transparent,
                          padding: const EdgeInsets.all(16.0),
                          margin: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Icon(Icons.copy, color: Colors.white),
                              Text(
                                data['name'] != null && data['name'].length > 30
                                    ? '${data['name'].substring(0, 30)}...' // Limit to 30 characters and add ellipsis
                                    : data['name'] ?? 'Unnamed List',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                                maxLines:
                                    1, // Ensure the text stays on one line
                                overflow: TextOverflow
                                    .ellipsis, // Add ellipsis if the text exceeds available space
                              ),
                              PopupMenuButton<String>(
                                icon:
                                    Icon(Icons.more_vert, color: Colors.white),
                                itemBuilder: (BuildContext context) {
                                  // Only show the delete option if 'premade' is false
                                  return [
                                    if (!isPremade)
                                      PopupMenuItem<String>(
                                        value: 'delete',
                                        child: Text('Delete List'),
                                      ),
                                  ];
                                },
                                onSelected: (String value) {
                                  if (value == 'delete') {
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: Text('Confirm Deletion'),
                                        content: Text(
                                            'Are you sure you want to delete this list?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () {
                                              FirebaseFirestore.instance
                                                  .collection(
                                                      'list') // Adjust to your collection name
                                                  .doc(doc
                                                      .id) // Use the doc ID to delete the specific document
                                                  .delete()
                                                  .then((_) {
                                                Navigator.of(context)
                                                    .pop(); // Close dialog
                                              }).catchError((error) {
                                                print(
                                                    'Failed to delete list: $error');
                                              });
                                            },
                                            child: Text('Yes'),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              Navigator.of(context)
                                                  .pop(); // Close dialog
                                            },
                                            child: Text('No'),
                                          ),
                                        ],
                                      ),
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              )
            ] else if (selectedListSubButton == 'By others') ...[
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('listbyothers')
                    .where('UserId',
                        isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                        child: Text(
                      'No lists found.',
                      style: TextStyle(color: Colors.white),
                    ));
                  }

                  final documents = snapshot.data!.docs;

                  return Column(
                    children: documents.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final String listId = data['listId']
                          as String; // Ensure this is stored in your listbyothers collection

                      return FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('list')
                            .doc(listId)
                            .get(),
                        builder: (context, listSnapshot) {
                          if (listSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Center(child: CircularProgressIndicator());
                          }
                          if (!listSnapshot.hasData ||
                              !listSnapshot.data!.exists) {
                            return SizedBox(); // Skip non-existing lists
                          }

                          final listData =
                              listSnapshot.data!.data() as Map<String, dynamic>;
                          final listName = listData['name'] ??
                              'Unnamed List'; // Fetch name from 'list' collection

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                isListContentClicked2 = true;
                                clickedListContent = listName;
                                selectedListId =
                                    listId; // Store the selected list ID
                              });
                            },
                            child: Container(
                              color: Colors.transparent,
                              padding: const EdgeInsets.all(16.0),
                              margin: const EdgeInsets.symmetric(vertical: 8.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Icon(Icons.copy, color: Colors.white),
                                  Text(
                                    listName.length > 30
                                        ? '${listName.substring(0, 30)}...' // Limit to 30 characters and add ellipsis
                                        : listName, // Use listName from 'list' collection
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                    maxLines:
                                        1, // Ensure the text stays on one line
                                    overflow: TextOverflow
                                        .ellipsis, // Add ellipsis if the text exceeds available space
                                  ),
                                  PopupMenuButton<String>(
                                    icon: Icon(Icons.more_vert,
                                        color: Colors.white),
                                    itemBuilder: (BuildContext context) {
                                      return [
                                        PopupMenuItem<String>(
                                          value: 'delete',
                                          child: Text('Delete List'),
                                        ),
                                      ];
                                    },
                                    onSelected: (String value) {
                                      if (value == 'delete') {
                                        showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: Text('Confirm Deletion'),
                                            content: Text(
                                                'Are you sure you want to delete this shared list?'),
                                            actions: [
                                              TextButton(
                                                onPressed: () {
                                                  FirebaseFirestore.instance
                                                      .collection(
                                                          'listbyothers') // Ensure this is the 'listbyothers' collection
                                                      .doc(doc
                                                          .id) // Only delete the specific entry in 'listbyothers'
                                                      .delete()
                                                      .then((_) {
                                                    Navigator.of(context)
                                                        .pop(); // Close the dialog after deletion
                                                  }).catchError((error) {
                                                    print(
                                                        'Failed to delete shared list: $error');
                                                  });
                                                },
                                                child: Text('Yes'),
                                              ),
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.of(context)
                                                      .pop(); // Close the dialog without any action
                                                },
                                                child: Text('No'),
                                              ),
                                            ],
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    }).toList(),
                  );
                },
              ),
            ] else ...[
              Row(
                children: [
                  Spacer(), // Push the IconButton to the right
                  IconButton(
                    icon: Icon(Icons.add, color: Colors.white),
                    onPressed: toggleContent,
                  ),
                ],
              ),
              // Fetch and display the list content from Firestore

              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('list')
                    .where('userId',
                        isEqualTo: FirebaseAuth
                            .instance.currentUser?.uid) // Filter by userId
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Text(
                        'No lists found',
                        style: TextStyle(color: Colors.white),
                      ),
                    );
                  }

                  final documents = snapshot.data!.docs;

                  return Column(
                    children: documents.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final String listId = doc.id; // Get the list ID

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            isListContentClicked = true;
                            clickedListContent = data['name'] ?? 'Unknown';
                            selectedListId =
                                listId; // Store the selected list ID
                          });
                        },
                        child: Container(
                          color: Colors.transparent,
                          padding: const EdgeInsets.all(16.0),
                          margin: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Icon(Icons.copy, color: Colors.white),
                              Text(
                                data['name'] != null && data['name'].length > 30
                                    ? '${data['name'].substring(0, 30)}...' // Limit to 30 characters and add ellipsis
                                    : data['name'] ?? 'Unnamed List',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                                maxLines:
                                    1, // Ensure the text stays on one line
                                overflow: TextOverflow
                                    .ellipsis, // Add ellipsis if the text exceeds available space
                              ),
                              PopupMenuButton<String>(
                                icon:
                                    Icon(Icons.more_vert, color: Colors.white),
                                itemBuilder: (BuildContext context) {
                                  return [
                                    PopupMenuItem<String>(
                                      value: 'delete',
                                      child: Text('Delete List'),
                                    ),
                                  ];
                                },
                                onSelected: (String value) {
                                  if (value == 'delete') {
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: Text('Confirm Deletion'),
                                        content: Text(
                                            'Are you sure you want to delete this list?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () {
                                              FirebaseFirestore.instance
                                                  .collection('list')
                                                  .doc(doc
                                                      .id) // Use the doc ID to delete the specific document
                                                  .delete()
                                                  .then((_) {
                                                Navigator.of(context)
                                                    .pop(); // Close dialog
                                              }).catchError((error) {
                                                print(
                                                    'Failed to delete list: $error');
                                              });
                                            },
                                            child: Text('Yes'),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                            },
                                            child: Text('No'),
                                          ),
                                        ],
                                      ),
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ] else if (isListContentClicked) ...[
            SingleChildScrollView(
              child: Container(
                color: Colors.transparent,
                padding: const EdgeInsets.all(16.0),
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.copy, color: Colors.white),
                            SizedBox(width: 8.0),
                            Text(
                              clickedListContent.length > 12
                                  ? '${clickedListContent.substring(0, 12)}...'
                                  : clickedListContent,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: Icon(Icons.send, color: Colors.white),
                          onPressed: () async {
                            Navigator.pop(context); // Close the current screen

                            try {
                              final firestore = FirebaseFirestore.instance;

                              // Query to get places matching the current listId
                              final querySnapshot = await firestore
                                  .collection('list')
                                  .doc(selectedListId)
                                  .collection('places')
                                  .get();

                              final places = querySnapshot.docs
                                  .map((doc) => doc.data())
                                  .toList();
                              final List<GeoPoint> geoPoints = places
                                  .map((place) => place['location'] as GeoPoint)
                                  .toList();

                              final List<LatLng> locations = geoPoints
                                  .map((geoPoint) => LatLng(
                                      geoPoint.latitude, geoPoint.longitude))
                                  .toList();

                              if (locations.isNotEmpty) {
                                RouteService routeService = RouteService(
                                  context: context,
                                  mapController: mapController,
                                  markers: markers,
                                  polylines: polylines,
                                  routePoints: [],
                                  apiKey:
                                      'AIzaSyANC6OfmrgsOcypf8rHrKaVCvvS89kQRMM',
                                );

                                // Create the bottom sheet state variable
                                OverlayEntry? _bottomSheetOverlayEntry;
                                ItineraryInfoBottomSheetState? bottomSheetState;
                                String estimatedTime = 'Calculating...';
                                String distance = 'Calculating...';
                                String locationName = '';

                                Offset overlayPosition = Offset(30, 30);
                                bool isMinimized = false;

                                void _showOverlay(BuildContext context) {
                                  _bottomSheetOverlayEntry = OverlayEntry(
                                    builder: (context) {
                                      return Positioned(
                                        left: overlayPosition.dx,
                                        top: overlayPosition.dy,
                                        child: Draggable(
                                          feedback:
                                              Container(), // No feedback when dragging
                                          onDragUpdate: (details) {
                                            // Increment overlay position based on drag delta
                                            overlayPosition += details.delta;
                                            _bottomSheetOverlayEntry!
                                                .markNeedsBuild();
                                          },
                                          child: SizedBox(
                                            width: isMinimized ? 70 : 340,
                                            height: isMinimized ? 70 : 298,
                                            child: Material(
                                              color: Colors.transparent,
                                              child: Column(
                                                children: [
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.end,
                                                    children: [
                                                      Container(
                                                        decoration:
                                                            BoxDecoration(
                                                          color: Colors.black
                                                              .withOpacity(0.7),
                                                          shape:
                                                              BoxShape.circle,
                                                        ),
                                                        child: IconButton(
                                                          icon: Icon(
                                                            isMinimized
                                                                ? Icons.explore
                                                                : Icons
                                                                    .minimize,
                                                            color: Colors.white,
                                                          ),
                                                          onPressed: () {
                                                            isMinimized =
                                                                !isMinimized;
                                                            _bottomSheetOverlayEntry!
                                                                .markNeedsBuild();
                                                          },
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  if (!isMinimized)
                                                    ItineraryInfoBottomSheet(
                                                      estimatedTime:
                                                          estimatedTime,
                                                      distance: distance,
                                                      destination: locationName,
                                                      routeService:
                                                          routeService,
                                                      onStateCreated: (state) {
                                                        bottomSheetState =
                                                            state;
                                                      },
                                                      onClose: () {
                                                        routeService
                                                            .cancelRoute();
                                                        _bottomSheetOverlayEntry
                                                            ?.remove();
                                                      },
                                                    ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  );

                                  Overlay.of(context)
                                      .insert(_bottomSheetOverlayEntry!);
                                }

                                _showOverlay(context);

                                await routeService.routeThroughLocations(
                                  locations,
                                  (calculatedTime, calculatedDistance,
                                      calculatedLocationName) {
                                    estimatedTime = calculatedTime;
                                    distance = calculatedDistance;
                                    locationName = calculatedLocationName;

                                    if (bottomSheetState != null) {
                                      bottomSheetState!.updateRouteInfo(
                                        estimatedTime,
                                        distance,
                                        locationName,
                                      );
                                    }
                                  },
                                );
                              } else {
                                print('No locations to route.');
                              }
                            } catch (e) {
                              print('Error fetching places or routing: $e');
                            }
                          },
                        )
                      ],
                    ),
                    SizedBox(height: 8.0),
                    FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('list')
                          .doc(selectedListId)
                          .get(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return CircularProgressIndicator();
                        }
                        if (snapshot.hasError) {
                          return Text('Error fetching user ID',
                              style: TextStyle(color: Colors.red));
                        }
                        if (!snapshot.hasData || snapshot.data == null) {
                          return Text('List data not found',
                              style: TextStyle(color: Colors.red));
                        }

                        final userId = snapshot.data!['userId'];

                        return FutureBuilder<DocumentSnapshot>(
                          future: FirebaseFirestore.instance
                              .collection('users')
                              .doc(userId)
                              .get(),
                          builder: (context, userSnapshot) {
                            if (userSnapshot.connectionState ==
                                ConnectionState.waiting) {
                              return CircularProgressIndicator();
                            }
                            if (userSnapshot.hasError) {
                              return Text('Error fetching username',
                                  style: TextStyle(color: Colors.red));
                            }
                            if (!userSnapshot.hasData ||
                                !userSnapshot.data!.exists) {
                              return Text('Username not found',
                                  style: TextStyle(color: Colors.red));
                            }

                            final username = userSnapshot.data!['username'];
                            Set<Marker> _markers = Set<Marker>();
                            Set<Polyline> _polylines = Set<Polyline>();
                            return TextButton(
                                onPressed: () {
                                  displayBottomSheet_otherprofile(
                                      context,
                                      mapController,
                                      _markers,
                                      _polylines,
                                      [],
                                      userId);
                                },
                                child: Text(
                                  'Posted by: $username',
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 12),
                                ));
                          }, // end of builder (for username FutureBuilder)
                        );
                      }, // end of builder (for userId FutureBuilder)
                    ),
                    SizedBox(height: 8.0),
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('list')
                          .doc(selectedListId)
                          .collection('places')
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        }

                        final List<QueryDocumentSnapshot> documents =
                            snapshot.data?.docs ?? [];

                        // Fetch the `premade` field from the parent 'list' document to determine visibility
                        return FutureBuilder<DocumentSnapshot>(
                          future: FirebaseFirestore.instance
                              .collection('list')
                              .doc(selectedListId)
                              .get(),
                          builder: (context, listSnapshot) {
                            if (listSnapshot.connectionState ==
                                ConnectionState.waiting) {
                              return Center(child: CircularProgressIndicator());
                            }

                            if (!listSnapshot.hasData ||
                                !listSnapshot.data!.exists) {
                              return Center(child: Text('No list found'));
                            }

                            final data = listSnapshot.data!.data()
                                as Map<String, dynamic>;
                            final bool isPremade = data['premade'] ??
                                false; // Get the premade field

                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    // Conditionally hide the delete icon if 'premade' is true
                                    if (!isPremade)
                                      IconButton(
                                        icon: Icon(Icons.delete,
                                            color: Colors.white),
                                        onPressed: () {
                                          // Show confirmation dialog
                                          showDialog(
                                            context: context,
                                            builder: (BuildContext context) {
                                              return AlertDialog(
                                                title: Text('Delete List'),
                                                content: Text(
                                                    'Are you sure you want to delete this list?'),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () {
                                                      Navigator.of(context)
                                                          .pop(); // Close dialog
                                                    },
                                                    child: Text('No'),
                                                  ),
                                                  TextButton(
                                                    onPressed: () async {
                                                      // Delete the list from Firestore
                                                      await FirebaseFirestore
                                                          .instance
                                                          .collection('list')
                                                          .doc(selectedListId)
                                                          .delete();

                                                      Navigator.of(context)
                                                          .pop(); // Close dialog
                                                      Navigator.of(context)
                                                          .pop();
                                                    },
                                                    child: Text('Yes'),
                                                  ),
                                                ],
                                              );
                                            },
                                          );
                                        },
                                      ),
                                    SizedBox(width: 4.0),
                                    // Conditionally hide the share icon if 'premade' is true
                                    if (!isPremade)
                                      IconButton(
                                        icon: Icon(Icons.share,
                                            color: Colors.white),
                                        onPressed: () {
                                          TextEditingController
                                              searchController =
                                              TextEditingController();
                                          List<DocumentSnapshot>
                                              filteredUserList =
                                              []; // New list to hold filtered results
                                          String?
                                              selectedUserId; // Allow null for initial state

                                          // Firestore user search function
                                          Future<void> searchUsers(String query,
                                              StateSetter setState) async {
                                            try {
                                              if (query.isNotEmpty) {
                                                // Fetch users based on the search query
                                                QuerySnapshot snapshot =
                                                    await FirebaseFirestore
                                                        .instance
                                                        .collection('users')
                                                        .where('username',
                                                            isGreaterThanOrEqualTo:
                                                                query)
                                                        .where('username',
                                                            isLessThanOrEqualTo:
                                                                query +
                                                                    '\uf8ff')
                                                        .get();

                                                setState(() {
                                                  filteredUserList = snapshot
                                                      .docs; // Store filtered results
                                                });
                                              } else {
                                                setState(() {
                                                  filteredUserList =
                                                      []; // Reset if no search query
                                                });
                                              }
                                            } catch (e) {
                                              print(
                                                  "Error searching users: $e");
                                            }
                                          }

                                          showDialog(
                                            context: context,
                                            builder: (BuildContext context) {
                                              bool showShareButton = false;
                                              List<bool> isChecked =
                                                  List.generate(
                                                      20, (index) => false);
                                              bool showMessage = false;

                                              return StatefulBuilder(
                                                builder: (BuildContext context,
                                                    StateSetter setState) {
                                                  return Dialog(
                                                    backgroundColor:
                                                        Colors.transparent,
                                                    child: Container(
                                                      width: 500.0,
                                                      height: 700.0,
                                                      decoration: BoxDecoration(
                                                        color: Color.fromARGB(
                                                            255, 44, 46, 86),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8.0),
                                                      ),
                                                      child: Column(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .spaceBetween,
                                                        children: [
                                                          Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                    .all(16.0),
                                                            child: TextField(
                                                              controller:
                                                                  searchController,
                                                              decoration:
                                                                  InputDecoration(
                                                                filled: true,
                                                                fillColor: Colors
                                                                    .transparent,
                                                                hintText:
                                                                    'Search...',
                                                                hintStyle: TextStyle(
                                                                    color: Colors
                                                                        .white54),
                                                                border:
                                                                    OutlineInputBorder(
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              32.0),
                                                                  borderSide:
                                                                      BorderSide(
                                                                          color:
                                                                              Colors.white),
                                                                ),
                                                                enabledBorder:
                                                                    OutlineInputBorder(
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              32.0),
                                                                  borderSide:
                                                                      BorderSide(
                                                                          color:
                                                                              Colors.white),
                                                                ),
                                                                focusedBorder:
                                                                    OutlineInputBorder(
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              32.0),
                                                                  borderSide:
                                                                      BorderSide(
                                                                          color:
                                                                              Colors.white),
                                                                ),
                                                              ),
                                                              onChanged:
                                                                  (query) {
                                                                searchUsers(
                                                                    query,
                                                                    setState); // Fetch users dynamically based on the search query
                                                              },
                                                            ),
                                                          ),
                                                          Expanded(
                                                            child: GridView
                                                                .builder(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .all(8.0),
                                                              gridDelegate:
                                                                  SliverGridDelegateWithFixedCrossAxisCount(
                                                                crossAxisCount:
                                                                    3,
                                                                mainAxisSpacing:
                                                                    8.0,
                                                                crossAxisSpacing:
                                                                    8.0,
                                                              ),
                                                              itemCount:
                                                                  filteredUserList
                                                                      .length, // Only show filtered results
                                                              itemBuilder:
                                                                  (context,
                                                                      index) {
                                                                var user = filteredUserList[
                                                                            index]
                                                                        .data()
                                                                    as Map<
                                                                        String,
                                                                        dynamic>?;

                                                                if (user ==
                                                                        null ||
                                                                    !user.containsKey(
                                                                        'username')) {
                                                                  return SizedBox(); // Handle missing username
                                                                }

                                                                String
                                                                    username =
                                                                    user[
                                                                        'username'];

                                                                return GestureDetector(
                                                                  onTap: () {
                                                                    setState(
                                                                        () {
                                                                      isChecked[
                                                                              index] =
                                                                          !isChecked[
                                                                              index];
                                                                      showShareButton =
                                                                          isChecked
                                                                              .contains(true);
                                                                      selectedUserId =
                                                                          filteredUserList[index]
                                                                              .id; // Capture the userId
                                                                    });
                                                                  },
                                                                  child: Stack(
                                                                    children: [
                                                                      Center(
                                                                        child:
                                                                            Column(
                                                                          mainAxisSize:
                                                                              MainAxisSize.min,
                                                                          children: [
                                                                            CircleAvatar(
                                                                              radius: 35,
                                                                              backgroundColor: Colors.white,
                                                                              child: Icon(
                                                                                Icons.person,
                                                                                size: 35,
                                                                                color: Color.fromARGB(255, 44, 46, 86),
                                                                              ),
                                                                            ),
                                                                            SizedBox(height: 8.0),
                                                                            Text(
                                                                              username.length > 10 ? '${username.substring(0, 10)}...' : username,
                                                                              style: TextStyle(
                                                                                color: Colors.white,
                                                                                fontSize: 7.0, // Set the desired font size here
                                                                              ),
                                                                              overflow: TextOverflow.ellipsis, // Handle overflow
                                                                            ),
                                                                          ],
                                                                        ),
                                                                      ),
                                                                      if (isChecked[
                                                                          index])
                                                                        Positioned(
                                                                          bottom:
                                                                              10, // Adjust as needed
                                                                          right:
                                                                              10, // Adjust as needed
                                                                          child:
                                                                              Icon(
                                                                            Icons.check_circle,
                                                                            color:
                                                                                Colors.green,
                                                                            size:
                                                                                20,
                                                                          ),
                                                                        ),
                                                                    ],
                                                                  ),
                                                                );
                                                              },
                                                            ),
                                                          ),
                                                          if (showShareButton)
                                                            Padding(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .all(
                                                                      16.0),
                                                              child: SizedBox(
                                                                width: double
                                                                    .infinity,
                                                                child:
                                                                    ElevatedButton(
                                                                  style: ElevatedButton
                                                                      .styleFrom(
                                                                    backgroundColor:
                                                                        Color.fromARGB(
                                                                            255,
                                                                            132,
                                                                            143,
                                                                            200),
                                                                  ),
                                                                  onPressed:
                                                                      () async {
                                                                    String?
                                                                        currentUserId =
                                                                        FirebaseAuth
                                                                            .instance
                                                                            .currentUser
                                                                            ?.uid; // Get the current user's ID
                                                                    String?
                                                                        currentListId =
                                                                        selectedListId; // Replace with the actual listId

                                                                    if (selectedUserId !=
                                                                            null &&
                                                                        currentUserId !=
                                                                            null) {
                                                                      try {
                                                                        // Upload to Firestore
                                                                        await FirebaseFirestore
                                                                            .instance
                                                                            .collection('listbyothers')
                                                                            .add({
                                                                          'listId':
                                                                              currentListId,
                                                                          'UserIdFrom':
                                                                              currentUserId,
                                                                          'UserId':
                                                                              selectedUserId, // Ensure selectedUserId is valid
                                                                        });

                                                                        setState(
                                                                            () {
                                                                          showShareButton =
                                                                              false;
                                                                          showMessage =
                                                                              true;
                                                                          isChecked = List.generate(
                                                                              13,
                                                                              (index) => false); // Reset checkmarks
                                                                        });

                                                                        Future.delayed(
                                                                            Duration(seconds: 3),
                                                                            () {
                                                                          setState(
                                                                              () {
                                                                            showMessage =
                                                                                false;
                                                                          });
                                                                        });
                                                                      } catch (e) {
                                                                        print(
                                                                            "Error uploading to Firestore: $e");
                                                                      }
                                                                    } else {
                                                                      // Handle the case where userId is null
                                                                      print(
                                                                          "Selected userId or current userId is null.");
                                                                    }
                                                                  },
                                                                  child: Text(
                                                                      'Send',
                                                                      style: TextStyle(
                                                                          color:
                                                                              Colors.white)),
                                                                ),
                                                              ),
                                                            ),
                                                          if (showMessage)
                                                            Container(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .symmetric(
                                                                      vertical:
                                                                          8.0,
                                                                      horizontal:
                                                                          16.0),
                                                              decoration:
                                                                  BoxDecoration(
                                                                color: Color
                                                                    .fromARGB(
                                                                        255,
                                                                        132,
                                                                        143,
                                                                        200),
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            8.0),
                                                              ),
                                                              width: double
                                                                  .infinity,
                                                              child: Text(
                                                                'List sent to Username.',
                                                                style:
                                                                    TextStyle(
                                                                  color: Colors
                                                                      .black,
                                                                  fontSize:
                                                                      16.0,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                ),
                                                                textAlign:
                                                                    TextAlign
                                                                        .left,
                                                              ),
                                                            ),
                                                        ],
                                                      ),
                                                    ),
                                                  );
                                                },
                                              );
                                            },
                                          );
                                        },
                                      ),
                                    // Conditionally hide the bookmark icon if 'premade' is true
                                    if (!isPremade)
                                      IconButton(
                                        icon: FutureBuilder<DocumentSnapshot>(
                                          future: FirebaseFirestore.instance
                                              .collection('listbyothers')
                                              .doc(selectedListId)
                                              .get(),
                                          builder: (context, snapshot) {
                                            if (snapshot.connectionState ==
                                                ConnectionState.waiting) {
                                              return Icon(
                                                  Icons.bookmark_outline,
                                                  color: Colors
                                                      .white); // Show unsaved icon while loading
                                            }
                                            if (snapshot.hasData &&
                                                snapshot.data!.exists) {
                                              return Icon(Icons.bookmark,
                                                  color: Colors
                                                      .white); // Show saved icon if bookmarked
                                            }
                                            return Icon(Icons.bookmark_outline,
                                                color: Colors
                                                    .white); // Show unsaved icon if not bookmarked
                                          },
                                        ),
                                        onPressed: () async {
                                          final bookmarkDocRef =
                                              FirebaseFirestore.instance
                                                  .collection('listbyothers')
                                                  .doc(selectedListId);

                                          final bookmarkSnapshot =
                                              await bookmarkDocRef.get();

                                          if (bookmarkSnapshot.exists) {
                                            // If already bookmarked, remove the bookmark
                                            await bookmarkDocRef.delete();
                                          } else {
                                            // If not bookmarked, add it to listbyothers
                                            await bookmarkDocRef.set({
                                              'listId': selectedListId,
                                              'userId': FirebaseAuth
                                                  .instance
                                                  .currentUser!
                                                  .uid, // Store current user's ID
                                            });
                                          }
                                          setState(
                                              () {}); // Trigger a rebuild to update the icon
                                        },
                                      ),
                                    SizedBox(width: 4.0),
                                    // Conditionally hide the lock/unlock icon if 'premade' is true
                                    if (!isPremade)
                                      IconButton(
                                        icon: Icon(
                                          isPrivate
                                              ? Icons.lock
                                              : Icons.lock_open,
                                          color: Colors.white,
                                        ),
                                        onPressed: () async {
                                          try {
                                            final firestore =
                                                FirebaseFirestore.instance;
                                            final listDoc = firestore
                                                .collection('list')
                                                .doc(selectedListId);

                                            // Toggle the 'isPrivate' field
                                            await listDoc.update(
                                                {'isPrivate': !isPrivate});

                                            setState(() {
                                              isPrivate = !isPrivate;
                                            });
                                          } catch (e) {
                                            print(
                                                'Error updating privacy status: $e');
                                          }
                                        },
                                      ),
                                  ],
                                ),
                                // Conditionally render the circle and plus button if there are places in the list
                                if (documents.isNotEmpty)
                                  InkWell(
                                    onTap: () {
                                      try {
                                        if (selectedListId != null &&
                                            selectedListId!.isNotEmpty) {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  _buildAddToListContent(
                                                      toggleAddToListContent,
                                                      selectedListId!,
                                                      context),
                                            ),
                                          );
                                        } else {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                                content:
                                                    Text('No list selected')),
                                          );
                                        }
                                      } catch (e) {
                                        print('Error occurred: $e');
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                              content:
                                                  Text('An error occurred')),
                                        );
                                      }
                                    },
                                    child: Visibility(
                                      visible:
                                          !isPremade, // Hide the container and icon if 'premade' is true
                                      child: Container(
                                        width: 28.0,
                                        height: 28.0,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                              color: Colors.white, width: 1.5),
                                        ),
                                        child: Center(
                                          child: Icon(
                                            Icons.add,
                                            color: Colors.white,
                                            size: 16.0,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                    Divider(color: Colors.white),
                    SizedBox(height: 24.0),
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('list')
                          .doc(selectedListId)
                          .collection('places')
                          .orderBy('order') // Ensure places are ordered
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        }

                        final List<QueryDocumentSnapshot> documents =
                            snapshot.data!.docs;

                        if (!snapshot.hasData || documents.isEmpty) {
                          return Column(
                            children: [
                              Text(
                                "Let's plan out your trip!",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 40.0),
                              TextButton(
                                onPressed: () {
                                  try {
                                    if (selectedListId != null &&
                                        selectedListId!.isNotEmpty) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              _buildAddToListContent(
                                            toggleAddToListContent,
                                            selectedListId!,
                                            context,
                                          ),
                                        ),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                            content: Text('No list selected')),
                                      );
                                    }
                                  } catch (e) {
                                    print('Error occurred: $e');
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text('An error occurred')),
                                    );
                                  }
                                },
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.symmetric(
                                      vertical: 8.0, horizontal: 16.0),
                                  backgroundColor:
                                      Color.fromARGB(255, 132, 143, 200),
                                  minimumSize: Size(200, 60),
                                ),
                                child: Text(
                                  "Add to this list",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          );
                        } else {
                          return SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: documents.map((doc) {
                                return Padding(
                                  padding:
                                      EdgeInsets.symmetric(horizontal: 8.0),
                                  child: GestureDetector(
                                    child: Container(
                                      height: 320,
                                      width: 320.0,
                                      padding: EdgeInsets.all(16.0),
                                      decoration: BoxDecoration(
                                        color:
                                            Color.fromARGB(255, 90, 111, 132),
                                        borderRadius:
                                            BorderRadius.circular(12.0),
                                      ),
                                      child: Stack(
                                        children: [
                                          Positioned(
                                            top: 16.0,
                                            left: 16.0,
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  doc['name'] ?? 'Place Name',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 16.0,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                SizedBox(height: 8.0),
                                              ],
                                            ),
                                          ),
                                          Positioned(
                                            top: 80.0,
                                            left: 0.0,
                                            right: 0.0,
                                            child: Container(
                                              width: 200.0,
                                              height: 200.0,
                                              decoration: BoxDecoration(
                                                color: Colors.black,
                                                borderRadius:
                                                    BorderRadius.circular(12.0),
                                              ),
                                              child: doc['imageUrl'] != null &&
                                                      doc['imageUrl'] != ''
                                                  ? ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12.0),
                                                      child: Image.network(
                                                        doc['imageUrl'],
                                                        fit: BoxFit.cover,
                                                      ),
                                                    )
                                                  : Center(
                                                      child: Text(
                                                        'Placeholder Image',
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 16.0,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                            ),
                                          ),
                                          // Fetch the 'premade' field from the parent list document
                                          FutureBuilder<DocumentSnapshot>(
                                            future: FirebaseFirestore.instance
                                                .collection('list')
                                                .doc(selectedListId)
                                                .get(),
                                            builder: (context, listSnapshot) {
                                              if (listSnapshot
                                                      .connectionState ==
                                                  ConnectionState.waiting) {
                                                return Center(
                                                    child:
                                                        CircularProgressIndicator());
                                              }

                                              if (!listSnapshot.hasData ||
                                                  !listSnapshot.data!.exists) {
                                                return Container(); // Or handle no data case
                                              }

                                              final data =
                                                  listSnapshot.data!.data()
                                                      as Map<String, dynamic>;
                                              final bool isPremade = data[
                                                      'premade'] ??
                                                  false; // Get the 'premade' field

                                              return Positioned(
                                                top: 8.0,
                                                right: 8.0,
                                                child: Visibility(
                                                  visible:
                                                      !isPremade, // Hide the delete icon if 'premade' is true
                                                  child: IconButton(
                                                    icon: Icon(
                                                      Icons.delete,
                                                      color: Colors.white,
                                                    ),
                                                    onPressed: () {
                                                      // Show confirmation dialog before deletion
                                                      showDialog(
                                                        context: context,
                                                        builder: (context) =>
                                                            AlertDialog(
                                                          title: Text(
                                                              'Confirm Deletion'),
                                                          content: Text(
                                                              'Are you sure you want to delete this place?'),
                                                          actions: [
                                                            TextButton(
                                                              onPressed: () {
                                                                // Perform deletion
                                                                FirebaseFirestore
                                                                    .instance
                                                                    .collection(
                                                                        'list')
                                                                    .doc(
                                                                        selectedListId)
                                                                    .collection(
                                                                        'places')
                                                                    .doc(doc.id)
                                                                    .delete()
                                                                    .then((_) {
                                                                  Navigator.of(
                                                                          context)
                                                                      .pop(); // Close dialog
                                                                }).catchError(
                                                                        (error) {
                                                                  // Handle error if needed
                                                                  print(
                                                                      'Failed to delete place: $error');
                                                                });
                                                              },
                                                              child: Text(
                                                                  'Delete'),
                                                            ),
                                                            TextButton(
                                                              onPressed: () {
                                                                Navigator.of(
                                                                        context)
                                                                    .pop(); // Close dialog
                                                              },
                                                              child: Text(
                                                                  'Cancel'),
                                                            ),
                                                          ],
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          );
                        }
                      },
                    ),
                    SizedBox(height: 60.0),
                    SizedBox(height: 16.0),
                  ],
                ),
              ),
            ),
          ] else if (isListContentClicked2) ...[
            SingleChildScrollView(
              child: Container(
                color: Colors.transparent,
                padding: const EdgeInsets.all(16.0),
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.copy, color: Colors.white),
                            SizedBox(width: 8.0),
                            Text(
                              clickedListContent.length > 12
                                  ? '${clickedListContent.substring(0, 12)}...'
                                  : clickedListContent,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: Icon(Icons.send, color: Colors.white),
                          onPressed: () async {
                            Navigator.pop(context); // Close the current screen

                            try {
                              final firestore = FirebaseFirestore.instance;

                              // Query to get places matching the current listId
                              final querySnapshot = await firestore
                                  .collection('list')
                                  .doc(selectedListId)
                                  .collection('places')
                                  .get();

                              final places = querySnapshot.docs
                                  .map((doc) => doc.data())
                                  .toList();
                              final List<GeoPoint> geoPoints = places
                                  .map((place) => place['location'] as GeoPoint)
                                  .toList();

                              final List<LatLng> locations = geoPoints
                                  .map((geoPoint) => LatLng(
                                      geoPoint.latitude, geoPoint.longitude))
                                  .toList();

                              if (locations.isNotEmpty) {
                                RouteService routeService = RouteService(
                                  context: context,
                                  mapController: mapController,
                                  markers: markers,
                                  polylines: polylines,
                                  routePoints: [],
                                  apiKey:
                                      'AIzaSyANC6OfmrgsOcypf8rHrKaVCvvS89kQRMM',
                                );

                                // Create the bottom sheet state variable
                                OverlayEntry? _bottomSheetOverlayEntry;
                                ItineraryInfoBottomSheetState? bottomSheetState;
                                String estimatedTime = 'Calculating...';
                                String distance = 'Calculating...';
                                String locationName = '';

                                Offset overlayPosition = Offset(30, 30);
                                bool isMinimized = false;

                                void _showOverlay(BuildContext context) {
                                  _bottomSheetOverlayEntry = OverlayEntry(
                                    builder: (context) {
                                      return Positioned(
                                        left: overlayPosition.dx,
                                        top: overlayPosition.dy,
                                        child: Draggable(
                                          feedback:
                                              Container(), // No feedback when dragging
                                          onDragUpdate: (details) {
                                            // Increment overlay position based on drag delta
                                            overlayPosition += details.delta;
                                            _bottomSheetOverlayEntry!
                                                .markNeedsBuild();
                                          },
                                          child: SizedBox(
                                            width: isMinimized ? 70 : 300,
                                            height: isMinimized ? 70 : 400,
                                            child: Material(
                                              color: Colors.transparent,
                                              child: Column(
                                                children: [
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.end,
                                                    children: [
                                                      Container(
                                                        decoration:
                                                            BoxDecoration(
                                                          color: Colors.black
                                                              .withOpacity(0.7),
                                                          shape:
                                                              BoxShape.circle,
                                                        ),
                                                        child: IconButton(
                                                          icon: Icon(
                                                            isMinimized
                                                                ? Icons.explore
                                                                : Icons
                                                                    .minimize,
                                                            color: Colors.white,
                                                          ),
                                                          onPressed: () {
                                                            isMinimized =
                                                                !isMinimized;
                                                            _bottomSheetOverlayEntry!
                                                                .markNeedsBuild();
                                                          },
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  if (!isMinimized)
                                                    ItineraryInfoBottomSheet(
                                                      estimatedTime:
                                                          estimatedTime,
                                                      distance: distance,
                                                      destination: locationName,
                                                      routeService:
                                                          routeService,
                                                      onStateCreated: (state) {
                                                        bottomSheetState =
                                                            state;
                                                      },
                                                      onClose: () {
                                                        routeService
                                                            .cancelRoute();
                                                        _bottomSheetOverlayEntry
                                                            ?.remove();
                                                      },
                                                    ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  );

                                  Overlay.of(context)
                                      .insert(_bottomSheetOverlayEntry!);
                                }

                                _showOverlay(context);

                                await routeService.routeThroughLocations(
                                  locations,
                                  (calculatedTime, calculatedDistance,
                                      calculatedLocationName) {
                                    estimatedTime = calculatedTime;
                                    distance = calculatedDistance;
                                    locationName = calculatedLocationName;

                                    if (bottomSheetState != null) {
                                      bottomSheetState!.updateRouteInfo(
                                        estimatedTime,
                                        distance,
                                        locationName,
                                      );
                                    }
                                  },
                                );
                              } else {
                                print('No locations to route.');
                              }
                            } catch (e) {
                              print('Error fetching places or routing: $e');
                            }
                          },
                        )
                      ],
                    ),
                    SizedBox(height: 8.0),
                    FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('list')
                          .doc(selectedListId)
                          .get(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return CircularProgressIndicator();
                        }
                        if (snapshot.hasError) {
                          return Text('Error fetching user ID',
                              style: TextStyle(color: Colors.red));
                        }
                        if (!snapshot.hasData || snapshot.data == null) {
                          return Text('List data not found',
                              style: TextStyle(color: Colors.red));
                        }

                        final userId = snapshot.data!['userId'];

                        return FutureBuilder<DocumentSnapshot>(
                          future: FirebaseFirestore.instance
                              .collection('users')
                              .doc(userId)
                              .get(),
                          builder: (context, userSnapshot) {
                            if (userSnapshot.connectionState ==
                                ConnectionState.waiting) {
                              return CircularProgressIndicator();
                            }
                            if (userSnapshot.hasError) {
                              return Text('Error fetching username',
                                  style: TextStyle(color: Colors.red));
                            }
                            if (!userSnapshot.hasData ||
                                !userSnapshot.data!.exists) {
                              return Text('Username not found',
                                  style: TextStyle(color: Colors.red));
                            }

                            final username = userSnapshot.data!['username'];
                            Set<Marker> _markers = Set<Marker>();
                            Set<Polyline> _polylines = Set<Polyline>();
                            return TextButton(
                                onPressed: () {
                                  displayBottomSheet_otherprofile(
                                      context,
                                      mapController,
                                      _markers,
                                      _polylines,
                                      [],
                                      userId);
                                },
                                child: Text(
                                  'Posted by: $username',
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 18),
                                ));
                          }, // end of builder (for username FutureBuilder)
                        );
                      }, // end of builder (for userId FutureBuilder)
                    ),
                    SizedBox(height: 8.0),
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('list')
                          .doc(selectedListId)
                          .collection('places')
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        }

                        final List<QueryDocumentSnapshot> documents =
                            snapshot.data?.docs ?? [];

                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                SizedBox(width: 4.0),
                                IconButton(
                                  icon: FutureBuilder<DocumentSnapshot>(
                                    future: FirebaseFirestore.instance
                                        .collection('list')
                                        .doc(selectedListId)
                                        .get(),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return Icon(Icons.bookmark_outline,
                                            color: Colors
                                                .white); // Show unsaved icon while loading
                                      }
                                      if (snapshot.hasData &&
                                          snapshot.data!.exists) {
                                        return Icon(Icons.bookmark,
                                            color: Colors
                                                .white); // Show saved icon if bookmarked
                                      }
                                      return Icon(Icons.bookmark_outline,
                                          color: Colors
                                              .white); // Show unsaved icon if not bookmarked
                                    },
                                  ),
                                  onPressed: () async {
                                    final bookmarkDocRef = FirebaseFirestore
                                        .instance
                                        .collection('list')
                                        .doc(selectedListId);

                                    final bookmarkSnapshot =
                                        await bookmarkDocRef.get();

                                    if (bookmarkSnapshot.exists) {
                                      // If already bookmarked, remove the bookmark
                                      await bookmarkDocRef.delete();
                                    } else {
                                      // If not bookmarked, add it to listbyothers
                                      await bookmarkDocRef.set({
                                        'listId': selectedListId,
                                        'userId': FirebaseAuth
                                            .instance
                                            .currentUser!
                                            .uid, // Store current user's ID
                                      });
                                    }
                                    setState(
                                        () {}); // Trigger a rebuild to update the icon
                                  },
                                ),
                                IconButton(
                                  icon: Icon(Icons.share, color: Colors.white),
                                  onPressed: () {
                                    TextEditingController searchController =
                                        TextEditingController();
                                    List<DocumentSnapshot> userList = [];
                                    List<DocumentSnapshot> filteredUserList =
                                        []; // New list to hold filtered results
                                    String?
                                        selectedUserId; // Allow null for initial state

                                    // Firestore user search function

                                    // Function to fetch initial users when the dialog opens
                                    Future<void> fetchInitialUsers(
                                        StateSetter setState) async {
                                      try {
                                        QuerySnapshot snapshot =
                                            await FirebaseFirestore.instance
                                                .collection('users')
                                                .get();
                                        setState(() {
                                          userList =
                                              snapshot.docs; // Store all users
                                          filteredUserList = List.from(
                                              userList); // Show all users initially
                                        });
                                        print(
                                            "Fetched ${snapshot.docs.length} initial users.");
                                      } catch (e) {
                                        print(
                                            "Error fetching initial users: $e");
                                      }
                                    }

// Search function to filter users based on the search query
                                    void searchUsers(
                                        String query, StateSetter setState) {
                                      setState(() {
                                        if (query.isNotEmpty) {
                                          filteredUserList =
                                              userList.where((userDoc) {
                                            String username = (userDoc.data()
                                                    as Map<String,
                                                        dynamic>)['username'] ??
                                                '';
                                            return username
                                                .toLowerCase()
                                                .contains(query
                                                    .toLowerCase()); // Case insensitive search
                                          }).toList();
                                        } else {
                                          filteredUserList = List.from(
                                              userList); // Reset to original if no query
                                        }
                                      });
                                    }

                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        bool showShareButton = false;
                                        List<bool> isChecked =
                                            List.generate(20, (index) => false);
                                        bool showMessage = false;

                                        return StatefulBuilder(
                                          builder: (BuildContext context,
                                              StateSetter setState) {
                                            fetchInitialUsers(
                                                setState); // Fetch initial users once when the dialog opens
                                            return Dialog(
                                              backgroundColor:
                                                  Colors.transparent,
                                              child: Container(
                                                width: 500.0,
                                                height: 700.0,
                                                decoration: BoxDecoration(
                                                  color: Color.fromARGB(
                                                      255, 44, 46, 86),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          8.0),
                                                ),
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              16.0),
                                                      child: TextField(
                                                        controller:
                                                            searchController,
                                                        decoration:
                                                            InputDecoration(
                                                          filled: true,
                                                          fillColor: Colors
                                                              .transparent,
                                                          hintText: 'Search...',
                                                          hintStyle: TextStyle(
                                                              color: Colors
                                                                  .white54),
                                                          border:
                                                              OutlineInputBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        32.0),
                                                            borderSide:
                                                                BorderSide(
                                                                    color: Colors
                                                                        .white),
                                                          ),
                                                          enabledBorder:
                                                              OutlineInputBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        32.0),
                                                            borderSide:
                                                                BorderSide(
                                                                    color: Colors
                                                                        .white),
                                                          ),
                                                          focusedBorder:
                                                              OutlineInputBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        32.0),
                                                            borderSide:
                                                                BorderSide(
                                                                    color: Colors
                                                                        .white),
                                                          ),
                                                        ),
                                                        onChanged: (query) {
                                                          searchUsers(query,
                                                              setState); // Pass the setState to update the user list
                                                        },
                                                      ),
                                                    ),
                                                    Expanded(
                                                      child: GridView.builder(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(8.0),
                                                        gridDelegate:
                                                            SliverGridDelegateWithFixedCrossAxisCount(
                                                          crossAxisCount: 3,
                                                          mainAxisSpacing: 8.0,
                                                          crossAxisSpacing: 8.0,
                                                        ),
                                                        itemCount: filteredUserList
                                                            .length, // Show only filtered results
                                                        itemBuilder:
                                                            (context, index) {
                                                          var user =
                                                              filteredUserList[
                                                                          index]
                                                                      .data()
                                                                  as Map<String,
                                                                      dynamic>?;

                                                          if (user == null ||
                                                              !user.containsKey(
                                                                  'username')) {
                                                            return SizedBox(); // Handle missing username
                                                          }

                                                          String username =
                                                              user['username'];

                                                          return GestureDetector(
                                                            onTap: () {
                                                              setState(() {
                                                                isChecked[
                                                                        index] =
                                                                    !isChecked[
                                                                        index];
                                                                showShareButton =
                                                                    isChecked
                                                                        .contains(
                                                                            true);
                                                                selectedUserId =
                                                                    filteredUserList[
                                                                            index]
                                                                        .id; // Capture the userId
                                                              });
                                                            },
                                                            child: Stack(
                                                              children: [
                                                                Center(
                                                                  child: Column(
                                                                    mainAxisSize:
                                                                        MainAxisSize
                                                                            .min,
                                                                    children: [
                                                                      CircleAvatar(
                                                                        radius:
                                                                            35,
                                                                        backgroundColor:
                                                                            Colors.white,
                                                                        child:
                                                                            Icon(
                                                                          Icons
                                                                              .person,
                                                                          size:
                                                                              35,
                                                                          color: Color.fromARGB(
                                                                              255,
                                                                              44,
                                                                              46,
                                                                              86),
                                                                        ),
                                                                      ),
                                                                      SizedBox(
                                                                          height:
                                                                              8.0),
                                                                      Text(
                                                                        username.length >
                                                                                10
                                                                            ? '${username.substring(0, 10)}...'
                                                                            : username,
                                                                        style:
                                                                            TextStyle(
                                                                          color:
                                                                              Colors.white,
                                                                          fontSize:
                                                                              7.0, // Set the desired font size here
                                                                        ),
                                                                        overflow:
                                                                            TextOverflow.ellipsis, // Handle overflow
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                                if (isChecked[
                                                                    index])
                                                                  Positioned(
                                                                    bottom:
                                                                        10, // Adjust as needed
                                                                    right:
                                                                        10, // Adjust as needed
                                                                    child: Icon(
                                                                      Icons
                                                                          .check_circle,
                                                                      color: Colors
                                                                          .green,
                                                                      size: 20,
                                                                    ),
                                                                  ),
                                                              ],
                                                            ),
                                                          );
                                                        },
                                                      ),
                                                    ),
                                                    if (showShareButton)
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(16.0),
                                                        child: SizedBox(
                                                          width:
                                                              double.infinity,
                                                          child: ElevatedButton(
                                                            style:
                                                                ElevatedButton
                                                                    .styleFrom(
                                                              backgroundColor:
                                                                  Color
                                                                      .fromARGB(
                                                                          255,
                                                                          132,
                                                                          143,
                                                                          200),
                                                            ),
                                                            onPressed:
                                                                () async {
                                                              String?
                                                                  currentUserId =
                                                                  FirebaseAuth
                                                                      .instance
                                                                      .currentUser
                                                                      ?.uid; // Get the current user's ID
                                                              String?
                                                                  currentListId =
                                                                  selectedListId; // Replace with the actual listId

                                                              if (selectedUserId !=
                                                                      null &&
                                                                  currentUserId !=
                                                                      null) {
                                                                try {
                                                                  // Upload to Firestore
                                                                  await FirebaseFirestore
                                                                      .instance
                                                                      .collection(
                                                                          'listbyothers')
                                                                      .add({
                                                                    'listId':
                                                                        currentListId,
                                                                    'UserIdFrom':
                                                                        currentUserId,
                                                                    'UserId':
                                                                        selectedUserId, // Ensure selectedUserId is valid
                                                                  });

                                                                  setState(() {
                                                                    showShareButton =
                                                                        false;
                                                                    showMessage =
                                                                        true;
                                                                    isChecked = List.generate(
                                                                        13,
                                                                        (index) =>
                                                                            false); // Reset checkmarks
                                                                  });

                                                                  Future.delayed(
                                                                      Duration(
                                                                          seconds:
                                                                              3),
                                                                      () {
                                                                    setState(
                                                                        () {
                                                                      showMessage =
                                                                          false;
                                                                    });
                                                                  });
                                                                } catch (e) {
                                                                  print(
                                                                      "Error uploading to Firestore: $e");
                                                                }
                                                              } else {
                                                                // Handle the case where userId is null
                                                                print(
                                                                    "Selected userId or current userId is null.");
                                                              }
                                                            },
                                                            child: Text('Send',
                                                                style: TextStyle(
                                                                    color: Colors
                                                                        .white)),
                                                          ),
                                                        ),
                                                      ),
                                                    if (showMessage)
                                                      Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                vertical: 8.0,
                                                                horizontal:
                                                                    16.0),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: Color.fromARGB(
                                                              255,
                                                              132,
                                                              143,
                                                              200),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      8.0),
                                                        ),
                                                        width: double.infinity,
                                                        child: Text(
                                                          'List sent to Username.',
                                                          style: TextStyle(
                                                            color: Colors.black,
                                                            fontSize: 16.0,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                          textAlign:
                                                              TextAlign.left,
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        );
                                      },
                                    );
                                  },
                                ),
                              ],
                            ),
                            if (documents.isNotEmpty)
                              InkWell(
                                onTap: () {},
                                child: Container(
                                  width: 28.0,
                                  height: 28.0,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.transparent,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Center(
                                    child: Icon(
                                      Icons.add,
                                      color: Colors.transparent,
                                      size: 16.0,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                    Divider(color: Colors.white),
                    SizedBox(height: 24.0),
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('list')
                          .doc(selectedListId)
                          .collection('places')
                          .orderBy('order') // Ensure places are ordered
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        }

                        final List<QueryDocumentSnapshot> documents =
                            snapshot.data!.docs;

                        if (!snapshot.hasData || documents.isEmpty) {
                          return Column(
                            children: [
                              Text(
                                "This list is empty.",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 40.0),
                            ],
                          );
                        } else {
                          return SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: documents.map((doc) {
                                return Padding(
                                  padding:
                                      EdgeInsets.symmetric(horizontal: 8.0),
                                  child: GestureDetector(
                                    child: Container(
                                      height: 320,
                                      width: 320.0,
                                      padding: EdgeInsets.all(16.0),
                                      decoration: BoxDecoration(
                                        color:
                                            Color.fromARGB(255, 90, 111, 132),
                                        borderRadius:
                                            BorderRadius.circular(12.0),
                                      ),
                                      child: Stack(
                                        children: [
                                          Positioned(
                                            top: 16.0,
                                            left: 16.0,
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  doc['name'] ?? 'Place Name',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 16.0,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                SizedBox(height: 8.0),
                                              ],
                                            ),
                                          ),
                                          Positioned(
                                            top: 80.0,
                                            left: 0.0,
                                            right: 0.0,
                                            child: Container(
                                              width: 200.0,
                                              height: 200.0,
                                              decoration: BoxDecoration(
                                                color: Colors.black,
                                                borderRadius:
                                                    BorderRadius.circular(12.0),
                                              ),
                                              child: doc['imageUrl'] != null &&
                                                      doc['imageUrl'] != ''
                                                  ? ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12.0),
                                                      child: Image.network(
                                                        doc['imageUrl'],
                                                        fit: BoxFit.cover,
                                                      ),
                                                    )
                                                  : Center(
                                                      child: Text(
                                                        'Placeholder Image',
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 16.0,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          );
                        }
                      },
                    ),
                    SizedBox(height: 60.0),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Recommended Places",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(height: 16.0),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          Container(
                            height: 320,
                            width: 320.0,
                            padding: EdgeInsets.all(16.0),
                            decoration: BoxDecoration(
                              color: Color.fromARGB(255, 90, 111, 132),
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            child: Stack(
                              children: [
                                Positioned(
                                  top: 16.0,
                                  left: 16.0,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Place Name 1',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 18.0,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 8.0),
                                      Text(
                                        'address',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14.0,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Positioned(
                                  top: 80.0,
                                  left: 0.0,
                                  right: 0.0,
                                  child: Container(
                                    width: 200.0,
                                    height: 200.0,
                                    decoration: BoxDecoration(
                                      color: Colors.black,
                                      borderRadius: BorderRadius.circular(12.0),
                                    ),
                                    child: Center(
                                      child: Text(
                                        'Placeholder Image',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16.0,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 16.0),
                          Container(
                            height: 320,
                            width: 320.0,
                            padding: EdgeInsets.all(16.0),
                            decoration: BoxDecoration(
                              color: Color.fromARGB(255, 90, 111, 132),
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            child: Stack(
                              children: [
                                Positioned(
                                  top: 16.0,
                                  left: 16.0,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Place Name 2',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 18.0,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 8.0),
                                      Text(
                                        'address',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14.0,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Positioned(
                                  top: 80.0,
                                  left: 0.0,
                                  right: 0.0,
                                  child: Container(
                                    width: 200.0,
                                    height: 200.0,
                                    decoration: BoxDecoration(
                                      color: Colors.black,
                                      borderRadius: BorderRadius.circular(12.0),
                                    ),
                                    child: Center(
                                      child: Text(
                                        'Placeholder Image',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16.0,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16.0),
                  ],
                ),
              ),
            ),
          ],
        ],
      );
    },
  );
}

// Helper methods and widgets

Widget _buildListItem(String text) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: Text(
      text,
      style: TextStyle(
        color: Colors.white,
        fontSize: 16,
      ),
    ),
  );
}

final TextEditingController _nameController = TextEditingController();
final FirebaseFirestore _firestore = FirebaseFirestore.instance;
final FirebaseAuth _auth = FirebaseAuth.instance;

Widget _buildAlternateContent(VoidCallback toggleContent) {
  // List of month abbreviations
  final List<String> months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec'
  ];

  // Controllers and state variables

  int _selectedDay = 1;
  String _selectedMonth = 'Jan';
  int _selectedYear = 2024;
  bool _isPrivate = false;

  // Function to format the date
  String _formatDate() {
    return '$_selectedDay $_selectedMonth $_selectedYear';
  }

  // Function to handle data upload to Firestore
  Future<void> _uploadData(BuildContext context) async {
    final String userId = _auth.currentUser?.uid ?? 'unknown_user';
    final String listId =
        _firestore.collection('list').doc().id; // Generate a unique ID

    final listItem = {
      'name': _nameController.text,
      'date': _formatDate(),
      'isPrivate': _isPrivate,
      'userId': userId,
      'listId': listId,
    };

    if (_nameController.text.isEmpty) {
      return;
    }

    try {
      await _firestore.collection('list').doc(listId).set(listItem);

      // Optionally clear the fields or navigate away
      _nameController.clear();
    } catch (e) {
      print('Error uploading data: $e');
    }
  }

  // Function to show dialog
  void _showDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  return StatefulBuilder(
    builder: (context, setState) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 16),
          Text(
            'List Name',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
          SizedBox(height: 8),
          TextField(
            controller: _nameController,
            style: TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Enter text...',
              hintStyle: TextStyle(
                color: Colors.white.withOpacity(0.7),
              ),
              border: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white),
              ),
            ),
          ),
          SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white),
            ),
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Privacy',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Choose whether your list can be accessed by other users.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
                SizedBox(height: 16),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Switch(
                    value: _isPrivate,
                    onChanged: (value) {
                      setState(() {
                        _isPrivate = value;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: toggleContent,
                  style: ButtonStyle(
                    backgroundColor:
                        MaterialStateProperty.all(Colors.transparent),
                    foregroundColor: MaterialStateProperty.all(Colors.white),
                    minimumSize: MaterialStateProperty.all(Size(150, 38)),
                    side: MaterialStateProperty.all(
                        BorderSide(color: Colors.red)),
                    shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                  child: Text('Cancel'),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    _uploadData(context);
                    toggleContent();
                    // Pass context to _uploadData
                  },
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(
                        Color.fromARGB(255, 132, 143, 200)),
                    foregroundColor: MaterialStateProperty.all(Colors.white),
                    minimumSize: MaterialStateProperty.all(Size(150, 38)),
                    shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                  child: Text('Create'),
                ),
              ],
            ),
          ),
        ],
      );
    },
  );
}

Widget _buildListSampleContent(
    BuildContext context,
    VoidCallback toggleListSampleContent,
    VoidCallback toggleAddToListContent,
    VoidCallback toggleEditListContent,
    VoidCallback toggleContent) {
  bool showMessage = false; // Initialize the showMessage variable

  return StatefulBuilder(
    builder: (BuildContext context, StateSetter setState) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            onPressed: toggleListSampleContent,
            icon: Icon(Icons.arrow_back, color: Colors.white),
          ),
          Center(
            child: Text(
              'List Sample Content',
              style: TextStyle(
                color: Colors.white,
                fontSize: 27,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListTile(
            leading: Icon(Icons.lock, color: Colors.white),
            title: Text(
              'Make Private',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold),
            ),
            trailing: Switch(value: false, onChanged: (value) {}),
          ),
          ListTile(
            leading: Icon(Icons.add, color: Colors.white),
            title: Text(
              'Add to this list',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold),
            ),
            onTap: toggleAddToListContent,
          ),
          ListTile(
            leading: Icon(Icons.edit, color: Colors.white),
            title: Text(
              'Edit List',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold),
            ),
            onTap: toggleEditListContent,
          ),
          ListTile(
            leading: Icon(Icons.share, color: Colors.white),
            title: Text(
              'Share',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold),
            ),
            onTap: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  bool showShareButton = false;
                  List<bool> isChecked = List.generate(9, (index) => false);
                  bool showMessage = false;

                  return StatefulBuilder(
                    builder: (BuildContext context, StateSetter setState) {
                      return Dialog(
                        backgroundColor: Colors.transparent,
                        child: Container(
                          width: 500.0,
                          height: 700.0,
                          decoration: BoxDecoration(
                            color: Color.fromARGB(255, 44, 46, 86),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: TextField(
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: Colors.transparent,
                                    hintText: 'Search...',
                                    hintStyle: TextStyle(color: Colors.white54),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(32.0),
                                      borderSide:
                                          BorderSide(color: Colors.white),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(32.0),
                                      borderSide:
                                          BorderSide(color: Colors.white),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(32.0),
                                      borderSide:
                                          BorderSide(color: Colors.white),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: GridView.builder(
                                  padding: const EdgeInsets.all(8.0),
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3,
                                    mainAxisSpacing: 8.0,
                                    crossAxisSpacing: 8.0,
                                  ),
                                  itemCount: 9,
                                  itemBuilder: (context, index) {
                                    return GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          isChecked[index] = !isChecked[index];
                                          showShareButton =
                                              isChecked.contains(true);
                                        });
                                      },
                                      child: Stack(
                                        children: [
                                          Center(
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                CircleAvatar(
                                                  radius: 35,
                                                  backgroundColor: Colors.white,
                                                  child: Icon(
                                                    Icons.person,
                                                    size: 35,
                                                    color: Color.fromARGB(
                                                        255, 44, 46, 86),
                                                  ),
                                                ),
                                                SizedBox(height: 8.0),
                                                Text(
                                                  'Name $index',
                                                  style: TextStyle(
                                                      color: Colors.white),
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (isChecked[index])
                                            Positioned(
                                              bottom: 10, // Adjust as needed
                                              right: 10, // Adjust as needed
                                              child: Icon(
                                                Icons.check_circle,
                                                color: Colors.green,
                                                size: 20,
                                              ),
                                            ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                              if (showShareButton)
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: SizedBox(
                                    width: double.infinity, // Use full width
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                          backgroundColor: Color.fromARGB(
                                              255, 132, 143, 200)),
                                      onPressed: () {
                                        setState(() {
                                          showShareButton = false;
                                          showMessage = true;
                                          isChecked = List.generate(
                                              9,
                                              (index) =>
                                                  false); // Reset the checkmarks
                                        });

                                        // Hide the message after 3 seconds
                                        Future.delayed(Duration(seconds: 3),
                                            () {
                                          setState(() {
                                            showMessage = false;
                                          });
                                        });
                                      },
                                      child: Text('Send',
                                          style:
                                              TextStyle(color: Colors.white)),
                                    ),
                                  ),
                                ),
                              if (showMessage)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 8.0, horizontal: 16.0),
                                  decoration: BoxDecoration(
                                    color: Color.fromARGB(
                                        255, 132, 143, 200), // Background color
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                  width: double.infinity, // Use full width
                                  child: Text(
                                    'List sent to Username.',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 16.0,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign:
                                        TextAlign.left, // Center align text
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.close, color: Colors.red),
            title: Text(
              'Delete List',
              style: TextStyle(
                  color: Colors.red, fontSize: 24, fontWeight: FontWeight.bold),
            ),
            onTap: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    backgroundColor: Color.fromARGB(255, 44, 46, 86),
                    title: Text('Delete List',
                        style: TextStyle(color: Colors.white)),
                    content: Text('Are you sure you want to delete List #1?',
                        style: TextStyle(
                          color: Colors.white,
                        )),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(); // Close the dialog
                        },
                        child: Text('CANCEL',
                            style: TextStyle(color: Colors.white)),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            showMessage = true; // Show the message
                          });
                          Navigator.of(context).pop(); // Close the dialog

                          // Hide the message after 3 seconds
                          Future.delayed(Duration(seconds: 3), () {
                            setState(() {
                              showMessage = false; // Hide the message
                            });
                          });
                        },
                        child: Text('DELETE',
                            style: TextStyle(
                                color: Color.fromARGB(
                                    255, 255, 0, 0))), // Make button text red
                      ),
                    ],
                  );
                },
              );
            },
          ),
          if (showMessage)
            Container(
              padding:
                  const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              decoration: BoxDecoration(
                color: Color.fromARGB(255, 132, 143, 200), // Background color
                borderRadius: BorderRadius.circular(8.0),
              ),
              width: double.infinity, // Use full width
              child: Text(
                'List item deleted.',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.left, // Align text to the left
              ),
            ),
        ],
      );
    },
  );
}

class SearchTextField extends StatefulWidget {
  final TextEditingController controller;
  final String apiKey;
  final Function(List<Map<String, dynamic>>) onSuggestionsUpdate;
  final String currentListId;
  final Function(Map<String, dynamic>) onAddPlace;

  SearchTextField({
    required this.controller,
    required this.apiKey,
    required this.onSuggestionsUpdate,
    required this.currentListId,
    required this.onAddPlace,
  });

  @override
  _SearchTextFieldState createState() => _SearchTextFieldState();
}

class _SearchTextFieldState extends State<SearchTextField> {
  List<Map<String, dynamic>> _suggestions = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchRandomPlaces();
  }

  Future<void> _searchPlaces(String query) async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (query.isEmpty) {
        await _fetchRandomPlaces();
      } else {
        List<Map<String, dynamic>> firestoreSuggestions =
            await _fetchFirestoreSuggestions(query);
        List<Map<String, dynamic>> googleSuggestions =
            await _fetchGoogleSuggestions(query);

        setState(() {
          _suggestions = [...firestoreSuggestions, ...googleSuggestions];
        });
      }
    } catch (e) {
      print('Error during search: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }

    widget.onSuggestionsUpdate(_suggestions);
  }

  Future<void> _fetchRandomPlaces() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final firestoreFuture = _fetchRandomFirestorePlaces();
      final googleFuture = _fetchRandomGooglePlaces();

      final results = await Future.wait([firestoreFuture, googleFuture]);

      setState(() {
        _suggestions = [...results[0], ...results[1]];
      });
    } catch (e) {
      print('Error fetching random places: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }

    widget.onSuggestionsUpdate(_suggestions);
  }

  Future<List<Map<String, dynamic>>> _fetchRandomFirestorePlaces() async {
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    try {
      final firestoreResult = await _firestore.collection('place').get();
      final randomDocs =
          (firestoreResult.docs..shuffle()).take(5).toList(); // Limit to 10
      return randomDocs
          .map((doc) => {
                'name': doc['placeName'] as String,
                'imageUrl': doc['imageUrl'] as String? ??
                    'https://example.com/default-image.jpg',
              })
          .toList();
    } catch (e) {
      print('Error fetching Firestore random places: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _fetchRandomGooglePlaces() async {
    try {
      final url =
          'https://maps.googleapis.com/maps/api/place/textsearch/json?query=restaurants&key=${widget.apiKey}'; // Example query
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = (data['results'] as List<dynamic>);
        final randomResults =
            (results..shuffle()).take(5).toList(); // Limit to 10
        return randomResults
            .map((place) => {
                  'name': place['name'] as String? ?? 'Unknown',
                  'imageUrl': place['photos'] != null &&
                          (place['photos'] as List).isNotEmpty
                      ? 'https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photoreference=${place['photos'][0]['photo_reference']}&key=${widget.apiKey}'
                      : 'https://example.com/default-image.jpg',
                })
            .toList();
      } else {
        print(
            'Failed to load Google Places random results: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error fetching Google Places random results: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _fetchFirestoreSuggestions(
      String query) async {
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    try {
      QuerySnapshot firestoreResult = await _firestore
          .collection('place')
          .where('placeName', isGreaterThanOrEqualTo: query)
          .where('placeName', isLessThanOrEqualTo: query + '\uf8ff')
          .get();

      return firestoreResult.docs
          .map((doc) => {
                'name': doc['placeName'] as String,
                'imageUrl': doc['imageUrl'] as String? ??
                    'https://example.com/default-image.jpg',
              })
          .toList();
    } catch (e) {
      print('Error fetching Firestore results: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _fetchGoogleSuggestions(
      String query) async {
    try {
      final url =
          'https://maps.googleapis.com/maps/api/place/textsearch/json?query=$query&key=${widget.apiKey}';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['results'] as List<dynamic>)
            .map((place) => {
                  'name': place['name'] as String? ?? 'Unknown',
                  'imageUrl': place['photos'] != null &&
                          (place['photos'] as List).isNotEmpty
                      ? 'https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photoreference=${place['photos'][0]['photo_reference']}&key=${widget.apiKey}'
                      : 'https://example.com/default-image.jpg',
                })
            .toList();
      } else {
        print('Failed to load Google Places results: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error fetching Google Places results: $e');
      return [];
    }
  }

  void _showSearchOverlay() {
    OverlayState? overlayState = Overlay.of(context); // Get the overlay state
    OverlayEntry? overlayEntry;

    // Create the overlay entry
    overlayEntry = OverlayEntry(
      builder: (context) => Positioned.fill(
        child: GestureDetector(
          onTap: () {
            // Dismiss the overlay if tapped outside
          },
          child: Material(
            color: Colors.black
                .withOpacity(0.5), // Semi-transparent overlay background
            child: Stack(
              children: [
                // Content of the overlay
                Positioned.fill(
                  child: Center(
                    child: Container(
                      width: MediaQuery.of(context)
                          .size
                          .width, // Full screen width
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color:
                            Color.fromARGB(255, 22, 23, 43), // Background color
                        borderRadius: BorderRadius
                            .zero, // No border radius for full screen
                      ),
                      child: Column(
                        children: [
                          SizedBox(height: 25.0),
                          Text(
                            "Add to this list",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          // Search TextField moved down
                          SizedBox(
                              height: 80.0), // Adds space before the TextField
                          TextField(
                            controller: widget.controller,
                            onChanged: (query) {
                              _searchPlaces(query);
                            },
                            style: TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.transparent,
                              hintText: 'Search',
                              hintStyle: TextStyle(color: Colors.white70),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                                borderSide: BorderSide(color: Colors.white),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                                borderSide: BorderSide(color: Colors.white),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                                borderSide: BorderSide(color: Colors.white),
                              ),
                              prefixIcon:
                                  Icon(Icons.search, color: Colors.white),
                            ),
                          ),
                          // Add space between the SearchTextField and the related searches container
                          SizedBox(
                              height:
                                  48.0), // Adjust this value for desired spacing
                          _isLoading
                              ? Center(
                                  child: CircularProgressIndicator(
                                      color: Colors.white))
                              : Container(
                                  height: 550.0,
                                  padding: const EdgeInsets.all(12.0),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.white),
                                    borderRadius: BorderRadius.circular(8.0),
                                    color: Color.fromARGB(255, 22, 23, 43),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Related Searches',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 32,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 8.0),
                                      _isLoading
                                          ? Center(
                                              child: CircularProgressIndicator(
                                                  color: Colors.white))
                                          : Expanded(
                                              child: Builder(
                                                builder: (context) {
                                                  return ListView.builder(
                                                    itemCount:
                                                        _suggestions.length,
                                                    itemBuilder:
                                                        (context, index) {
                                                      final suggestion =
                                                          _suggestions[index];
                                                      return Container(
                                                        margin: const EdgeInsets
                                                            .only(bottom: 8.0),
                                                        child: Stack(
                                                          children: [
                                                            SizedBox(
                                                              width: double
                                                                  .infinity,
                                                              height: 100.0,
                                                              child: suggestion[
                                                                          'imageUrl'] !=
                                                                      null
                                                                  ? Image
                                                                      .network(
                                                                      suggestion[
                                                                          'imageUrl'],
                                                                      fit: BoxFit
                                                                          .cover,
                                                                      errorBuilder: (context,
                                                                          error,
                                                                          stackTrace) {
                                                                        return Center(
                                                                            child:
                                                                                Text('No Image', style: TextStyle(fontSize: 16)));
                                                                      },
                                                                    )
                                                                  : Center(
                                                                      child: Text(
                                                                          'No Image',
                                                                          style:
                                                                              TextStyle(fontSize: 16))),
                                                            ),
                                                            Positioned(
                                                              left: 0.0,
                                                              bottom: 0.0,
                                                              right: 0,
                                                              child: Container(
                                                                color: Colors
                                                                    .black
                                                                    .withOpacity(
                                                                        0.5),
                                                                padding:
                                                                    const EdgeInsets
                                                                        .all(
                                                                        8.0),
                                                                child: Row(
                                                                  children: [
                                                                    Expanded(
                                                                      child:
                                                                          Text(
                                                                        suggestion['name'] ??
                                                                            'No Name',
                                                                        style:
                                                                            TextStyle(
                                                                          color:
                                                                              Colors.white,
                                                                          fontSize:
                                                                              16.0,
                                                                          fontWeight:
                                                                              FontWeight.bold,
                                                                        ),
                                                                        overflow:
                                                                            TextOverflow.ellipsis,
                                                                      ),
                                                                    ),
                                                                    IconButton(
                                                                      icon: Icon(
                                                                          Icons
                                                                              .add,
                                                                          color:
                                                                              Colors.white),
                                                                      onPressed:
                                                                          () {
                                                                        widget.onAddPlace(
                                                                            suggestion); // Use callback to add the place
                                                                        ScaffoldMessenger.of(context)
                                                                            .showSnackBar(
                                                                          SnackBar(
                                                                            content:
                                                                                Text('Place added!'),
                                                                            duration:
                                                                                Duration(seconds: 2),
                                                                          ),
                                                                        );

                                                                        // Create the overlay entry for the "Place added!" message
                                                                        OverlayState?
                                                                            overlayState =
                                                                            Overlay.of(context);
                                                                        OverlayEntry?
                                                                            overlayEntry;

                                                                        overlayEntry =
                                                                            OverlayEntry(
                                                                          builder: (context) =>
                                                                              Positioned.fill(
                                                                            child:
                                                                                GestureDetector(
                                                                              onTap: () {
                                                                                // Dismiss the overlay when tapped outside
                                                                                overlayEntry?.remove();
                                                                              },
                                                                              child: Material(
                                                                                color: Colors.black.withOpacity(0.5), // Semi-transparent overlay background
                                                                                child: Stack(
                                                                                  children: [
                                                                                    // Centered "Place added!" message
                                                                                    Positioned.fill(
                                                                                      child: Center(
                                                                                        child: Container(
                                                                                          width: MediaQuery.of(context).size.width * 0.7, // Message container width
                                                                                          padding: const EdgeInsets.all(16.0),
                                                                                          decoration: BoxDecoration(
                                                                                            color: Color.fromARGB(255, 22, 23, 43), // Background color
                                                                                            borderRadius: BorderRadius.circular(8.0), // Rounded corners
                                                                                          ),
                                                                                          child: Column(
                                                                                            mainAxisSize: MainAxisSize.min,
                                                                                            children: [
                                                                                              Text(
                                                                                                "Place added!",
                                                                                                style: TextStyle(
                                                                                                  color: Colors.white,
                                                                                                  fontSize: 20,
                                                                                                  fontWeight: FontWeight.bold,
                                                                                                ),
                                                                                              ),
                                                                                              SizedBox(height: 20),
                                                                                              TextButton(
                                                                                                onPressed: () {
                                                                                                  overlayEntry?.remove(); // Remove the overlay when OK is pressed
                                                                                                },
                                                                                                child: Text(
                                                                                                  "OK",
                                                                                                  style: TextStyle(color: Colors.white),
                                                                                                ),
                                                                                              ),
                                                                                            ],
                                                                                          ),
                                                                                        ),
                                                                                      ),
                                                                                    ),
                                                                                  ],
                                                                                ),
                                                                              ),
                                                                            ),
                                                                          ),
                                                                        );

                                                                        // Insert the overlay entry into the overlay
                                                                        overlayState
                                                                            ?.insert(overlayEntry);

                                                                        // Optionally, you can remove the overlay after a set duration
                                                                        Future.delayed(
                                                                            Duration(seconds: 2),
                                                                            () {
                                                                          overlayEntry
                                                                              ?.remove();
                                                                        });
                                                                      },
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      );
                                                    },
                                                  );
                                                },
                                              ),
                                            ),
                                    ],
                                  ),
                                ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Back button at the bottom-left of the overlay
                Positioned(
                  top:
                      20.0, // Adjust this value to control the vertical position (move it lower)
                  left: 16.0,
                  child: IconButton(
                    icon: Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () {
                      overlayEntry?.remove();
                      Navigator.pop(context);
                      // Close the overlay when tapped
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // Insert the overlay entry
    overlayState.insert(overlayEntry);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () {
              // Action to be performed on tap (e.g., show a dialog)
              _showSearchOverlay();
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: Colors.white),
              ),
              child: Row(
                children: [
                  Icon(Icons.search, color: Colors.white),
                  SizedBox(width: 8.0),
                  Text(
                    'Search',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 48.0),
          Container(
            height: 550.0,
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white),
              borderRadius: BorderRadius.circular(8.0),
              color: Color.fromARGB(255, 22, 23, 43),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Related Searches',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8.0),
                _isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                        ),
                      )
                    : Expanded(
                        child: Builder(
                          builder: (context) {
                            return ListView.builder(
                              itemCount: _suggestions.length,
                              itemBuilder: (context, index) {
                                final suggestion = _suggestions[index];
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8.0),
                                  child: Stack(
                                    children: [
                                      SizedBox(
                                        width: double.infinity,
                                        height: 100.0,
                                        child: suggestion['imageUrl'] != null
                                            ? Image.network(
                                                suggestion['imageUrl'],
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error,
                                                    stackTrace) {
                                                  return Center(
                                                      child: Text('No Image',
                                                          style: TextStyle(
                                                              fontSize: 16)));
                                                },
                                              )
                                            : Center(
                                                child: Text(
                                                  'No Image',
                                                  style:
                                                      TextStyle(fontSize: 16),
                                                ),
                                              ),
                                      ),
                                      Positioned(
                                        left: 0.0,
                                        bottom: 0.0,
                                        right: 0,
                                        child: Container(
                                          color: Colors.black.withOpacity(0.5),
                                          padding: const EdgeInsets.all(8.0),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  suggestion['name'] ??
                                                      'No Name',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 16.0,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              IconButton(
                                                icon: Icon(Icons.add,
                                                    color: Colors.white),
                                                onPressed: () {
                                                  widget.onAddPlace(
                                                      suggestion); // Use callback
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    SnackBar(
                                                      content:
                                                          Text('Place added!'),
                                                      duration:
                                                          Duration(seconds: 2),
                                                    ),
                                                  );
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Widget _buildAddToListContent(
    VoidCallback toggleAddToListContent, String listId, BuildContext context) {
  final TextEditingController _searchController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _apiKey =
      'AIzaSyANC6OfmrgsOcypf8rHrKaVCvvS89kQRMM'; // Replace with your actual API key

  final String _currentListId = listId;

  Future<GeoPoint?> _fetchPlaceLocation(String placeName) async {
    try {
      // Step 1: Fetch from Firestore
      final querySnapshot = await _firestore
          .collection('place')
          .where('placeName', isEqualTo: placeName)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final placeDoc = querySnapshot.docs.first;
        final location = placeDoc['location']
            as GeoPoint?; // Ensure 'location' is cast to GeoPoint

        return location;
      } else {
        print('No place found in Firestore with name: $placeName');
      }

      // Step 2: If not found in Firestore, fetch from Google Maps API
      const googleApiKey =
          'AIzaSyANC6OfmrgsOcypf8rHrKaVCvvS89kQRMM'; // Replace with your API key
      final url =
          'https://maps.googleapis.com/maps/api/place/findplacefromtext/json?input=$placeName&inputtype=textquery&fields=geometry&key=$googleApiKey';

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['candidates'].isNotEmpty) {
          final geometry = data['candidates'][0]['geometry'];
          final lat = geometry['location']['lat'];
          final lng = geometry['location']['lng'];

          // Convert to GeoPoint for consistency with Firestore
          return GeoPoint(lat, lng);
        } else {
          print('No place found on Google Maps with name: $placeName');
          return null;
        }
      } else {
        print(
            'Failed to fetch location from Google Maps API: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error fetching place location: $e');
      return null;
    }
  }

  Future<void> _addPlaceToCurrentList(Map<String, dynamic> place) async {
    try {
      final placeName = place['name'];
      final location = await _fetchPlaceLocation(placeName);

      if (location != null) {
        // Fetch the current number of places to determine the next order value
        final placesSnapshot = await _firestore
            .collection('list')
            .doc(_currentListId)
            .collection('places')
            .get();

        final order = placesSnapshot.size + 1; // Order based on count + 1

        final updatedPlace = {
          ...place,
          'location': location,
          'order': order, // Add the order field here
        };

        await _firestore
            .collection('list')
            .doc(_currentListId)
            .collection('places')
            .add(updatedPlace);
        print('Place added to Firestore with location and order');
      } else {
        print('Place not added. Location not found.');
      }
    } catch (e) {
      print('Error adding place: $e');
    }
  }

  return Scaffold(
    backgroundColor: Color.fromARGB(255, 22, 23, 43),
    body: StatefulBuilder(
      builder: (BuildContext context, StateSetter setState) {
        List<Map<String, dynamic>> _places = [];
        List<Map<String, dynamic>> _googlePlaces = [];

        void _handleSuggestionsUpdate(List<Map<String, dynamic>> suggestions) {
          setState(() {
            _googlePlaces = suggestions;
          });
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
          decoration: BoxDecoration(
            color: Color.fromARGB(255, 22, 23, 43), // Adjust color as needed
            borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Center(
                      child: Text(
                        'Add to this List',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 48),
                ],
              ),
              IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  color: const Color.fromARGB(255, 255, 255, 255),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              SizedBox(height: 16.0),
              SearchTextField(
                controller: _searchController,
                apiKey: _apiKey,
                onSuggestionsUpdate: _handleSuggestionsUpdate,
                currentListId: _currentListId,
                onAddPlace: _addPlaceToCurrentList,
              ),
              SizedBox(height: 16.0),
              if (_places.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white),
                    borderRadius: BorderRadius.circular(8.0),
                    color: Colors.black.withOpacity(0.5),
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: 200.0),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _places.length,
                      itemBuilder: (context, index) {
                        final place = _places[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8.0),
                          height: 100.0,
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: Image.network(
                                  place['imageUrl'] ??
                                      'https://example.com/default-image.jpg',
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                left: 10.0,
                                bottom: 10.0,
                                child: Row(
                                  mainAxisSize: MainAxisSize.max,
                                  children: [
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.all(8.0),
                                        color: Colors.black.withOpacity(0.5),
                                        child: Text(
                                          place['name'] ?? 'Unknown',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18.0,
                                          ),
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon:
                                          Icon(Icons.add, color: Colors.white),
                                      onPressed: () {
                                        _addPlaceToCurrentList(place);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              SizedBox(height: 16.0),
              if (_googlePlaces.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white),
                    borderRadius: BorderRadius.circular(8.0),
                    color: Colors.black.withOpacity(0.5),
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: 200.0),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _googlePlaces.length,
                      itemBuilder: (context, index) {
                        final place = _googlePlaces[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8.0),
                          child: Stack(
                            children: [
                              SizedBox(
                                width: double.infinity,
                                height: 100.0,
                                child: Image.network(
                                  place['imageUrl'] ??
                                      'https://example.com/default-image.jpg',
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                left: 0.0,
                                bottom: 0.0,
                                right: 0,
                                child: Container(
                                  color: Colors.black.withOpacity(0.5),
                                  padding: const EdgeInsets.all(8.0),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          place['name'] ?? 'No Name',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16.0,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.add,
                                            color: Colors.white),
                                        onPressed: () {
                                          _addPlaceToCurrentList(place);
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    ),
  );
}

Widget _buildEditListContent(Function() toggleEditListContent) {
  return Stack(
    children: [
      // Positioned close icon
      Positioned(
        top: 16, // Adjust as needed
        left: 16, // Adjust as needed
        child: IconButton(
          onPressed: toggleEditListContent,
          icon: Icon(Icons.close, color: Colors.white),
        ),
      ),
      // Positioned check icon
      Positioned(
        top: 16, // Adjust as needed
        right: 16, // Adjust as needed
        child: IconButton(
          onPressed: () {
            // Add action for the check icon here
          },
          icon: Icon(Icons.check, color: Colors.white),
        ),
      ),
      // Centered text and line
      Center(
        child: Padding(
          padding: const EdgeInsets.only(
              top: 50.0), // Adjust to position text correctly
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Edit this list',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 27,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 100), // Increase spacing between the texts
              Text(
                'List #1',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 60,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 0), // Space between text and line
              // Long white line using LayoutBuilder
              LayoutBuilder(
                builder: (context, constraints) {
                  return Container(
                    width: constraints.maxWidth *
                        0.8, // 80% of the available width
                    height: 2,
                    color: Colors.white,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    ],
  );
}

Widget _buildSettingsContent(BuildContext context, VoidCallback toggleContent) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start, // Align items to the start
    children: [
      Container(
        padding: EdgeInsets.all(16.0), // Adjust padding as needed
        child: Row(
          children: [
            IconButton(
              icon: Icon(Icons.arrow_back),
              color: Colors.white,
              onPressed: toggleContent,
            ),
            SizedBox(width: 8.0), // Spacing between icon and text
            Text(
              'Settings',
              style: TextStyle(
                fontSize: 24.0,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      // General setting with switch
      Container(
        padding: EdgeInsets.symmetric(
            vertical: 8.0), // Adjust vertical padding as needed
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(),
          ],
        ),
      ),
      // Account setting
      Container(
        padding: EdgeInsets.symmetric(
            vertical: 8.0), // Adjust vertical padding as needed
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(),
            GestureDetector(
              onTap: () {
                // Handle Account tap if needed
              },
              child: SizedBox(width: 24.0), // Provide space for tapping
            ),
          ],
        ),
      ),
      // Logs Out setting
      Container(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        child: GestureDetector(
          onTap: () async {
            await _auth.signOut();
            // Navigate back to the sign-in page
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const SignInWithEmail()),
              (route) => false, // This clears the navigation stack
            );
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.close,
                    size: 32,
                    color: Colors.red, // Icon color for Log Out
                  ),
                  SizedBox(width: 32.0), // Spacing between icon and text
                  Text(
                    'Log Out',
                    style: TextStyle(
                      fontSize: 32.0,
                      color: Colors.red, // Text color for Log Out
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SizedBox(width: 24.0), // Provide space for tapping
            ],
          ),
        ),
      )
    ],
  );
}

Widget _buildPinContent(String placeName) {
  return Container(
    color: Colors.transparent,
    padding: const EdgeInsets.all(1.0),
    margin: const EdgeInsets.symmetric(vertical: 8.0),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Icon(Icons.location_pin, color: Colors.white),
        Text(
          placeName,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
        ),
        IconButton(
          icon: Icon(Icons.more_vert, color: Colors.white),
          onPressed: () {
            // Handle three dots button press
          },
        ),
      ],
    ),
  );
}

Widget _buildByYouContent() {
  return Column(
    children: [
      Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              // Handle back button press
            },
          ),
          Text('By You'),
        ],
      ),
      _buildListItem('Your List 1'),
      _buildListItem('Your List 2'),
      // Add more items as needed
    ],
  );
}

Widget _buildByOthersContent() {
  return Column(
    children: [
      Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              // Handle back button press
            },
          ),
          Text('By Others'),
        ],
      ),
      _buildListItem('Others\' List 1'),
      _buildListItem('Others\' List 2'),
      // Add more items as needed
    ],
  );
}

//END OF CODE
String userId = FirebaseAuth.instance.currentUser!.uid;
void _openEditProfileDialog(BuildContext context) async {
  TextEditingController _usernameController = TextEditingController();

  // Fetch current username from Firestore
  DocumentSnapshot userDoc =
      await FirebaseFirestore.instance.collection('users').doc(userId).get();
  String currentUsername =
      userDoc['username']; // Assuming the username field is 'username'

  // Set current username as placeholder
  _usernameController.text = currentUsername;

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Edit Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(
                labelText: 'New Username',
                hintText: 'Enter your new username',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              String newUsername = _usernameController.text.trim();
              if (newUsername.isNotEmpty) {
                // Update the username in Firestore
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(userId)
                    .update({
                  'username': newUsername,
                });
                Navigator.pop(context);
              } else {
                // Show a warning if username is empty
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Username cannot be empty')));
              }
            },
            child: Text('Save'),
          ),
        ],
      );
    },
  );
}
