import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import '../../cubits/movie_cubit.dart';
import '../../cubits/watchlist_cubit.dart';
import '../../widgets/movie_card.dart';
import '../../core/helpers.dart';

class DiscoveryScreen extends StatelessWidget {
  final String selectedGenre;

  const DiscoveryScreen({super.key, required this.selectedGenre});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Genre: $selectedGenre'),
        elevation: 0,
        backgroundColor: Colors.black,
      ),
      body: BlocBuilder<MovieCubit, MovieState>(
        builder: (context, state) {
          if (state is MovieLoading) return const Center(child: CircularProgressIndicator());
          if (state is MovieLoaded) {
            return CardSwiper(
              cardsCount: state.movies.length,
              onSwipe: (prev, curr, dir) {
                if (dir == CardSwiperDirection.right) {
                  context.read<WatchlistCubit>().addToWatchlist(
                        state.movies[prev],
                        selectedGenre,
                      );
                }
                return true;
              },
              cardBuilder: (context, index, x, y) {
                final movie = state.movies[index];
                return MovieCard(
                  movie: movie,
                  onLongPress: () => handleLongPress(context, movie),
                );
              },
            );
          }
          return const Center(child: Text('Pick a Genre!'));
        },
      ),
    );
  }
}
