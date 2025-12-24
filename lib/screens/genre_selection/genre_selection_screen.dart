import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubits/movie_cubit.dart';
import '../../cubits/watchlist_cubit.dart';
import '../../models/genre.dart';
import '../../widgets/genre_tile.dart';
import '../discovery/discovery_screen.dart';
import '../../core/helpers.dart';

class GenreSelectionScreen extends StatefulWidget {
  const GenreSelectionScreen({super.key});

  @override
  State<GenreSelectionScreen> createState() => _GenreSelectionScreenState();
}

class _GenreSelectionScreenState extends State<GenreSelectionScreen> {
  List _searchResults = [];
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  void _onSearch(String query) async {
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    final results = await context.read<MovieCubit>().searchMovies(query);
    setState(() => _searchResults = results);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('MovieScout', style: TextStyle(fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        centerTitle: true,
        backgroundColor: Colors.black,
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: _searchResults.isNotEmpty
                ? _buildSearchList()
                : _buildGenreGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.25),
              blurRadius: 14,
              spreadRadius: 1,
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          onChanged: _onSearch,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Search any movie...',
            hintStyle: const TextStyle(color: Color(0xFF8E8E93)),
            prefixIcon: const Icon(Icons.search, color: Color(0xFFE50914)),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close, color: Color(0xFF8E8E93)),
                    onPressed: () {
                      _searchController.clear();
                      _onSearch('');
                      _searchFocusNode.unfocus();
                    },
                  )
                : null,
            filled: true,
            fillColor: const Color(0xFF111111),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchList() {
    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, i) {
        final movie = _searchResults[i];
        return ListTile(
          onLongPress: () => handleLongPress(context, movie),
          leading: movie['poster_path'] != null
              ? Image.network('https://image.tmdb.org/t/p/w92${movie['poster_path']}')
              : const Icon(Icons.movie),
          title: Text(movie['title'] ?? 'Unknown'),
          trailing: IconButton(
            icon: const Icon(Icons.add_circle_outline, color: Colors.greenAccent),
            onPressed: () {
              context.read<WatchlistCubit>().addToWatchlist(movie, 'Search');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Added to Watchlist!')),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildGenreGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.1,
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
      ),
      itemCount: genresList.length,
      itemBuilder: (context, index) {
        final genre = genresList[index];
        return GenreTile(
          genre: genre,
          onTap: () {
            context.read<MovieCubit>().fetchMovies(genre.label);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DiscoveryScreen(selectedGenre: genre.label),
              ),
            );
          },
        );
      },
    );
  }
}
