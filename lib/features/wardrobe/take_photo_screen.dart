import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'add_wardrobe_screen.dart';

class TakePhotoScreen extends StatefulWidget {
  const TakePhotoScreen({super.key});

  @override
  State<TakePhotoScreen> createState() => _TakePhotoScreenState();
}

class _TakePhotoScreenState extends State<TakePhotoScreen> {
  File? _photo;
  final _picker = ImagePicker();
  bool _picking = false;

  @override
  void initState() {
    super.initState();
    // Auto-launch camera on open
    WidgetsBinding.instance.addPostFrameCallback((_) => _takePhoto());
  }

  Future<void> _takePhoto() async {
    if (_picking) return;
    setState(() => _picking = true);
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (picked != null && mounted) {
        setState(() => _photo = File(picked.path));
      } else if (mounted) {
        Navigator.pop(context);
      }
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _pickFromGallery() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1080,
      maxHeight: 1080,
      imageQuality: 85,
    );
    if (picked != null && mounted) {
      setState(() => _photo = File(picked.path));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Add New Clothes'),
      ),
      body: _photo == null
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : Stack(
              fit: StackFit.expand,
              children: [
                Image.file(_photo!, fit: BoxFit.contain),

                // Bottom controls
                Positioned(
                  bottom: 32,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Gallery button
                      GestureDetector(
                        onTap: _pickFromGallery,
                        child: Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.photo_library,
                              color: Colors.white),
                        ),
                      ),

                      // Retake button
                      GestureDetector(
                        onTap: _takePhoto,
                        child: Container(
                          width: 64,
                          height: 64,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt,
                              color: Colors.black, size: 30),
                        ),
                      ),

                      // Use photo button
                      GestureDetector(
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  AddWardrobeScreen(initialImage: _photo),
                            ),
                          );
                        },
                        child: Container(
                          width: 52,
                          height: 52,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check,
                              color: Colors.black, size: 28),
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
