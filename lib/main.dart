import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:image/image.dart' as img;

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: new ThemeData.dark(),
      home: new MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => new _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String str;
  String strrr;

  File myFile;
  final scaffoldKey = new GlobalKey<ScaffoldState>();
  static const baseUrl = 'http://192.168.29.152:8000/postimage';

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      key: scaffoldKey,
      appBar: new AppBar(
        title: new Text('Upload image'),
      ),
      body: new Column(
        children: <Widget>[
          _buildPreviewImage(),
          _buildButtons(),
        ],
      ),
    );
  }

  Widget _buildPreviewImage() {
    return new Expanded(
      child: new Card(
        elevation: 3.0,
        shape: new RoundedRectangleBorder(
          borderRadius: new BorderRadius.all(
            new Radius.circular(4.0),
          ),
        ),
        child: new Stack(
          children: <Widget>[
            new Container(
              constraints: new BoxConstraints.expand(),
              child: myFile == null
                  ? new Image.asset('assets/bg.png', colorBlendMode: BlendMode.darken, color: Colors.black26, fit: BoxFit.cover)
                  : new Image.file(myFile, fit: BoxFit.cover),
            ),
            new Align(
              alignment: AlignmentDirectional.center,
              child: myFile == null
                  ? new Text(
                'No selected image',
                style: Theme.of(context).textTheme.title,
              )
                  : new Container(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButtons() {
    return new Padding(
      padding: const EdgeInsets.all(8.0),
      child: new Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          new IconButton(
            icon: Icon(Icons.camera),
            onPressed: _takePhoto,
            tooltip: 'Take photo',
          ),
          new IconButton(
            icon: Icon(Icons.file_upload),
            onPressed: _uploadImage,
            tooltip: 'Upload image',
          ),
          new IconButton(
            icon: Icon(Icons.image),
            onPressed: _selectGalleryImage,
            tooltip: 'Select from gallery',
          ),
        ],
      ),
    );
  }

  _takePhoto() async {
    myFile = await ImagePicker.pickImage(source: ImageSource.camera);
     str = myFile.toString();
     strrr = str.replaceAll('jpg','png');

    print('strr $strrr');

    setState(() {});
  }

  _showSnackbar(String text) => scaffoldKey.currentState?.showSnackBar(
    new SnackBar(
      content: new Text(text),
    ),
  );

  _uploadImage() async {
    if (myFile == null) {
      return _showSnackbar('Please select image');
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return new Center(
          child: new CircularProgressIndicator(),
        );
      },
      barrierDismissible: false,
    );

    try {
      final url = Uri.parse('http://192.168.29.152:8000/postimage');
      final fileName = path.basename(myFile!=strrr?strrr:str);
      print('filename  $fileName');
      final bytes = await compute(compress, myFile.readAsBytesSync());

      var request = http.MultipartRequest('POST', url)
        ..files.add(
          new http.MultipartFile.fromBytes(
            'image',
            bytes,
            filename: fileName,
          ),
        );

      var response = await request.send();
      var decoded = await response.stream.bytesToString().then(json.decode);
      print('response123 $decoded');

      Navigator.pop(context);
      if (response.statusCode == HttpStatus.OK) {
        _showSnackbar('Image uploaded, imageUrl = $baseUrl/${decoded['path']}');
      } else {
        _showSnackbar('Image failed: ${decoded['message']}');
      }
    } catch (e) {
      Navigator.pop(context);
      _showSnackbar('Image failed: $e');
    }
  }

  _selectGalleryImage() async {
    myFile = await ImagePicker.pickImage(source: ImageSource.gallery);
    str = myFile.toString();
    setState(() {});
  }
}



List<int> compress(List<int> bytes) {
  var image = img.decodeImage(bytes);
  var resize = img.copyResize(image, width: 480);
  return img.encodePng(resize, level: 1);
}