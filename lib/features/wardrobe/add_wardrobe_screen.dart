import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart'; // for Firebase.app()
import 'wardrobe_repository.dart';

class AddWardrobeScreen extends StatefulWidget {
  const AddWardrobeScreen({super.key});

  @override
  State<AddWardrobeScreen> createState() => _AddWardrobeScreenState();
}

class _AddWardrobeScreenState extends State<AddWardrobeScreen> {
  final WardrobeRepository _repository = WardrobeRepository();
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  File? _imageFile;
  String? _selectedType;
  final TextEditingController _colorController = TextEditingController();
  bool _isUploading = false;

  // Predefined types for consistency. You can add more.
  final List<String> _clothingTypes = [
    'Top',
    'Bottom',
    'Shoes',
    'Outerwear',
    'Dress',
    'Accessory',
  ];

  @override
  void dispose() {
    _colorController.dispose();
    super.dispose();
  }

  // --- Logic to Pick Images ---

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1080, // Compress large images appropriately
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      _showSnackBar('Failed to pick image: $e');
    }
  }

  void _showOptionsBottomSheet() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Photo Library'),
                onTap: () {
                  _pickImage(ImageSource.gallery);
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Camera'),
                onTap: () {
                  _pickImage(ImageSource.camera);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // --- Logic to Upload and Save ---

  Future<String?> _uploadImageToStorage(File image) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      _showSnackBar('You must be logged in to upload images.');
      return null;
    }

    // Unique filename based on timestamp to avoid collisions
    final String fileName = 'img_${DateTime.now().millisecondsSinceEpoch}.jpg';

    // Use the bucket defined in the Firebase options so we don't accidentally
    // talk to the wrong storage instance. (The generated options sometimes use
    // the .firebasestorage.app host while the actual bucket is *.appspot.com.)
    final String? bucket = Firebase.app().options.storageBucket;
    final FirebaseStorage storage = bucket != null
        ? FirebaseStorage.instanceFor(bucket: bucket)
        : FirebaseStorage.instance;

    final Reference storageRef = storage
        .ref()
        .child('users')
        .child(userId)
        .child('clothes_images')
        .child(fileName);

    // Log where we're writing, helps debug ``object-not-found`` issues.
    debugPrint(
      'uploading file to bucket=${storageRef.bucket} '
      'path=${storageRef.fullPath}',
    );

    try {
      final TaskSnapshot snapshot = await storageRef.putFile(image);
      if (snapshot.state != TaskState.success) {
        throw FirebaseException(
          plugin: 'firebase_storage',
          code: 'upload-failed',
          message: 'Upload task ended in ${snapshot.state}',
        );
      }

      final String downloadUrl = await storageRef.getDownloadURL();
      debugPrint('download url obtained: $downloadUrl');
      return downloadUrl;
    } on FirebaseException catch (e) {
      // Any Firebase-specific error: bucket mismatch, permission denied, etc.
      debugPrint(
        'Firebase Storage Error @ ${storageRef.bucket}/${storageRef.fullPath}: '
        '${e.code} - ${e.message}',
      );
      _showSnackBar('Storage Error: ${e.code}');
      return null;
    } catch (e) {
      debugPrint('General error uploading image: $e');
      _showSnackBar('Failed to upload image: $e');
      return null;
    }
  }

  Future<void> _saveItem() async {
    if (!_formKey.currentState!.validate()) return;
    if (_imageFile == null) {
      _showSnackBar('Please select an image first.');
      return;
    }

    setState(() => _isUploading = true);

    try {
      // 1. Upload image to Firebase Storage
      final imageUrl = await _uploadImageToStorage(_imageFile!);

      if (imageUrl == null) throw Exception("Image upload failed");

      // 2. Save metadata to Firestore using your repository
      // Note: WardrobeRepository.addItem needs to accept these parameters.
      // If it doesn't yet, we need to update it.
      await _repository.addClothingItem(
        imageUrl: imageUrl,
        type: _selectedType!.toLowerCase(),
        color: _colorController.text.trim().toLowerCase(),
      );

      if (mounted) {
        _showSnackBar('Item added successfully!');
        Navigator.of(context).pop(); // Go back to wardrobe screen
      }
    } catch (e) {
      _showSnackBar('Error saving item: $e');
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  // --- UI Build ---

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Add New Item')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image Selection Area
              GestureDetector(
                onTap: _showOptionsBottomSheet,
                child: AspectRatio(
                  aspectRatio: 1.0, // Square container
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(16),
                      image: _imageFile != null
                          ? DecorationImage(
                              image: FileImage(_imageFile!),
                              fit: BoxFit.cover,
                            )
                          : null,
                      border: Border.all(
                        color: theme.colorScheme.outline.withOpacity(0.2),
                      ),
                    ),
                    child: _imageFile == null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_a_photo_outlined,
                                size: 64,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Tap to add photo',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          )
                        : null, // Image shows via DecorationImage
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Clothing Type Dropdown
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.surface,
                ),
                items: _clothingTypes.map((String type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _selectedType = newValue;
                  });
                },
                validator: (value) =>
                    value == null ? 'Please select a category' : null,
              ),
              const SizedBox(height: 16),

              // Color Text Field
              TextFormField(
                controller: _colorController,
                decoration: InputDecoration(
                  labelText: 'Color',
                  hintText: 'e.g., Navy Blue',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.surface,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a color';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Save Button (Using your custom StyleButton if compatible, else standard)
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isUploading ? null : _saveItem,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isUploading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Save to Wardrobe',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
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
