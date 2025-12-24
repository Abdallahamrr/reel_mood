import 'package:hydrated_bloc/hydrated_bloc.dart';

class WatchlistCubit extends HydratedCubit<List<Map<String, dynamic>>> {
  WatchlistCubit() : super([]);

  void addToWatchlist(Map<String, dynamic> movie, String genre) {
    if (!state.any((m) => m['id'] == movie['id'])) {
      emit([...state, {...movie, 'saved_Genre': genre}]);
    }
  }

  void removeFromWatchlist(int id) {
    emit(state.where((m) => m['id'] != id).toList());
  }

  void clearWatchlist() => emit([]);

  @override
  Map<String, dynamic>? toJson(List<Map<String, dynamic>> state) => {'watchlist': state};

  @override
  List<Map<String, dynamic>>? fromJson(Map<String, dynamic> json) => List<Map<String, dynamic>>.from(json['watchlist']);
}
