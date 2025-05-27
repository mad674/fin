// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';

// class ProfileScreen extends StatelessWidget {
//   final User? user = FirebaseAuth.instance.currentUser;

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text("Profile"),
//       ),
//       body: user == null
//           ? Center(child: Text("No user data available."))
//           : Padding(
//               padding: EdgeInsets.all(16),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Center(
//                     child: CircleAvatar(
//                       radius: 50,
//                       backgroundColor: Colors.green,
//                       child: Icon(Icons.account_circle, size: 80, color: Colors.white),
//                     ),
//                   ),
//                   SizedBox(height: 16),
//                   Text("Email: ${user!.email}", style: TextStyle(fontSize: 18)),
//                   SizedBox(height: 8),
//                   // Assuming you store phone and registration details in Firestore.
//                   // For now, these are placeholders.
//                   Text("Phone: ${user!.phoneNumber}", style: TextStyle(fontSize: 18)),
//                   SizedBox(height: 8),
//                   Text("Registered on: ${user!.metadata.creationTime}", style: TextStyle(fontSize: 18)),
//                   SizedBox(height: 24),
//                   // Additional details or settings can be added here.
//                   Text("Profile Settings", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
//                   SizedBox(height: 8),
//                   ListTile(
//                     leading: Icon(Icons.edit),
//                     title: Text("Edit Profile"),
//                     onTap: () {
//                       // TODO: Implement profile editing functionality.
//                       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Edit Profile tapped")));
//                     },
//                   ),
//                   ListTile(
//                     leading: Icon(Icons.security),
//                     title: Text("Security Settings"),
//                     onTap: () {
//                       // TODO: Implement security settings.
//                       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Security Settings tapped")));
//                     },
//                   ),
//                 ],
//               ),
//             ),
//     );
//   }
// }
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  TextEditingController _nameController = TextEditingController();
  TextEditingController _phoneController = TextEditingController();
  File? _image;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  void _fetchUserData() async {
    if (user != null) {
      DocumentSnapshot userData = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
      setState(() {
        _nameController.text = userData['name'] ?? '';
        _phoneController.text = userData['phone'] ?? '';
      });
    }
  }

  Future<void> _updateProfile() async {
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user!.uid).set({
        'name': _nameController.text,
        'phone': _phoneController.text,
      }, SetOptions(merge: true));

      setState(() {
        _isEditing = false;
      });
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Profile"),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.of(context).pop();
            },
          )
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.camera_alt, color: Colors.green),
                  backgroundImage: _image != null ? FileImage(_image!) : null,
                  // child: _image == null ? Icon(Icons.account_circle, size: 80, color: Colors.white) : null,
                  
                ),
              ),
            ),
            SizedBox(height: 16),
            _isEditing
                ? TextField(
                    controller: _nameController,
                    decoration: InputDecoration(labelText: "Name"),
                  )
                : Text("Name: ${_nameController.text}", style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text("Phone: ${user?.phoneNumber}", style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text("Email: ${user?.email}", style: TextStyle(fontSize: 18)),
            SizedBox(height: 24),
            _isEditing
                ? ElevatedButton(
                    onPressed: _updateProfile,
                    child: Text("Save"),
                  )
                : ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _isEditing = true;
                      });
                    },
                    child: Text("Edit Profile"),
                  ),
            ListTile(
                    leading: Icon(Icons.security),
                    title: Text("Security Settings"),
                    onTap: () {
                      // TODO: Implement security settings.
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Security Settings tapped")));
                    },
                  ),
            ListTile(
                    leading: Icon(Icons.logout, color: Colors.red),
                    title: Text("Logout", style: TextStyle(color: Colors.red)),
                    onTap: () async {
                      await FirebaseAuth.instance.signOut();
                      Navigator.pushReplacementNamed(context, "/login"); // Adjust based on your routes
                    },
                  ),

          ],

        ),
      ),
    );
  }
}
