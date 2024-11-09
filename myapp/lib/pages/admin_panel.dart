import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

Future<void> displayAdminPanel(BuildContext context) async {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true, // Allows full-screen height
    builder: (BuildContext context) {
      return FractionallySizedBox(
        heightFactor: 0.9, // 90% of the screen height
        child: AdminPanel(),
      );
    },
  );
}

class AdminPanel extends StatefulWidget {
  @override
  _AdminPanelState createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  bool isListContentClicked = false; // Track if list content is clicked
  String clickedListContent = ''; // Track which list content is clicked
  String? selectedListId; // Move this here to be accessible across methods
  String selectedSection = '';
  String selectedUser = '';

  Future<List<String>> fetchUsernames() async {
    QuerySnapshot<Map<String, dynamic>> snapshot =
        await FirebaseFirestore.instance.collection('users').get();

    List<String> usernames = snapshot.docs.map((doc) {
      // Check if 'username' exists and is not null, else use a default value
      return (doc.data()['username'] ?? 'Unknown User') as String;
    }).toList();

    return usernames;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      height: 3000,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color.fromARGB(225, 41, 42, 60), // Single solid background color
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.0),
          topRight: Radius.circular(20.0),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isListContentClicked) ...[
            // New Content Container with List name
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
                              clickedListContent.length > 20
                                  ? '${clickedListContent.substring(0, 20)}...' // Limit to 25 characters with ellipsis
                                  : clickedListContent,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Icon(Icons.send, color: Colors.white),
                      ],
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
                                IconButton(
                                  icon: Icon(Icons.more_vert,
                                      color: Colors.white),
                                  onPressed: () {},
                                ),
                                SizedBox(width: 4.0),
                                // Add the delete button here
                                IconButton(
                                  icon: Icon(Icons.delete, color: Colors.white),
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
                                                await FirebaseFirestore.instance
                                                    .collection('list')
                                                    .doc(selectedListId)
                                                    .delete();

                                                Navigator.of(context)
                                                    .pop(); // Close dialog
                                              },
                                              child: Text('Yes'),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                ),
                              ],
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
                                "No Places Added in this List",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 40.0),
                              TextButton(
                                onPressed: () {},
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
                                return Container(
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
                                              doc['name'] ?? 'Place Name',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 18.0,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            SizedBox(height: 8.0),
                                            Text(
                                              'Address',
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
                                );
                              }).toList(),
                            ),
                          );
                        }
                      },
                    ),
                    SizedBox(height: 60.0),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Back Button
            TextButton(
              onPressed: () {
                setState(() {
                  isListContentClicked = false;
                  selectedListId = null; // Reset selected list
                });
              },
              child: const Text(
                'Go Back',
                style: TextStyle(
                  fontSize: 24,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ] else if (selectedSection.isEmpty) ...[
            TextButton(
              onPressed: () {
                setState(() {
                  selectedSection = 'Content Management';
                });
              },
              child: const Text(
                'Content Management',
                style: TextStyle(
                    fontSize: 24,
                    color: Colors.white,
                    fontWeight: FontWeight.bold), // Bigger text
              ),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () {
                setState(() {
                  selectedSection = 'Account Management';
                });
              },
              child: const Text(
                'Account Management',
                style: TextStyle(
                    fontSize: 24,
                    color: Colors.white,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ] else if (selectedSection == 'Content Management') ...[
            const Text(
              'Content Management',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () {
                setState(() {
                  selectedSection = 'Posts';
                });
              },
              child: const Text(
                'Posts',
                style: TextStyle(
                    fontSize: 24,
                    color: Colors.white,
                    fontWeight: FontWeight.bold), // Bigger text
              ),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () {
                setState(() {
                  selectedSection =
                      'Deleted Posts'; // Navigate to Deleted Posts
                });
              },
              child: const Text(
                'Deleted Posts',
                style: TextStyle(
                    fontSize: 24,
                    color: Colors.white,
                    fontWeight: FontWeight.bold), // Bigger text
              ),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () {
                setState(() {
                  selectedSection = 'Itineraries';
                });
              },
              child: const Text(
                'Itineraries',
                style: TextStyle(
                    fontSize: 24,
                    color: Colors.white,
                    fontWeight: FontWeight.bold), // Bigger text
              ),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () {
                setState(() {
                  selectedSection = ''; // Go Back
                });
              },
              child: const Text(
                'Go Back',
                style: TextStyle(
                    fontSize: 24,
                    color: Colors.white,
                    fontWeight: FontWeight.bold), // Bigger text
              ),
            ),
          ] else if (selectedSection == 'Posts') ...[
            const Text(
              'Posts',
              style: TextStyle(
                  fontSize: 24,
                  color: Colors.white,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _buildAlternateContent(context, () {
                setState(() {
                  selectedSection =
                      'Content Management'; // Return to content management
                });
              }),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () {
                setState(() {
                  selectedSection = 'Content Management';
                });
              },
              child: const Text(
                'Go Back',
                style: TextStyle(
                    fontSize: 24,
                    color: Colors.white,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ] else if (selectedSection == 'Deleted Posts') ...[
            const Text(
              'Deleted Posts',
              style: TextStyle(
                fontSize: 24,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _buildDeletedPostsContent(context, () {
                setState(() {
                  selectedSection =
                      'Content Management'; // Return to content management
                });
              }),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () {
                setState(() {
                  selectedSection =
                      'Content Management'; // Go back to content management
                });
              },
              child: const Text(
                'Go Back',
                style: TextStyle(
                  fontSize: 24,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ] else if (selectedSection == 'Itineraries') ...[
            Expanded(
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Text(
                      'Itineraries',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    height: 500, // Set a fixed height to show 6 items
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('list')
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        }
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return Center(child: Text('No lists found'));
                        }

                        final documents = snapshot.data!.docs;

                        return ListView(
                          children: documents.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            final String listId = doc.id;

                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  isListContentClicked = true;
                                  clickedListContent =
                                      data['name'] ?? 'Unknown';
                                  selectedListId =
                                      listId; // Store the selected list ID
                                });
                              },
                              child: Container(
                                color: Colors.transparent,
                                padding: const EdgeInsets.all(16.0),
                                margin:
                                    const EdgeInsets.symmetric(vertical: 8.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      data['name'] != null &&
                                              data['name'].length > 30
                                          ? '${data['name'].substring(0, 30)}...' // Limit to 30 characters and add ellipsis
                                          : data['name'] ?? 'Unnamed List',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                      ),
                                      maxLines:
                                          1, // Ensure the text stays on one line
                                      overflow: TextOverflow
                                          .ellipsis, // Add ellipsis if text exceeds available space
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 1),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        selectedSection = 'Content Management';
                      });
                    },
                    child: const Text(
                      'Go Back',
                      style: TextStyle(
                        fontSize: 24,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else if (selectedSection == 'Account Management') ...[
            const Text(
              'Account Management',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () {
                setState(() {
                  selectedSection = 'Users List';
                });
              },
              child: const Text(
                'Users List',
                style: TextStyle(
                    fontSize: 24,
                    color: Colors.white,
                    fontWeight: FontWeight.bold), // Bigger text
              ),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () {
                setState(() {
                  selectedSection = 'Deactivated Users';
                });
              },
              child: const Text(
                'Deactivated Users',
                style: TextStyle(
                    fontSize: 24,
                    color: Colors.white,
                    fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () {
                setState(() {
                  selectedSection = '';
                });
              },
              child: const Text(
                'Go Back',
                style: TextStyle(
                    fontSize: 24,
                    color: Colors.white,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ] else if (selectedSection == 'Deactivated Users') ...[
            const Text(
              'Deactivated Users',
              style: TextStyle(
                  fontSize: 24,
                  color: Colors.white,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const SizedBox(height: 20),
            Container(
              height: 300, // Height of the scrollable area
              child: StreamBuilder(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .where('isDeactivated', isEqualTo: true)
                    .snapshots(),
                builder: (BuildContext context,
                    AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                    // Use a set to store unique usernames
                    Set<String> uniqueUsernames = {};

                    for (var doc in snapshot.data!.docs) {
                      var post = doc.data() as Map<String, dynamic>;
                      if (post.containsKey('username')) {
                        uniqueUsernames.add(post['username']);
                      }
                    }

                    // Convert the set to a list and display it
                    return ListView(
                      children: uniqueUsernames.map((username) {
                        return ListTile(
                          title: Text(
                            username,
                            style: const TextStyle(color: Colors.white),
                          ),
                        );
                      }).toList(),
                    );
                  }

                  return const Center(
                      child: Text('No users found.',
                          style: TextStyle(color: Colors.white)));
                },
              ),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () {
                setState(() {
                  selectedSection = 'Account Management';
                });
              },
              child: const Text(
                'Go Back',
                style: TextStyle(
                    fontSize: 24,
                    color: Colors.white,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ] else if (selectedSection == 'Users List') ...[
            const Text(
              'Users List',
              style: TextStyle(
                  fontSize: 24,
                  color: Colors.white,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Container(
              height: 300, // Height of the scrollable area
              child: StreamBuilder(
                stream:
                    FirebaseFirestore.instance.collection('users').snapshots(),
                builder: (BuildContext context,
                    AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                    Set<String> uniqueUsernames = {};

                    for (var doc in snapshot.data!.docs) {
                      var post = doc.data() as Map<String, dynamic>;
                      if (post.containsKey('username')) {
                        uniqueUsernames.add(post['username']);
                      }
                    }

                    return ListView(
                      children: snapshot.data!.docs.map((doc) {
                        var post = doc.data() as Map<String, dynamic>;
                        String username = post['username'];
                        bool isDeactivated = post['isDeactivated'] ?? false;

                        return ListTile(
                          title: Text(
                            username,
                            style: TextStyle(
                              color: isDeactivated ? Colors.red : Colors.white,
                            ),
                          ),
                          onTap: () {
                            setState(() {
                              selectedSection = 'User Details';
                              selectedUser = username; // Save selected username
                            });
                          },
                        );
                      }).toList(),
                    );
                  }

                  return const Center(
                      child: Text('No users found.',
                          style: TextStyle(color: Colors.white)));
                },
              ),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () {
                setState(() {
                  selectedSection = 'Account Management';
                });
              },
              child: const Text(
                'Go Back',
                style: TextStyle(
                    fontSize: 24,
                    color: Colors.white,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ] else if (selectedSection == 'User Details') ...[
            const Text(
              'User Details',
              style: TextStyle(
                  fontSize: 24,
                  color: Colors.white,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Text(
              'Selected User: $selectedUser',
              style: const TextStyle(fontSize: 20, color: Colors.white),
            ),
            const SizedBox(height: 20),

// Fetch user data and show the appropriate button
            FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .where('username', isEqualTo: selectedUser)
                  .get()
                  .then((QuerySnapshot snapshot) => snapshot.docs.first),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                } else if (!snapshot.hasData || snapshot.data == null) {
                  return const Text(
                    'User not found',
                    style: TextStyle(fontSize: 20, color: Colors.white),
                  );
                } else {
                  var userData = snapshot.data!.data() as Map<String, dynamic>;

                  if (userData['isDeactivated'] == true) {
                    // Show Activate User button
                    return TextButton(
                      onPressed: () {
                        var docId = snapshot.data!.id;
                        FirebaseFirestore.instance
                            .collection('users')
                            .doc(docId)
                            .update({
                          'isDeactivated':
                              false, // Set isDeactivated to false (activated)
                          'deactivateMessage':
                              null, // Clear the deactivateMessage field
                        }).then((_) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('User activated successfully')),
                          );
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text('Success'),
                                content: const Text('User Activated'),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context)
                                          .pop(); // Close the dialog
                                      setState(() {
                                        selectedSection =
                                            'Users List'; // Go back after OK is pressed
                                      });
                                    },
                                    child: const Text('OK'),
                                  ),
                                ],
                              );
                            },
                          );
                        }).catchError((error) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('Error activating user: $error')),
                          );
                        });
                      },
                      child: const Text(
                        'Activate User',
                        style: TextStyle(
                          fontSize: 24,
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  } else {
                    // Show Deactivate User button
                    String deactivateMessage =
                        ''; // Holds the reason for deactivation

                    return TextButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text('Confirm Deactivation'),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                      'Please provide a reason for deactivating the user:'),
                                  TextField(
                                    onChanged: (value) {
                                      deactivateMessage =
                                          value; // Capture the input value
                                    },
                                    decoration: const InputDecoration(
                                      hintText: 'Reason for deactivation',
                                    ),
                                  ),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    if (deactivateMessage.isNotEmpty) {
                                      // Proceed with deactivation if the message is provided
                                      var docId = snapshot.data!.id;
                                      FirebaseFirestore.instance
                                          .collection('users')
                                          .doc(docId)
                                          .update({
                                        'isDeactivated': true,
                                        'deactivateMessage':
                                            deactivateMessage, // Save the message
                                      }).then((_) {
                                        Navigator.of(context)
                                            .pop(); // Close the dialog
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                              content: Text(
                                                  'User deactivated successfully')),
                                        );
                                        showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return AlertDialog(
                                              title: const Text('Success'),
                                              content: const Text(
                                                  'User Deactivated'),
                                              actions: [
                                                TextButton(
                                                  onPressed: () {
                                                    Navigator.of(context)
                                                        .pop(); // Close the success dialog
                                                    setState(() {
                                                      selectedSection =
                                                          'Users List'; // Go back after OK is pressed
                                                    });
                                                  },
                                                  child: const Text('OK'),
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                      }).catchError((error) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                              content: Text(
                                                  'Error deactivating user: $error')),
                                        );
                                      });
                                    } else {
                                      // Show error if no message is provided
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                'Please provide a reason for deactivation')),
                                      );
                                    }
                                  },
                                  child: const Text('Confirm'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context)
                                        .pop(); // Close the dialog without any action
                                  },
                                  child: const Text('Cancel'),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      child: const Text(
                        'Deactivate User',
                        style: TextStyle(
                          fontSize: 24,
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }
                }
              },
            ),

            const SizedBox(height: 20),

            TextButton(
              onPressed: () {
                setState(() {
                  selectedSection = 'Users List';
                });
              },
              child: const Text(
                'Go Back',
                style: TextStyle(
                    fontSize: 24,
                    color: Colors.white,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildAlternateContent(
      BuildContext context, VoidCallback toggleContent) {
    return Stack(
      children: [
        StreamBuilder(
          stream: FirebaseFirestore.instance
              .collection('post')
              .where('isDeleted',
                  isEqualTo: false) // Only get posts that are not deleted
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
              return Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (BuildContext context, int index) {
                        var post = snapshot.data!.docs[index].data()
                            as Map<String, dynamic>;
                        var postId = snapshot.data!.docs[index].id;
                        var username = post['username'] ?? 'Unknown';
                        var imageUrl = post['imageUrl'];
                        var caption = post['caption'] ?? 'No Caption';
                        int likes = post['likes'] ?? 0;
                        List<dynamic> likedBy = post['likedBy'] ?? [];
                        List<dynamic> comments = post['comments'] ?? [];

                        bool isExpanded = false;

                        return StatefulBuilder(
                          builder:
                              (BuildContext context, StateSetter setState) {
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
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            backgroundColor: Colors.white,
                                            radius: 16,
                                            child: Icon(Icons.person,
                                                color: Colors.grey),
                                          ),
                                          SizedBox(width: 8),
                                          Text(username,
                                              style: TextStyle(
                                                  color: Colors.white)),
                                        ],
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.delete,
                                            color: Colors.red),
                                        onPressed: () {
                                          showDialog(
                                            context: context,
                                            builder: (BuildContext context) {
                                              return AlertDialog(
                                                title: Text('Delete Post'),
                                                content: Text(
                                                    'Are you sure you want to delete this post?'),
                                                actions: [
                                                  TextButton(
                                                    child: Text('No'),
                                                    onPressed: () {
                                                      Navigator.of(context)
                                                          .pop();
                                                    },
                                                  ),
                                                  TextButton(
                                                    child: Text('Yes'),
                                                    onPressed: () async {
                                                      await FirebaseFirestore
                                                          .instance
                                                          .collection('post')
                                                          .doc(postId)
                                                          .update({
                                                        'isDeleted': true
                                                      });
                                                      Navigator.of(context)
                                                          .pop();
                                                    },
                                                  ),
                                                ],
                                              );
                                            },
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 8),
                                  isExpanded
                                      ? Column(
                                          children: [
                                            Text(caption,
                                                style: TextStyle(
                                                    color: Colors.white)),
                                            InkWell(
                                              onTap: () {
                                                setState(() {
                                                  isExpanded = false;
                                                });
                                              },
                                              child: Text('Show less',
                                                  style: TextStyle(
                                                      color: Colors.blue)),
                                            ),
                                          ],
                                        )
                                      : Column(
                                          children: [
                                            Text(
                                              caption.length > 100
                                                  ? '${caption.substring(0, 100)}...'
                                                  : caption,
                                              style: TextStyle(
                                                  color: Colors.white),
                                            ),
                                            if (caption.length > 100)
                                              InkWell(
                                                onTap: () {
                                                  setState(() {
                                                    isExpanded = true;
                                                  });
                                                },
                                                child: Text('Show more',
                                                    style: TextStyle(
                                                        color: Colors.blue)),
                                              ),
                                          ],
                                        ),
                                  SizedBox(height: 8),
                                  imageUrl != null
                                      ? Container(
                                          height: 200,
                                          color: Colors.grey,
                                          child: Image.network(
                                            imageUrl,
                                            fit: BoxFit.cover,
                                            width: double.infinity,
                                          ),
                                        )
                                      : Container(
                                          height: 200,
                                          color: Colors.grey,
                                          child: Center(
                                            child: Text('No Image',
                                                style: TextStyle(
                                                    color: Colors.white)),
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
                                                'likes':
                                                    FieldValue.increment(1),
                                                'likedBy':
                                                    FieldValue.arrayUnion(
                                                        [user.uid])
                                              });
                                            } else {
                                              await FirebaseFirestore.instance
                                                  .collection('post')
                                                  .doc(postId)
                                                  .update({
                                                'likes':
                                                    FieldValue.increment(-1),
                                                'likedBy':
                                                    FieldValue.arrayRemove(
                                                        [user.uid])
                                              });
                                            }
                                          }
                                        },
                                        child: Row(
                                          children: [
                                            Icon(Icons.thumb_up,
                                                color: likedBy.contains(
                                                        FirebaseAuth.instance
                                                            .currentUser?.uid)
                                                    ? Colors.blue
                                                    : Colors.white),
                                            SizedBox(width: 4),
                                            Text(
                                                '$likes Like${likes == 1 ? '' : 's'}',
                                                style: TextStyle(
                                                    color: Colors.white)),
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
                                                style: TextStyle(
                                                    color: Colors.white)),
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
                  ),
                ],
              );
            }

            return Center(child: Text('No posts found.'));
          },
        ),
      ],
    );
  }
}

void _showCommentDialog(BuildContext context, String postId) {
  final TextEditingController commentController = TextEditingController();

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Add a Comment'),
        content: TextField(
          controller: commentController,
          decoration: InputDecoration(hintText: "Enter your comment"),
        ),
        actions: <Widget>[
          TextButton(
            child: Text('Cancel'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: Text('Post'),
            onPressed: () async {
              User? user = FirebaseAuth.instance.currentUser;
              if (user != null && commentController.text.isNotEmpty) {
                await FirebaseFirestore.instance
                    .collection('post')
                    .doc(postId)
                    .update({
                  'comments': FieldValue.arrayUnion([
                    {'text': commentController.text, 'userId': user.uid}
                  ])
                });
              }
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
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

Widget _buildDeletedPostsContent(
    BuildContext context, VoidCallback toggleContent) {
  return Stack(
    children: [
      StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('post')
            .where('isDeleted',
                isEqualTo: true) // Only get posts that are deleted
            .snapshots(),
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
                      var post = snapshot.data!.docs[index].data()
                          as Map<String, dynamic>;
                      var postId = snapshot.data!.docs[index].id;
                      var username = post['username'] ?? 'Unknown';
                      var imageUrl = post['imageUrl'];
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
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          backgroundColor: Colors.white,
                                          radius: 16,
                                          child: Icon(Icons.person,
                                              color: Colors.grey),
                                        ),
                                        SizedBox(width: 8),
                                        Text(username,
                                            style:
                                                TextStyle(color: Colors.white)),
                                      ],
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.restore,
                                          color: Colors.green), // Restore icon
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return AlertDialog(
                                              title: Text('Restore Post'),
                                              content: Text(
                                                  'Are you sure you want to restore this post?'),
                                              actions: [
                                                TextButton(
                                                  child: Text('No'),
                                                  onPressed: () {
                                                    Navigator.of(context).pop();
                                                  },
                                                ),
                                                TextButton(
                                                  child: Text('Yes'),
                                                  onPressed: () async {
                                                    await FirebaseFirestore
                                                        .instance
                                                        .collection('post')
                                                        .doc(postId)
                                                        .update({
                                                      'isDeleted': false
                                                    });
                                                    Navigator.of(context).pop();
                                                  },
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                      },
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8),
                                isExpanded
                                    ? Column(
                                        children: [
                                          Text(caption,
                                              style: TextStyle(
                                                  color: Colors.white)),
                                          InkWell(
                                            onTap: () {
                                              setState(() {
                                                isExpanded = false;
                                              });
                                            },
                                            child: Text('Show less',
                                                style: TextStyle(
                                                    color: Colors.blue)),
                                          ),
                                        ],
                                      )
                                    : Column(
                                        children: [
                                          Text(
                                            caption.length > 100
                                                ? '${caption.substring(0, 100)}...'
                                                : caption,
                                            style:
                                                TextStyle(color: Colors.white),
                                          ),
                                          if (caption.length > 100)
                                            InkWell(
                                              onTap: () {
                                                setState(() {
                                                  isExpanded = true;
                                                });
                                              },
                                              child: Text('Show more',
                                                  style: TextStyle(
                                                      color: Colors.blue)),
                                            ),
                                        ],
                                      ),
                                SizedBox(height: 8),
                                imageUrl != null
                                    ? Container(
                                        height: 200,
                                        color: Colors.grey,
                                        child: Image.network(
                                          imageUrl,
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                        ),
                                      )
                                    : Container(
                                        height: 200,
                                        color: Colors.grey,
                                        child: Center(
                                          child: Text('No Image',
                                              style: TextStyle(
                                                  color: Colors.white)),
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
                                          Icon(Icons.thumb_up,
                                              color: likedBy.contains(
                                                      FirebaseAuth.instance
                                                          .currentUser?.uid)
                                                  ? Colors.blue
                                                  : Colors.white),
                                          SizedBox(width: 4),
                                          Text(
                                              '$likes Like${likes == 1 ? '' : 's'}',
                                              style: TextStyle(
                                                  color: Colors.white)),
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
                                              style: TextStyle(
                                                  color: Colors.white)),
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
                ),
              ],
            );
          }

          return Center(child: Text('No deleted posts found.'));
        },
      ),
    ],
  );
}
