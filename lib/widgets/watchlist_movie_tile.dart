import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubits/watchlist_cubit.dart';
import '../cubits/movie_cubit.dart';
import '../core/helpers.dart';

class WatchlistMovieTile extends StatelessWidget {
  final Map<String, dynamic> movie;
  final bool isExpanded;
  final VoidCallback toggleExpanded;

  const WatchlistMovieTile({
    super.key,
    required this.movie,
    required this.isExpanded,
    required this.toggleExpanded,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE50914).withOpacity(0.25),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        children: [
          _buildHeader(context),
          if (isExpanded) _buildExpandedDetails(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: movie['poster_path'] != null
              ? Image.network(
                  'https://image.tmdb.org/t/p/w154${movie['poster_path']}',
                  height: 90,
                  width: 60,
                  fit: BoxFit.cover,
                )
              : Container(
                  height: 90,
                  width: 60,
                  color: Colors.grey.shade800,
                  child: const Icon(Icons.movie),
                ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                movie['title'] ?? 'Unknown',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE50914).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  movie['saved_Genre'],
                  style: const TextStyle(color: Color(0xFFE50914), fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline, color: Color(0xFFE50914)),
          onPressed: () => context.read<WatchlistCubit>().removeFromWatchlist(movie['id']),
        ),
        IconButton(
          icon: Icon(isExpanded ? Icons.info : Icons.info_outline, color: Colors.white),
          onPressed: toggleExpanded,
        ),
      ],
    );
  }

  Widget _buildExpandedDetails(BuildContext context) {
    return FutureBuilder<Map<String, String>>(
      future: context.read<MovieCubit>().fetchMovieDetails(movie['id']),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Padding(
            padding: EdgeInsets.all(8.0),
            child: Center(child: CircularProgressIndicator()),
          );
        final details = snapshot.data!;
        return Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => launchURL('https://www.youtube.com/watch?v=${details['trailer_key']}'),
                child: Row(
                  children: const [
                    Icon(Icons.play_circle, color: Color(0xFFD40000)),
                    SizedBox(width: 8),
                    Text('Watch Trailer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500, decoration: TextDecoration.underline)),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: () => launchURL('https://www.imdb.com/title/${details['imdb_id']}'),
                child: Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber),
                    const SizedBox(width: 8),
                    Text('IMDb Rating: ${details['vote_average']}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, decoration: TextDecoration.underline)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
