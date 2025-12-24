import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import '../../cubits/movie_cubit.dart';
import '../../cubits/watchlist_cubit.dart';
import '../../core/helpers.dart';

class DiscoveryScreen extends StatelessWidget {
  final String selectedGenre;

  const DiscoveryScreen({super.key, required this.selectedGenre});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Responsive card size based on available height
    final maxCardHeight = screenHeight * 0.95; // at most 50% of screen height
    final cardWidth = screenWidth * 0.9;
    final titleFontSize = screenWidth * 0.06;

    return Scaffold(
      appBar: AppBar(
        title: Text('Genre: $selectedGenre'),
        elevation: 0,
        backgroundColor: Colors.black,
      ),
      body: BlocBuilder<MovieCubit, MovieState>(
        builder: (context, state) {
          if (state is MovieLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is MovieLoaded) {
            final movies = state.movies;
            return Center(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Card height is constrained by available space
                  final cardHeight = constraints.maxHeight * 0.7;

                  return CardSwiper(
                    cardsCount: movies.length,
                    onSwipe: (prev, curr, dir) {
                      if (dir == CardSwiperDirection.right) {
                        context.read<WatchlistCubit>().addToWatchlist(
                          movies[prev],
                          selectedGenre,
                        );
                      }
                      return true;
                    },
                    cardBuilder: (context, index, x, y) {
                      final movie = movies[index];
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: SizedBox(
                              width: cardWidth,
                              child: Text(
                                movie['title'] ?? 'Unknown',
                                style: TextStyle(
                                  fontSize: titleFontSize,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          Container(
                            width: cardWidth,
                            height: cardHeight > maxCardHeight
                                ? maxCardHeight
                                : cardHeight,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(25),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.red.withOpacity(0.25),
                                  blurRadius: 14,
                                  spreadRadius: 2,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(25),
                              child: GestureDetector(
                                onLongPress: () =>
                                    handleLongPress(context, movie),
                                child: Image.network(
                                  'https://image.tmdb.org/t/p/w500${movie['poster_path']}',
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            );
          }
          return const Center(child: Text('Pick a Genre!'));
        },
      ),
    );
  }
}
