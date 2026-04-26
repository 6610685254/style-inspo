import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

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
  String? _selectedType;
  String? _selectedColorName;
  bool _isUploading = false;

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
  final List<Color> _colorOptions = [
    Colors.black,
    Colors.grey,
    Colors.red,
    Colors.pink,
    Colors.orange,
    Colors.yellow,
    Colors.green,
    Colors.blue,
    Colors.purple,
    Colors.brown,
    Colors.white,
  ];
  final List<String> _colorNames = [
    'black',
    'grey',
    'red',
    'pink',
    'orange',
    'yellow',
    'green',
    'blue',
    'purple',
    'brown',
    'white',
  ];

  final Set<String> _selectedStyleTags = {};
  final Set<String> _selectedWeatherTags = {};

  final List<String> _styleOptions = const [
    'casual',
    'minimal',
    'street',
    'formal',
    'sporty',
    'cute',
    'vintage',
  ];

  final List<String> _weatherOptions = const [
    'hot',
    'rainy',
    'cold',
    'indoor',
    'outdoor',
  ];

  @override
  void initState() {
    super.initState();
    _imageFile = widget.initialImage;
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        setState(() => _imageFile = File(pickedFile.path));
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

  Future<String?> _uploadImageToStorage(File image) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      _showSnackBar('You must be logged in.');
      return null;
    }

    final fileName = 'img_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = FirebaseStorage.instance.ref('users/$userId/clothes_images/$fileName');

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
    if (_imageFile == null) {
      _showSnackBar('Please select an image first.');
      return;
    }
    if (_selectedType == null) {
      _showSnackBar('Please select a category.');
      return;
    }
    if (_selectedColorName == null) {
      _showSnackBar('Please select a color.');
      return;
    }

    setState(() => _isUploading = true);

    try {
      final imageUrl = await _uploadImageToStorage(_imageFile!);
      if (imageUrl == null) return;

      await _repository.addClothingItem(
        imageUrl: imageUrl,
        type: _selectedType!.toLowerCase(),
        color: _selectedColorName!,
        season: _selectedSeason.toLowerCase(),
        styleTags: _selectedStyleTags.toList(),
        weatherTags: _selectedWeatherTags.toList(),
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

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
              GestureDetector(
                onTap: _showOptionsBottomSheet,
                child: Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    image: _imageFile != null
                        ? DecorationImage(image: FileImage(_imageFile!), fit: BoxFit.cover)
                        : null,
                  ),
                  child: _imageFile == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_a_photo_outlined,
                              size: 48,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Choose your photo',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 24),
              const Text('Add to', style: TextStyle(fontWeight: FontWeight.w600)),
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
                      color: selected ? Theme.of(context).colorScheme.surface : onSurface,
                    ),
                    onSelected: (_) => setState(() => _selectedType = type),
                  );
                }).toList(),
              ),
              if (_selectedType == null)
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text(
                    'Please select a category',
                    style: TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
              const SizedBox(height: 20),
              const Text('What color?', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              SizedBox(
                height: 52,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _colorOptions.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final isSelected = _selectedColorName == _colorNames[index];
                    return GestureDetector(
                      onTap: () => setState(() => _selectedColorName = _colorNames[index]),
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: _colorOptions[index],
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? Colors.black : Colors.grey.shade300,
                            width: isSelected ? 2.5 : 1.2,
                          ),
                        ),
                        child: _colorNames[index] == 'white'
                            ? Center(
                                child: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: isSelected ? Colors.black : Colors.grey.shade400,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              )
                            : null,
                      ),
                    );
                  },
                ),
              ),
              if (_selectedColorName == null)
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text(
                    'Please select a color',
                    style: TextStyle(color: Colors.red, fontSize: 12),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    'Selected: ${_selectedColorName!}',
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                  ),
                ),
              const SizedBox(height: 20),
              const Text('Season', style: TextStyle(fontWeight: FontWeight.w600)),
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
                      color: selected ? Theme.of(context).colorScheme.surface : onSurface,
                    ),
                    onSelected: (_) => setState(() => _selectedSeason = season),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 8),
              const Text('Style details (optional)', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              _TagSection(
                title: 'Style',
                options: _styleOptions,
                selectedTags: _selectedStyleTags,
                onToggle: (value) {
                  setState(() {
                    _selectedStyleTags.contains(value)
                        ? _selectedStyleTags.remove(value)
                        : _selectedStyleTags.add(value);
                  });
                },
              ),
              const SizedBox(height: 12),
              _TagSection(
                title: 'Weather',
                options: _weatherOptions,
                selectedTags: _selectedWeatherTags,
                onToggle: (value) {
                  setState(() {
                    _selectedWeatherTags.contains(value)
                        ? _selectedWeatherTags.remove(value)
                        : _selectedWeatherTags.add(value);
                  });
                },
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isUploading ? null : _saveItem,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _isUploading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
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

class _TagSection extends StatelessWidget {
  const _TagSection({
    required this.title,
    required this.options,
    required this.selectedTags,
    required this.onToggle,
  });

  final String title;
  final List<String> options;
  final Set<String> selectedTags;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final isSelected = selectedTags.contains(option);
            return FilterChip(
              label: Text(option),
              selected: isSelected,
              selectedColor: onSurface,
              labelStyle: TextStyle(
                color: isSelected ? Theme.of(context).colorScheme.surface : onSurface,
              ),
              onSelected: (_) => onToggle(option),
            );
          }).toList(),
        ),
      ],
    );
  }
}
