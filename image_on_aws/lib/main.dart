import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_storage_s3/amplify_storage_s3.dart';
import 'package:image_picker_for_web/image_picker_for_web.dart'; // Web-compatible image picker
import 'package:image_picker_web/image_picker_web.dart';
import 'amplifyconfiguration.dart';
import 'dart:typed_data'; // For handling image byte data in web

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Uint8List? _image; // Byte data for the image
  bool _isAmplifyConfigured = false;
  bool _isSignedIn = false;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _verificationCodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _configureAmplify();
  }

  Future<void> _configureAmplify() async {
    try {
      await Amplify.addPlugins([
        AmplifyAuthCognito(),
        AmplifyStorageS3(),
      ]);
      await Amplify.configure(amplifyconfig);
      setState(() {
        _isAmplifyConfigured = true;
      });
      // await _checkAuthStatus();
      print('Amplify configured successfully');
      setState(() {
        
      });
    } catch (e) {
      print('Error configuring Amplify: $e');
    }
  }

  Future<void> _checkAuthStatus() async {
    try {
      final result = await Amplify.Auth.fetchAuthSession();
      setState(() {
        _isSignedIn = result.isSignedIn;
      });
    } catch (e) {
      print('Error checking auth status: $e');
    }
  }

  Future<void> _signUp() async {
    try {
      final userAttributes = <CognitoUserAttributeKey, String>{
        CognitoUserAttributeKey.email: _emailController.text.trim(),
      };
      final result = await Amplify.Auth.signUp(
        username:"divyanshpatidar85@gmail.com",
        password:"putyourpassword",
      );
      if (result.isSignUpComplete) {
        _showVerificationDialog();
      }
    } catch (e) {
      print('Error signing up: $e');
    }
  }

  Future<void> _confirmSignUp() async {
    try {
      final result = await Amplify.Auth.confirmSignUp(
        username: _emailController.text.trim(),
        confirmationCode: _verificationCodeController.text.trim(),
      );
      if (result.isSignUpComplete) {
        await _signIn();
      }
    } catch (e) {
      print('Error confirming sign up: $e');
    }
  }

  Future<void> _signIn() async {
    try {
      final result = await Amplify.Auth.signIn(
        username: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      setState(() {
        _isSignedIn = result.isSignedIn;
      });
    } catch (e) {
      print('Error signing in: $e');
    }
  }

  Future<void> _signOut() async {
    try {
      await Amplify.Auth.signOut();
      setState(() {
        _isSignedIn = false;
      });
    } catch (e) {
      print('Error signing out: $e');
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePickerWeb.getImageAsBytes();
    setState(() {
      if (pickedFile != null) {
        _image = pickedFile; // Store the byte data for the image
      }
    });
  }

  Future<void> _uploadImage() async {
    if (_image == null) return;

    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path = StoragePath.fromString(fileName);

      // Upload file using byte data
      final result = await Amplify.Storage.uploadFile(
        localFile: AWSFile.fromData(
          _image!,
          // key: path.key,
          contentType: 'image/jpeg', // Adjust the content type as needed
        ),
        path: path,
        onProgress: (progress) {
          print('Fraction completed: ${progress.fractionCompleted}');
        },
      ).result;
      print('Successfully uploaded image: ${result}');
    } catch (e) {
      print('Error uploading image: $e');
    }
  }

  void _showVerificationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Verify your email'),
          content: TextField(
            controller: _verificationCodeController,
            decoration: InputDecoration(labelText: 'Verification Code'),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Verify'),
              onPressed: () {
                Navigator.of(context).pop();
                _confirmSignUp();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('S3 Image Upload with Cognito')),
      body: Center(
        child: true ? _buildUploadUI() : _buildAuthUI(),
      ),
    );
  }

  Widget _buildAuthUI() {
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextField(
            controller: _emailController,
            decoration: InputDecoration(labelText: 'Email'),
            keyboardType: TextInputType.emailAddress,
          ),
          TextField(
            controller: _passwordController,
            decoration: InputDecoration(labelText: 'Password'),
            obscureText: true,
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: _isAmplifyConfigured ? _signIn : null,
            child: Text('Sign In'),
          ),
          ElevatedButton(
            onPressed: _isAmplifyConfigured ? _signUp : null,
            child: Text('Sign Up'),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadUI() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        if (_image != null) Image.memory(_image!, height: 200), // Display the image as byte data
        ElevatedButton(
          onPressed: _pickImage,
          child: Text('Pick Image'),
        ),
        ElevatedButton(
          onPressed: _image != null ? _uploadImage : null,
          child: Text('Upload Image'),
        ),
        ElevatedButton(
          onPressed: _signOut,
          child: Text('Sign Out'),
        ),
      ],
    );
  }
}
