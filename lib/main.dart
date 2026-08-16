import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'groq_service.dart';
void main() {
  runApp(const SnapshotChefApp());
}

class SnapshotChefApp extends StatelessWidget {
  const SnapshotChefApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SnapshotChef',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  File? selectedImage;
  String? result;
  bool loading = false;

  Future <void> takePhoto() async {
    final picker = ImagePicker();

    final image = await picker.pickImage(
      source: ImageSource.camera,
    );

    if(image == null) return;

    setState(() {
      selectedImage = File(image.path);
    });
  }

  Future<void> analyzeImage() async {
    if(selectedImage == null) return;

    setState(() {
      loading = true;
      result = null;
    });

    try {
      final response = await GroqService.analyzeFridge(
        selectedImage!,
      );

      setState(() {
        result = response;
      });
    } catch(e) {
      setState(() {
        result = 'Something went Wrong: $e';
      });
    }finally {
      setState(() {
        loading = false;
      });
    }
  }
  Future<void> selectPhoto() async {
    final picker = ImagePicker();

    final image = await picker.pickImage(
      source: ImageSource.gallery,
    );

    if(image == null) return;

    setState(() {
      selectedImage = File(image.path);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Snapshot Chef'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if(selectedImage != null) 
                Image.file(
                  selectedImage!,
                  height: 300,
                )
                else
                  const Icon(
                    Icons.kitchen,
                    size: 120,
                  ),

                  const SizedBox(height: 30),

                  ElevatedButton.icon(
                    onPressed: takePhoto,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Take a snapshot of refrigerator'),
                  ),

                  const SizedBox(height: 10),

                  OutlinedButton.icon(
                    onPressed: selectPhoto,
                    icon: const Icon(Icons.photo),
                    label: const Text('Choose from Gallery'),
                  ),

                  const SizedBox(height: 10),

                  ElevatedButton(
                    onPressed: loading ? null : analyzeImage,
                    child: loading
                    ? const CircularProgressIndicator()
                    : const Text('Analyze My Fridge'),
                  ),
                  
                  const SizedBox(height: 10),

                  if(result != null)
                    Expanded(
                      child: SingleChildScrollView(
                        child: Text(result!),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}