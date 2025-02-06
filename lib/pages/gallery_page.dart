import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:Hafiz_gallery/pages/favorites_page.dart';
import 'package:Hafiz_gallery/pages/home_page.dart';
import 'package:image_picker/image_picker.dart';
import '../helpers/database_helper.dart';

class GalleryPage extends StatefulWidget {
  const GalleryPage({Key? key}) : super(key: key);

  @override
  _GalleryPageState createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  final ImagePicker _picker = ImagePicker();
  List<Map<String, dynamic>> _imageFileList = [];

  @override
  void initState() {
    super.initState();
    _loadImages();
  }

  Future<void> _loadImages() async {
    final images = await DatabaseHelper.instance.getAllImages();
    setState(() {
      _imageFileList = images;
    });
  }

  Future<void> _pickImage() async {
    final pickedFiles = await _picker.pickMultiImage();

    if (pickedFiles != null && pickedFiles.isNotEmpty) {
      for (var pickedFile in pickedFiles) {
        final imageFile = File(pickedFile.path);
        final date = DateTime.now();

        // Simpan gambar ke database
        await DatabaseHelper.instance.insertImage(imageFile, date);

        // Muat gambar terbaru dari database
        _loadImages();
      }
    }
  }

  Future<void> _deleteImage(int id) async {
    await DatabaseHelper.instance.deleteImage(id);
    _loadImages();
  }

  Future<void> _toggleFavorite(int id, bool isFavorite) async {
    // Perbarui status favorit gambar
    await DatabaseHelper.instance.updateFavoriteStatus(id, !isFavorite);

    // Muat ulang gambar di galeri
    _loadImages();

    // Jika gambar baru saja ditambahkan ke favorit
    if (!isFavorite) {
      // Pop dialog setelah mengklik favorite
      Navigator.of(context).pop();

      // Navigasikan ke HomePage, lalu ke FavoritesPage
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const HomePage(), // Menavigasi kembali ke HomePage
        ),
      ).then((_) {
        // Setelah kembali ke HomePage, navigasi langsung ke FavoritesPage
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const FavoritesPage(),
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Galeri'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _pickImage,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: _imageFileList.length,
          itemBuilder: (context, index) {
            final imageData = _imageFileList[index];
            final imageBytes = imageData['image'] as List<int>;
            final image = Image.memory(Uint8List.fromList(imageBytes));

            return GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    return Dialog(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          image,
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              'Ditambahkan pada: ${imageData['date']}',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              IconButton(
                                icon: Icon(
                                  imageData['is_favorite'] == 1
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: imageData['is_favorite'] == 1
                                      ? Colors.red
                                      : null,
                                ),
                                onPressed: () {
                                  _toggleFavorite(
                                    imageData['id'],
                                    imageData['is_favorite'] == 1,
                                  );
                                },
                              ),
                              TextButton(
                                onPressed: () {
                                  _deleteImage(imageData['id']);
                                  Navigator.of(context).pop(); // Close dialog
                                },
                                child: const Text('Hapus'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
              child: Container(
                color: Colors.grey[300],
                child: image,
              ),
            );
          },
        ),
      ),
    );
  }
}
