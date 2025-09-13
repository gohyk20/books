import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:http/http.dart' as http; 
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key}); //what is this bruh?

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Reader',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 183, 93, 58)),
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context){
    List<Map<String, String>> books = [{"title":"Lily and the busy bee", "url":"https://bookbucket0371.s3.ap-southeast-2.amazonaws.com/Lily%20and%20the%20Bee.pdf?response-content-disposition=inline&X-Amz-Content-Sha256=UNSIGNED-PAYLOAD&X-Amz-Security-Token=IQoJb3JpZ2luX2VjEM%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2FwEaDmFwLXNvdXRoZWFzdC0yIkcwRQIgK3Uu%2BtDz%2BGaSDHWOq4P9pBZe4kpa%2BwBgXsrF%2FXSpPp8CIQCRw2qJxnPeeSLCHGGBKEAZ6iaVUViZ69Po1%2Bu1Nhq8Cir5AghIEAAaDDc1NDMwOTc0MzA3NCIMDkNWNxm4pL6fFJUWKtYCLA2GOFagB%2BqLCZEe1jZb8RIEy2rT74XyYXYypS%2BbQV2vVaXKCH%2FBlWqNtWUcNtON7H4bMsw50QAP1%2BSj5r8gp5C5RlQrt9nAX7cuHyKXseugl%2BfH6uA0%2B8AqwA3kUeZNd5mebFQvDvrMMJpvvrKNqhCPzmAqep7eZeUChfaYxb%2BS2%2Bf3dpZqgshc8i%2FzSExRVW%2FxHStULWoN9eGvfngz55WQgw%2Fc13WdVoIymy82gOzovfpUJVaqLNdj1s1u%2FUn2ihVUUNdEIAE8KvGZ4EsosUbRUP%2F1T4udjz%2B2UHva5r2brwxogfc1wzMbtmGXZjcM8Yy5Salju%2FVeniZAGrmzVhX1no%2BPn0yhsG3FIX41QLUkEYhhcGxQ9YgRcEPcZ6PErnMqeMl7kK3Mpl9GRgw3KZyMn3GAVqDYeLIx6U5liUf9oHW7U5IMStChAf3%2FqXVkzcw9JYq1MLrdlMYGOo8Cr0azEdmlZ%2FsQUKbrpsMlqDyRUQt6%2FrNAu1QX5GmvEWsEjEANNc9qXAcHuVUIhIgOlZpNbdVRrcUmbdh1r0TJR7oszPTsFfu5KGbdKHYikj%2FImMKNsxkHyTGru0%2Bn84iV2BjiCR%2FHpHcFWUoRMjvG5Aa%2BZ29Kck9nZSA027e1OjQylFcldQJHWYwAYe8A8a1PZxqjQvwy5dIESrhkZni6Zct3BnzKy9AablRR0AvlK1iyLI1H8KaLbMv%2BPYophS32%2F7nPt2N7uMzy7x2R0FxBnfA2EDatNFI1k9R1aBy5E%2FD4ibrz3p4aAa1lZjt%2FROVzP2goBHgP3Kjnz6HGhMJVjC5Rj%2FtciicZ08eAAxlveA%3D%3D&X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=ASIA27IC5IHRF7GLJ4B2%2F20250913%2Fap-southeast-2%2Fs3%2Faws4_request&X-Amz-Date=20250913T143452Z&X-Amz-Expires=10800&X-Amz-SignedHeaders=host&X-Amz-Signature=4991698cf5f38fd1278704014502587d0ce2875ce7eda2d638a06e019a1574e3"}];
    var theme = Theme.of(context);


    return Scaffold(
      appBar: AppBar(
        title: Text("My Books"),
        backgroundColor: theme.colorScheme.secondaryContainer,
      ),
      body: GridView.count(
        crossAxisCount: 3,
        children: [
          for (var book in books)
            BookCard(book: book)
        ]
      )
    );
  }
}

class BookCard extends StatelessWidget{
  final Map<String, String> book;
  const BookCard({super.key, required this.book});

  @override
  Widget build(BuildContext context){
    return Padding(
      padding: const EdgeInsets.all(20),
      child: ElevatedButton(
        onPressed: (){
          Navigator.push(context, MaterialPageRoute(builder: (context) => PdfPage(book: book,)));
        }, 
        child: Text(book['title']!),
      ),
    );
  }
}

class PdfPage extends StatelessWidget{
  final Map<String, String> book;
  const PdfPage({super.key, required this.book});

  Future<File> getFile() async{
    //check if book title is present in app documents directory
    final dir = await getApplicationDocumentsDirectory();
    bool found = false;
    File? file;
    await for (var entity in dir.list()){
      if(entity is File && entity.path.split(Platform.pathSeparator).last == book['title']){
        found = true;
        file = entity;
      }
    }

    // if it is, simply return it
    if (found){
      return file!;
    }

    // else download file from the book url
    else{
      //make a get request to the book url to get the pdf bytes
      final url = Uri.parse(book['url']!);
      final response = await http.get(url);
      Uint8List bytes;
      if (response.statusCode == 200){
        bytes =  response.bodyBytes;
      }else{
        print(url);
        throw Exception('Failed to get pdf');
      }

      //save it to app directory
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/${book['title']}'); //filename will just be book title
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
            body: SfPdfViewer.file(asyncSnapshot.data!),
          );
        }
      }
    );
  }
}
