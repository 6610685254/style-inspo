import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'wardrobe_repository.dart';

class AddWardrobeScreen extends StatefulWidget {
  final File? initialImage;
  const AddWardrobeScreen({super.key, this.initialImage});

  @override
  State<AddWardrobeScreen> createState() => _AddWardrobeScreenState();
}

class _AddWardrobeScreenState extends State<AddWardrobeScreen> {
  final WardrobeRepository _repository = WardrobeRepository();
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  File? _imageFile;

  @override
  void initState() {
    super.initState();
    _imageFile = widget.initialImage;
  }
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

  final List<String> _seasons = ['All', 'Spring', 'Summer', 'Autumn', 'Winter'];
  String _selectedSeason = 'All';

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
      _showSnackBar('You must be logged in.');
      return null;
    }

    final fileName = 'img_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = FirebaseStorage.instance
        .ref('users/$userId/clothes_images/$fileName');

    try {
      await ref.putFile(image);
      return await ref.getDownloadURL();
    } on FirebaseException catch (e) {
      _showSnackBar('Upload failed: ${e.code} — ${e.message}');
      return null;
    } catch (e) {
      _showSnackBar('Upload failed: $e');
      return null;
    }
  }

  Future<void> _saveItem() async {
    // Validate image
    if (_imageFile == null) {
      _showSnackBar('Please select an image first.');
      return;
    }

    // Validate category (not part of the Form, so check manually)
    if (_selectedType == null) {
      _showSnackBar('Please select a category.');
      return;
    }

    // Validate color field
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isUploading = true);

    try {
      final imageUrl = await _uploadImageToStorage(_imageFile!);
      if (imageUrl == null) return; // error already shown via snackbar

      await _repository.addClothingItem(
        imageUrl: imageUrl,
        type: _selectedType!.toLowerCase(),
        color: _colorController.text.trim().toLowerCase(),
        season: _selectedSeason.toLowerCase(),
      );

      if (mounted) {
        _showSnackBar('Item added successfully!');
        Navigator.of(context).pop();
      }
    } catch (e) {
      _showSnackBar('Error: $e');
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
    return Scaffold(
      appBar: AppBar(title: const Text('Add New Clothes')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Photo picker area
              GestureDetector(
                onTap: _showOptionsBottomSheet,
                child: Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    image: _imageFile != null
                        ? DecorationImage(
                            image: FileImage(_imageFile!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _imageFile == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo_outlined,
                                size: 48,
                                color: Theme.of(context).colorScheme.onSurfaceVariant),
                            const SizedBox(height: 8),
                            Text(
                              'Choose your photo',
                              style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant),
                            ),
                          ],
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 24),

              // Add to (category chips)
              const Text('Add to',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _clothingTypes.map((type) {
                  final selected = _selectedType == type;
                  final onSurface = Theme.of(context).colorScheme.onSurface;
                  return ChoiceChip(
                    label: Text(type),
                    selected: selected,
                    selectedColor: onSurface,
                    labelStyle: TextStyle(
                      color: selected
                          ? Theme.of(context).colorScheme.surface
                          : onSurface,
                    ),
                    onSelected: (_) => setState(() => _selectedType = type),
                  );
                }).toList(),
              ),
              if (_selectedType == null)
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text('Please select a category',
                      style: TextStyle(color: Colors.red, fontSize: 12)),
                ),
              const SizedBox(height: 20),

              // Color field
              const Text('What color?',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _colorController,
                decoration: const InputDecoration(
                  hintText: 'e.g., Navy Blue',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    (value == null || value.trim().isEmpty)
                        ? 'Please enter a color'
                        : null,
              ),
              const SizedBox(height: 20),

              // Season
              const Text('Season',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _seasons.map((season) {
                  final selected = _selectedSeason == season;
                  final onSurface = Theme.of(context).colorScheme.onSurface;
                  return ChoiceChip(
                    label: Text(season),
                    selected: selected,
                    selectedColor: onSurface,
                    labelStyle: TextStyle(
                      color: selected
                          ? Theme.of(context).colorScheme.surface
                          : onSurface,
                    ),
                    onSelected: (_) =>
                        setState(() => _selectedSeason = season),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),

              // Add button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isUploading ? null : _saveItem,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isUploading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Add', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
