import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ProductUploadPage extends StatefulWidget {
  final String userEmail;

  const ProductUploadPage({Key? key, required this.userEmail}) : super(key: key);

  @override
  _ProductUploadPageState createState() => _ProductUploadPageState();
}

class _ProductUploadPageState extends State<ProductUploadPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _basePriceController = TextEditingController();
  final TextEditingController _smallPriceController = TextEditingController();
  final TextEditingController _mediumPriceController = TextEditingController();
  final TextEditingController _largePriceController = TextEditingController();
  final TextEditingController _extraLargePriceController = TextEditingController();

  File? _selectedImage;
  String? _imageUrl;
  bool _hasSizes = false;
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _basePriceController.dispose();
    _smallPriceController.dispose();
    _mediumPriceController.dispose();
    _largePriceController.dispose();
    _extraLargePriceController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  Future<String?> _uploadImageToCloudinary(File imageFile) async {
    try {
      // Load Cloudinary credentials from environment variables
      final cloudName = dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? 'dm1wcgwwi';
      final uploadPreset = dotenv.env['CLOUDINARY_UPLOAD_PRESET'] ?? 'craftelle_upload';

      print('📤 Starting upload to Cloudinary...');
      print('☁️ Cloud Name: $cloudName');
      print('🔑 Upload Preset: $uploadPreset');

      // Use direct HTTP upload
      final uri = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');

      var request = http.MultipartRequest('POST', uri);
      request.fields['upload_preset'] = uploadPreset;
      // Note: folder is configured in the upload preset, not passed here

      // Add the image file
      request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      print('📡 Sending request to Cloudinary...');

      // Send the request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('📥 Response status: ${response.statusCode}');
      print('📄 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final secureUrl = responseData['secure_url'];
        print('✅ Upload successful! URL: $secureUrl');
        return secureUrl;
      } else {
        print('❌ Cloudinary error: ${response.statusCode}');
        print('📋 Error details: ${response.body}');

        // Parse error message from response
        String errorMessage = 'Upload failed with status ${response.statusCode}';
        try {
          final errorData = json.decode(response.body);
          if (errorData['error'] != null && errorData['error']['message'] != null) {
            errorMessage = errorData['error']['message'];
          }
        } catch (_) {
          // Use default error message if parsing fails
        }

        // Show error dialog
        if (mounted) {
          _showErrorDialog(
            'Upload Failed',
            '$errorMessage\n\nStatus Code: ${response.statusCode}\n\nPlease check:\n• Upload preset is "unsigned"\n• Cloud name is correct\n• Preset name: craftelle_upload',
          );
        }
        return null;
      }
    } catch (e, stackTrace) {
      print('❌ Error uploading image: $e');
      print('📚 Stack trace: $stackTrace');

      if (mounted) {
        _showErrorDialog(
          'Upload Error',
          '${e.toString()}\n\nPlease check your internet connection and Cloudinary settings.',
        );
      }
      return null;
    }
  }

  Future<void> _submitProduct() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedImage == null) {
      _showErrorDialog(
        'Image Required',
        'Please select an image for your product before uploading.',
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Upload image first
      final imageUrl = await _uploadImageToCloudinary(_selectedImage!);

      if (imageUrl == null) {
        // Error dialog already shown by _uploadImageToCloudinary
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Prepare product data
      final productData = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'imageUrl': imageUrl,
        'hasSizes': _hasSizes,
        'sellerEmail': widget.userEmail,
        'sellerName': widget.userEmail.split('@')[0],
      };

      if (_hasSizes) {
        productData['sizePrices'] = {
          if (_smallPriceController.text.isNotEmpty)
            'small': double.parse(_smallPriceController.text),
          if (_mediumPriceController.text.isNotEmpty)
            'medium': double.parse(_mediumPriceController.text),
          if (_largePriceController.text.isNotEmpty)
            'large': double.parse(_largePriceController.text),
          if (_extraLargePriceController.text.isNotEmpty)
            'extraLarge': double.parse(_extraLargePriceController.text),
        };
      } else {
        productData['basePrice'] = double.parse(_basePriceController.text);
      }

      print('📦 Submitting product to backend...');

      // Submit to backend
      final response = await http.post(
        Uri.parse('https://neurosense-palsy.fly.dev/api/v1/products'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(productData),
      );

      print('📥 Backend response: ${response.statusCode}');
      final responseData = json.decode(response.body);

      if (response.statusCode == 201 && responseData['success']) {
        print('✅ Product created successfully!');
        _showSuccessDialog();
        _clearForm();
      } else {
        print('❌ Backend error: ${responseData['message']}');
        _showErrorDialog(
          'Product Creation Failed',
          responseData['message'] ?? 'Failed to create product. Please try again.',
        );
      }
    } catch (e) {
      print('❌ Error in _submitProduct: $e');
      _showErrorDialog(
        'Error',
        'An error occurred: ${e.toString()}',
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _clearForm() {
    _nameController.clear();
    _descriptionController.clear();
    _basePriceController.clear();
    _smallPriceController.clear();
    _mediumPriceController.clear();
    _largePriceController.clear();
    _extraLargePriceController.clear();
    setState(() {
      _selectedImage = null;
      _hasSizes = false;
    });
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle,
                color: Color(0xFFFDA4AF),
                size: 64,
              ),
              const SizedBox(height: 16),
              const Text(
                'Product Uploaded Successfully!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Your masterpiece is now live in the collection',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFDA4AF),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: const Text("Done"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                message,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: const Text("Close"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Create Your Masterpiece',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFDA4AF),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Share your beautiful creation with the world',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),

              // Image Upload
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFDA4AF), width: 2),
                  ),
                  child: _selectedImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.file(
                            _selectedImage!,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.add_photo_alternate,
                              size: 64,
                              color: Color(0xFFFDA4AF),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Tap to upload image',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 24),

              // Product Name
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Product Name',
                  hintText: 'e.g., Handmade Rose Bouquet',
                  prefixIcon: const Icon(Icons.label, color: Color(0xFFFDA4AF)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFFDA4AF), width: 2),
                  ),
                ),
                validator: (value) => value?.isEmpty ?? true ? 'Enter product name' : null,
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Description',
                  hintText: 'Tell us about your beautiful creation...',
                  prefixIcon: const Icon(Icons.description, color: Color(0xFFFDA4AF)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFFDA4AF), width: 2),
                  ),
                ),
                validator: (value) => value?.isEmpty ?? true ? 'Enter description' : null,
              ),
              const SizedBox(height: 16),

              // Has Sizes Switch
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.straighten, color: Color(0xFFFDA4AF)),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Does this product have different sizes?',
                        style: TextStyle(fontSize: 15),
                      ),
                    ),
                    Switch(
                      value: _hasSizes,
                      onChanged: (value) {
                        setState(() {
                          _hasSizes = value;
                        });
                      },
                      activeColor: const Color(0xFFFDA4AF),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Pricing Section
              if (!_hasSizes) ...[
                TextFormField(
                  controller: _basePriceController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Price (GH₵)',
                    hintText: 'e.g., 150',
                    prefixIcon: const Icon(Icons.attach_money, color: Color(0xFFFDA4AF)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFFDA4AF), width: 2),
                    ),
                  ),
                  validator: (value) => value?.isEmpty ?? true ? 'Enter price' : null,
                ),
              ] else ...[
                const Text(
                  'Size Pricing',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFFDA4AF),
                  ),
                ),
                const SizedBox(height: 12),
                _buildSizePriceField('Small', _smallPriceController, Icons.crop_square),
                const SizedBox(height: 12),
                _buildSizePriceField('Medium', _mediumPriceController, Icons.crop_din),
                const SizedBox(height: 12),
                _buildSizePriceField('Large', _largePriceController, Icons.crop_landscape),
                const SizedBox(height: 12),
                _buildSizePriceField('Extra Large', _extraLargePriceController, Icons.crop_free),
              ],

              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitProduct,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFDA4AF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 3,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.cloud_upload, size: 24),
                            SizedBox(width: 12),
                            Text(
                              'Upload Masterpiece',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSizePriceField(String label, TextEditingController controller, IconData icon) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: '$label (GH₵)',
        hintText: 'Optional',
        prefixIcon: Icon(icon, color: const Color(0xFFFDA4AF)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFFDA4AF), width: 2),
        ),
      ),
    );
  }
}
