import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:http/http.dart' as http; 
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:video_player/video_player.dart';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'appColors.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Spark and Fable',
      theme: ThemeData(
        // --- CORE COLORS ---
        primaryColor: AppColors.fableTeal,
        // Used for things like active switch states, primary buttons, etc.
        colorScheme: ColorScheme.light(
          primary: AppColors.fableTeal,         // Main interactive color (e.g., AppBar background)
          secondary: AppColors.sparkYellow,     // Floating action buttons, highlighting
          surface: AppColors.storybookCream,                // Card, Dialog, and Sheet surfaces
          onPrimary: Colors.white,              // Text/icon color on primary
          onSecondary: AppColors.deepNavyText,  // Text/icon color on secondary
        ),
        scaffoldBackgroundColor: AppColors.storybookCream,

        // --- TYPOGRAPHY (Poppins/Nunito is recommended) ---
        fontFamily: 'Nunito', // Define this in pubspec.yaml
        textTheme: TextTheme(
          bodyLarge: TextStyle(color: AppColors.deepNavyText),
          bodyMedium: TextStyle(color: AppColors.deepNavyText),
          titleLarge: TextStyle(color: AppColors.deepNavyText, fontWeight: FontWeight.bold),
          // Ensure all text elements use the deep navy color
        ),

        // --- WIDGET STYLES (Focus on Rounded & Friendly) ---
        
        // Rounded Buttons
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.sparkYellow, // Button background
            foregroundColor: AppColors.deepNavyText, // Text/Icon color
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.0), // Rounded corners
            ),
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        
        // App Bar Styling
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.fableTeal,
          foregroundColor: Colors.white, // Text/Icons are white
          centerTitle: true,
          elevation: 0, // Flat design for a friendly look
        ),
      ),

      home: LoginPage(),
    );
  }
}


class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();
  bool _isLoading = false;
  String message = 'click the login button!';
  String email = '';
  String password = '';

  @override
  Widget build(BuildContext context){

    Future<void> login(email, password) async {
      //send request to api
      final url = Uri.parse("http://10.0.2.2:8000/auth/login"); //127.0.0.1 points to the emulator, use 10.0.2.2 instead for local device

      try{
        setState(() {
          _isLoading = true;
        });
        final response = await http.post(
          url, 
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({ //convert to json string
            'email': email,
            'password': password
          })
        );

        //successful response, get token and store it, then go to home page
        if (response.statusCode == 200){
          //store token
          final data = jsonDecode(response.body);
          await secureStorage.write(key: "access_token", value: data['access_token']);
          setState(() => message='Success!');
          
          //next page
          if (!mounted) return; //check if this widget is still mounted (part of the tree) so pushing the context still works
          Navigator.push(context, MaterialPageRoute(builder: (context) => const MyHomePage()));
        }
        //unsuccessful response
        else{
          print("Status code: ${response.statusCode}");
          setState(() => message='Failed to login');
        }
      }

      //error
      catch(e) {
        setState(() {
          message = 'Error: $e';
        });
      }

      finally{
        setState(() => _isLoading = false,);
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Login', style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: Form(
        key: _formKey,
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: TextFormField(
              decoration: InputDecoration(labelText: 'email'),
              validator:(value) {
                if (value == null || value.isEmpty){
                  return "please enter a value";
                }
                return null;
              },
              onChanged: (value){
                email = value;
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: TextFormField(
              decoration: InputDecoration(labelText: 'password'),
              obscureText: true,
              validator:(value) {
                if (value == null || value.isEmpty){
                  return "please enter a value";
                }
                return null;
              },
              onChanged: (value){
                password = value;
              },
            ),
          ),
          SizedBox(height: 10),
          _isLoading
            ? CircularProgressIndicator()
            : ElevatedButton(
                onPressed: (){
                  if(_formKey.currentState!.validate()){ //validate inputs (not null or empty)
                    login(email, password);
                  }
                }, 
                child: Text('Login', style: TextStyle(color: Theme.of(context).colorScheme.onPrimary))
              ),
          SizedBox(height: 10),
          Text(message)
        ],)
      )
    );
  }
}


class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context){
    var theme = Theme.of(context);
    final secureStorage = const FlutterSecureStorage();

    Future<List> getBooks() async{

      print("getting books");

      //get the books witht the access token
      List booksList = [];
      final url = Uri.parse("http://10.0.2.2:8000/library");
      final accessToken = await secureStorage.read(key: 'access_token');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json'
        }
      );

      //update books list if successful
      if(response.statusCode == 200){
        final data = jsonDecode(response.body); //list of books
        booksList = data;
      }

      //failure to get books
      else{
        print("Error getting books: status - ${response.statusCode}");
        print("Response body: ${response.body}");
      }

      return booksList;
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text("My Books"),
      ),
      body: 
        FutureBuilder(
          future: getBooks(),
          builder: (context, asyncSnapshot){
            //loading
            if (asyncSnapshot.connectionState == ConnectionState.waiting){
              return Center(child: CircularProgressIndicator());
            }
            //error
            else if (asyncSnapshot.hasError){
              return Center(child: Text("Error: ${asyncSnapshot.error}"));
            }
            //load books
            else{
              final books = asyncSnapshot.data!;
              if (books.isEmpty){
                return Center(child: Text("No books found"));
              }
              return ListView(
                children: [
                  for (var book in books) BookCard(book: book)
                ]
              );
            }
          }
        )
    );
  }
}

class BookCard extends StatelessWidget{
  final Map book;
  const BookCard({super.key, required this.book});
  /*book is of form   
  {
    "id": "string",
    "title": "string",
    "author": "string"
  }
  */

  @override
  Widget build(BuildContext context){
    return Padding(
      padding: const EdgeInsets.all(20),
      child: ElevatedButton(
        onPressed: (){
          Navigator.push(context, MaterialPageRoute(builder: (context) => BookSummaryPage(book: book,)));
        }, 
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children:[
            //Image.network(book['thumbnail']!, width: 100, height:150, fit: BoxFit.cover), //TODO: thumbnail
            SizedBox(width: 10),
            Expanded(child: Column(
              children: [
                Text(book['title']!),
                SizedBox(height: 10,),
                Text('by ${book['author']}')
              ],
            )),
          ]
        ),
      ),
    );
  }
}

class BookSummaryPage extends StatelessWidget{
  final Map book;
  const BookSummaryPage({super.key, required this.book});
  final secureStorage = const FlutterSecureStorage();

  Future<Map> getBookInfo() async{
    //get the info of books with access token and book id
    final url = Uri.parse('http://10.0.2.2:8000/library/${book["id"]}');
    final accessToken = await secureStorage.read(key: 'access_token');
    Map bookInfo = {};

    final response = await http.get(
      url,
      headers:{
        'Authorization': 'Bearer $accessToken',
        'Content-Type': "application/json"
      }
    );

    //update book info if successful
    if (response.statusCode == 200){
      final data = jsonDecode(response.body);
      bookInfo = data;
    }

    //failure
    else{
      print("Error: status - ${response.statusCode}");
      print("Response body: ${response.body}");
    }

    return bookInfo;

  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(book['title']!)
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: FutureBuilder(
          future: getBookInfo(),
          builder: (context, asyncSnapshot) {
            if (asyncSnapshot.connectionState == ConnectionState.waiting){
              return Center(child: CircularProgressIndicator());
            }
            else if (asyncSnapshot.hasError){
              return Center(child: Text("Error retrieving book info"));
            }
            else{
              Map bookInfo = asyncSnapshot.data!;
              if (bookInfo.isEmpty){
                return Center(child: Text("No info found, check status"));
              }
              return Column(
                children:[
                  //Image.network(book['thumbnail']!, height: MediaQuery.of(context).size.height*0.4),
                  SizedBox(height:30),
                  Text(bookInfo['title']!, style: TextStyle(fontSize: 50)),
                  SizedBox(height:30),
                  Text(bookInfo['description']!, style: TextStyle(fontSize: 30)),
                  Expanded(child: SizedBox(),),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: (){
                            Navigator.push(context, MaterialPageRoute(builder: (context) => PdfPage(book: book,)));
                          }, 
                          child: Text('Read', style: TextStyle(fontSize: 30.0))
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: (){
                            Navigator.push(context, MaterialPageRoute(builder: (context) => VideoPlayerScreen(book: book,)));
                          }, 
                          child: Text('Watch', style: TextStyle(fontSize: 30.0))
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height:80)
                ]
              );
            }
          }
        ),
      )
    );
  }
}

class PdfPage extends StatelessWidget{
  final Map book;
  const PdfPage({super.key, required this.book});
  final secureStorage = const FlutterSecureStorage();

  Future<File> getFile() async{
    //check if book title is present in app documents directory
    final dir = await getApplicationDocumentsDirectory();
    bool found = false;
    File? file;
    await for (var entity in dir.list()){
      if(entity is File && entity.path.split(Platform.pathSeparator).last == book["title"]){
        found = true;
        file = entity;
      }
    }

    // if it is, simply return it
    if (found){
      print("pdf file found in app directory: $file");
      return file!;
    }

    // else download file from the book url
    else{
      print("pdf file not found in app directory, downloading...");
      //call api to generate pdf url
      String pdfUrl = "";
      Uri url = Uri.parse("http://10.0.2.2:8000/books/${book['id']}/download/pdf");
      final accessToken = await secureStorage.read(key: 'access_token');
      final response = await http.get(
        url,
        headers:{
          "Authorization": "Bearer $accessToken",
          "Content-Type": "application/json"
        }
      );

      if(response.statusCode == 200){
        final data = jsonDecode(response.body);
        pdfUrl = data['url'];
        print("successfully retrieved pdf url- $pdfUrl");
      }

      else{
        print("Error getting pdf url: status - ${response.statusCode}");
        print("Response body: ${response.body}");
        throw Exception('Failed to get pdf url');
      }

      //use pdfurl to get the pdf file
      url = Uri.parse(pdfUrl);
      final pdfResponse = await http.get(url);

      Uint8List bytes;
      if (pdfResponse.statusCode == 200){
        print("successfully retrieved pdf...");
        bytes =  pdfResponse.bodyBytes;
      }else{
        print("Error getting pdf: status - ${pdfResponse.statusCode}");
        throw Exception('Failed to get pdf');
      }

      //save it to app directory
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/${book["title"]}'); //filename will just be book title
      await file.writeAsBytes(bytes);

      return file;
    }
  }

  @override
  Widget build(BuildContext context){
    final theme = Theme.of(context);

    return FutureBuilder(
      future: getFile(),
      builder: (context, asyncSnapshot) {
        if (asyncSnapshot.connectionState == ConnectionState.waiting){
          return Center(child: CircularProgressIndicator());
        } else if(asyncSnapshot.hasError){
          return Center(child: Text("Error: ${asyncSnapshot.error}"));
        } else {
          return Scaffold(
            appBar: AppBar(
              title: Text(book["title"]!),
              backgroundColor: theme.colorScheme.secondaryContainer,
            ),
            body: SfPdfViewer.file(asyncSnapshot.data!, pageLayoutMode: PdfPageLayoutMode.single),
          );
        }
      }
    );
  }
}

class VideoPlayerScreen extends StatefulWidget {
  final Map book;
  const VideoPlayerScreen({super.key, required this.book});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _controller;
  final secureStorage = FlutterSecureStorage();
  bool isLoading = true;

  Future<void> intialiseVideo() async{

      //get video url
      String videoUrl = "";
      final url = Uri.parse("http://10.0.2.2:8000/books/${widget.book['id']}/download/video");
      final accessToken = await secureStorage.read(key: 'access_token');
      final response = await http.get(
        url,
        headers:{
          "Authorization": "Bearer $accessToken",
          "Content-Type": "application/json"
        }
      );

      if (response.statusCode == 200){
        final data = jsonDecode(response.body);
        videoUrl = data['url'];
        print("Got video url - $videoUrl");
      }
      else{
        print("Error getting video url: status - ${response.statusCode}");
        throw(Exception("Error getting video url"));
      }

      //set up controller
      _controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
      await _controller.initialize();

      //stop loading
      setState(() => isLoading = false);
    }
  

  @override
  void initState() {
    super.initState();
    intialiseVideo();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.book['title']!)),
      body: 
          isLoading
          ? Center(child: CircularProgressIndicator())
          : Stack(
            children:[
              Center(child: AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller)
              )),

              Center(
                child: AnimatedSwitcher(
                  duration: Duration(milliseconds: 10),
                  reverseDuration: Duration(milliseconds: 100),
                  child: _controller.value.isPlaying ? SizedBox() : Icon(Icons.play_arrow_rounded, color: Colors.white, size: 100) //empty when playing, when paused show pause play icon
                )
              ),
              
              GestureDetector(
                onTap: (){
                  setState( (){
                    print("Video tapped");
                    _controller.value.isPlaying ? _controller.pause() : _controller.play();
                  });
                }
              ), //order matters here! Gesture detector layer needs to be at the top
              ]
            )
      );
  }
}



/* Dummy data for testing 
    List<Map<String, String>> books = [
      {
        "title": "The Bee and the Elephant",
        "url": "https://freekidsbooks.org/wp-content/uploads/2021/04/the-bee-and-the-elephant-RTR-FKB.pdf",
        "thumbnail": "https://freekidsbooks.org/wp-content/uploads/2021/04/the-bee-and-the-elephant-RTR-FKB-300x261.jpg",
        "summary": "A little bee has lost his home and asks an elephant to help him find it.",
        "video": "https://ia800608.us.archive.org/30/items/BiliBili-BV1TswCeYEEc_p1-1EEY1C2T1VB/BV1TswCeYEEc_p1.mp4"
      },
      {
        "title": "An Umbrella for Druvi",
        "url": "https://freekidsbooks.org/wp-content/uploads/2020/10/an-umbrella-for-druvi-pratham-FKB.pdf",
        "thumbnail": "https://freekidsbooks.org/wp-content/uploads/2020/10/an-umbrella-for-druvi-pratham-FKB-300x252.jpg",
        "summary": "Druvi the dragonfly needs an umbrella to protect her wings from the rain.",
        "video": "https://dn721609.ca.archive.org/0/items/BiliBili-BV16z421k7di_p1-10VB/BV16z421k7di_p1.mp4"
      },
      {
        "title": "What Makes You Special",
        "url": "https://freekidsbooks.org/wp-content/uploads/2018/10/What-makes-you-special-FKB.pdf",
        "thumbnail": "https://www.frugalfeeds.com.au/wp-content/uploads/2023/01/KFC-8-Box-Tuesday.jpg",
        "summary": "A delightful book showcasing the unique qualities of various animals.",
        "video": "https://ia801709.us.archive.org/1/items/BiliBili-BV18h411571k_p1-10VB/BV18h411571k_p1.mp4"
        
      },
      {
        "title": "Elephant, Naughty Elephant",
        "url": "https://freekidsbooks.org/wp-content/uploads/2023/08/Elephant_Naughty_Elephant-FKB.pdf",
        "thumbnail": "https://freekidsbooks.org/wp-content/uploads/2023/08/Elephant_Naughty_Elephant-667x604.jpg",
        "summary": "A cute, beautifully illustrated text for young children about a naughty elephant.",
        "video": "https://ia800603.us.archive.org/15/items/BiliBili-BV1q34y1B7jC_p1-C2B6VB/BV1q34y1B7jC_p1.mp4"
      },
      {
        "title": "The Story of My Life – Helen Keller",
        "url": "https://freekidsbooks.org/wp-content/uploads/2019/12/FKB-The_Story_Of_My_Life-Hellen-Keller-PD.pdf",
        "thumbnail": "https://images2.minutemediacdn.com/image/upload/w_2025/shape/cover/sport/81472-wikimedia-commons-keller-2d50e25f1c6dc0d39fc865199fc77359.jpg",
        "summary": "The inspiring autobiography of Helen Keller, detailing her journey overcoming challenges.",
        "video": "https://ia800603.us.archive.org/15/items/BiliBili-BV1q34y1B7jC_p1-C2B6VB/BV1q34y1B7jC_p1.mp4"
      },
    ];
*/
