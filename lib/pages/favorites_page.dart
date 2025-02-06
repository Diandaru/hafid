import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../helpers/database_helper.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({Key? key}) : super(key: key);

  @override
  _FavoritesPageState createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  List<Map<String, dynamic>> _favoriteImages = [];

  @override
  void initState() {
    super.initState();
    _loadFavoriteImages();
  }

  Future<void> _loadFavoriteImages() async {
    final favorites = await DatabaseHelper.instance.getFavoriteImages();
    setState(() {
      _favoriteImages = favorites;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorites'),
      ),
      body: _favoriteImages.isEmpty
          ? const Center(child: Text('No favorites yet!'))
          : GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _favoriteImages.length,
              itemBuilder: (context, index) {
                final imageData = _favoriteImages[index];
                final imageBytes = imageData['image'] as List<int>;
                final image = Image.memory(Uint8List.fromList(imageBytes));

                return Container(
                  color: Colors.grey[300],
                  child: image,
                );
              },
            ),
    );
  }
}
