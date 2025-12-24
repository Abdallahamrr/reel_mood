import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/genre.dart';

abstract class MovieState {}
class MovieInitial extends MovieState {}
class MovieLoading extends MovieState {}
class MovieLoaded extends MovieState {
  final List movies;
  MovieLoaded(this.movies);
}

class MovieCubit extends Cubit<MovieState> {
  MovieCubit() : super(MovieInitial());
  String get _apiKey => dotenv.env['TMDB_API_KEY'] ?? '';

  void fetchMovies(String genreLabel) async {
    if (_apiKey.isEmpty) return;
    emit(MovieLoading());
    try {
      final genre = genresList.firstWhere((g) => g.label == genreLabel);
      Map<String, dynamic> params = {
        'api_key': _apiKey,
        'with_genres': genre.genreId,
        'sort_by': 'popularity.desc',
      };
      if (genreLabel == 'Nostalgic') {
        params['release_date.lte'] = '2010-12-31';
        params['with_genres'] = '18,10751';
      }
      final response = await Dio().get('https://api.themoviedb.org/3/discover/movie', queryParameters: params);
      emit(MovieLoaded(response.data['results']));
    } catch (e) {
      emit(MovieInitial());
    }
  }

  Future<List> searchMovies(String query) async {
    if (query.isEmpty) return [];
    try {
      final response = await Dio().get(
        'https://api.themoviedb.org/3/search/movie',
        queryParameters: {'api_key': _apiKey, 'query': query},
      );
      return response.data['results'];
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, String>> fetchMovieDetails(int movieId) async {
    try {
      final response = await Dio().get(
        'https://api.themoviedb.org/3/movie/$movieId',
        queryParameters: {'api_key': _apiKey, 'append_to_response': 'videos'},
      );
      final videos = response.data['videos']['results'] as List;
      final trailer = videos.firstWhere(
        (v) => v['type'] == 'Trailer' && v['site'] == 'YouTube',
        orElse: () => {'key': ''},
      );
      return {
        'trailer_key': trailer['key'] ?? '',
        'imdb_id': response.data['imdb_id'] ?? '',
        'vote_average': (response.data['vote_average'] as num).toDouble().toStringAsFixed(1),
      };
    } catch (e) {
      return {'trailer_key': '', 'imdb_id': '', 'vote_average': 'N/A'};
    }
  }
}
