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
      title: 'Snapshot Chef',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
        ),
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
  final ImagePicker _picker = ImagePicker();

  XFile? selectedImage;
  String? result;
  bool loading = false;

  // Take a photo using the camera
  Future<void> takePhoto() async {
    try {
      final image = await _picker.pickImage(
        source: ImageSource.camera,
      );

      if (image == null) return;

      setState(() {
        selectedImage = image;
        result = null;
      });
    } catch (e) {
      setState(() {
        result = 'Unable to take photo: $e';
      });
    }
  }

  // Choose an existing image
  Future<void> selectPhoto() async {
    try {
      final image = await _picker.pickImage(
        source: ImageSource.gallery,
      );

      if (image == null) return;

      setState(() {
        selectedImage = image;
        result = null;
      });
    } catch (e) {
      setState(() {
        result = 'Unable to select photo: $e';
      });
    }
  }

  // Send the image to the Cloudflare Worker
  Future<void> analyzeImage() async {
    if (selectedImage == null || loading) return;

    setState(() {
      loading = true;
      result = null;
    });

    try {
      final response = await GroqService.analyzeFridge(
        selectedImage!,
      );

      if (!mounted) return;

      setState(() {
        result = response;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        result = 'Something went wrong:\n$e';
      });
    } finally {
      if (!mounted) return;

      setState(() {
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Snapshot Chef'
        ),
        centerTitle: true,
        leading: const Icon(
          Icons.kitchen,
          size: 40,
        )
      ),
      
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),

          child: Column(
            children: [

              // Image preview
              Expanded(
                flex: 4,
                child: Center(
                  child: selectedImage == null
                      ? const Icon(
                          Icons.kitchen,
                          size: 120,
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(16),

                          child: Image.network(
                            selectedImage!.path,
                            height: 300,
                            fit: BoxFit.cover,

                            // Useful loading indicator
                            loadingBuilder:
                                (context, child, loadingProgress) {
                              if (loadingProgress == null) {
                                return child;
                              }

                              return const SizedBox(
                                height: 300,
                                child: Center(
                                  child:
                                      CircularProgressIndicator(),
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 20),

              // Camera button
              SizedBox(
                height: 50,
                width: 800,
                child: ElevatedButton.icon(
                  onPressed: loading ? null : takePhoto,
                  icon: const Icon(Icons.camera_alt, size: 25),
                  label:  const Text(
                    'Take a Snapshot of Refrigerator',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    )
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Gallery button
              SizedBox(
                height: 50,
                width: 800,
                child: OutlinedButton.icon(
                  onPressed: loading ? null : selectPhoto,
                  icon: const Icon(Icons.photo, size: 25),
                  label: const Text(
                    'Choose from Gallery',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    )
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Analyze button
              SizedBox(
                height: 50,
                width: 800,
                child: ElevatedButton(
                  onPressed:
                      selectedImage == null || loading
                          ? null
                          : analyzeImage,

                  child: loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Analyze My Fridge',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          )
                        ),
                ),
              ),

              const SizedBox(height: 20),

              // AI result
              if (result != null)
                Expanded(
                  flex: 3,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),

                      child: SingleChildScrollView(
                        child: Text(
                          result!,
                          style: const TextStyle(
                            fontSize: 16,
                            height: 1.5,
                          ),
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
  }
}