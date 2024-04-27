import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  
  @override
  Widget build(BuildContext context) {
    return PictureSlider();
  }





}


class PictureSlider extends StatefulWidget {
  @override
  _PictureSliderState createState() => _PictureSliderState();
}

class _PictureSliderState extends State<PictureSlider> {
  List<String> pictureUrls = [];
  int currentIndex = 0;
  late Timer timer;
  File? pickedFile;
  @override
  void initState() {
    super.initState();
    fetchPictures();
    timer = Timer.periodic(Duration(seconds: 2), (Timer t) => changePicture());
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  void fetchPictures() async {
    try {
      final response = await http.get(Uri.parse('https://facesearchserver.onrender.com/get-picture'));
      if (response.statusCode == 200) {
        setState(() {
           final List<dynamic> jsonData = json.decode(response.body);
           pictureUrls = jsonData.map((item) => item['image'] as String).toList();
        });
      } else {
        print('Failed to fetch pictures. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching pictures: $e');
    }
  }

  void changePicture() {
    setState(() {
      if(pictureUrls.length>0)
      currentIndex = (currentIndex + 1) % pictureUrls.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 234, 229, 229),
      appBar: AppBar(title: Text('Face Search' , style: TextStyle(color: Colors.white),) , centerTitle: true,
      backgroundColor: Color.fromARGB(255, 2, 38, 68),),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(height: 50,),
          Center(
            child: pictureUrls.isEmpty? 
             CircularProgressIndicator(): 
             Image.memory(base64Decode(pictureUrls[currentIndex]), fit: BoxFit.contain,),
          ),
          SizedBox(height: 20,),
          Container(
            width: double.infinity,

            child: ElevatedButton(onPressed: selectFile, child: Text('Add Photo' ,style: TextStyle(color: Colors.white),),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color.fromARGB(255, 2, 38, 68),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(5)))),),
          )
        ],
      ),
     
    );
  }
  Future selectFile() async{
  final result = await ImagePicker().pickImage(source: ImageSource.gallery);
  if(result == null)
  return ;
  setState(() {
    pickedFile = File(result.path);
   
  });
  uploadPicture(context , pickedFile!);
}
Future<void> uploadPicture(BuildContext context, File imageFile) async {
  // Create a multipart request
  var request = http.MultipartRequest('POST', Uri.parse('https://facesearchserver.onrender.com/upload'));

  // Add the image file to the request
  request.files.add(await http.MultipartFile.fromPath('picture', imageFile.path));

  try {
    // Send the request
    var response = await request.send();

    // Check the response status code
    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Picture uploaded successfully')));
      fetchPictures();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to upload picture. Status code: ${response.statusCode}')));
    }
  } catch (e) {
    print('Error uploading picture: $e');
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error uploading picture: $e')));
  }
}

}