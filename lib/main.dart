import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:device_preview/device_preview.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(
    DevicePreview(
      enabled: !kReleaseMode,
      builder: (context) => const ReelMoodApp(),
    ),
  );
}

class ReelMoodApp extends StatelessWidget {
  const ReelMoodApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => MovieCubit()),
        BlocProvider(create: (context) => WatchlistCubit()),
      ],
      child: MaterialApp(
        useInheritedMediaQuery: true,
        locale: DevicePreview.locale(context),
        builder: DevicePreview.appBuilder,
        theme: ThemeData.dark(),
        home: const MoodSelectionScreen(),
      ),
    );
  }
}

// --- LOGIC (CUBIT) ---
class MovieState {}

class MovieInitial extends MovieState {}

class MovieLoading extends MovieState {}

class MovieLoaded extends MovieState {
  final List movies;
  MovieLoaded(this.movies);
}

class MovieCubit extends Cubit<MovieState> {
  MovieCubit() : super(MovieInitial());

  final String _apiKey = 'c68571d4bc72280a2a9b44494724cf6c';

  void fetchMovies(String mood) async {
    emit(MovieLoading());
    try {
      final moodMap = {
        '😊 Happy': 35,
        '😢 Sad': 18,
        '🔥 Energetic': 28,
        '😱 Scared': 27,
      };
      final genreId = moodMap[mood];

      final response = await Dio().get(
        'https://api.themoviedb.org/3/discover/movie',
        queryParameters: {
          'api_key': _apiKey,
          'with_genres': genreId,
          'sort_by': 'popularity.desc',
        },
      );
      emit(MovieLoaded(response.data['results']));
    } catch (e) {
      print(e);
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
        'vote_average': response.data['vote_average'].toStringAsFixed(1),
      };
    } catch (e) {
      return {'trailer_key': '', 'imdb_id': '', 'vote_average': 'N/A'};
    }
  }
}

// --- SCREEN 1: MOOD SELECTION ---
class MoodSelectionScreen extends StatelessWidget {
  const MoodSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final moods = ['😊 Happy', '😢 Sad', '🔥 Energetic', '😱 Scared'];

    return Scaffold(
      appBar: AppBar(title: const Text('How is your Mood?')),
      body: GridView.builder(
        padding: const EdgeInsets.all(20),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: moods.length,
        itemBuilder: (context, index) {
          return ElevatedButton(
            onPressed: () {
              final chosenMood = moods[index];
              context.read<MovieCubit>().fetchMovies(chosenMood);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      MainNavigationWrapper(initialMood: chosenMood),
                ),
              );
            },
            child: Text(moods[index], style: const TextStyle(fontSize: 20)),
          );
        },
      ),
    );
  }
}

// --- SCREEN 2: MOVIE DISCOVERY ---
class DiscoveryScreen extends StatelessWidget {
  final String selectedMood;
  const DiscoveryScreen({super.key, required this.selectedMood});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Mood: $selectedMood')),
      body: BlocBuilder<MovieCubit, MovieState>(
        builder: (context, state) {
          if (state is MovieLoading)
            return const Center(child: CircularProgressIndicator());
          if (state is MovieLoaded) {
            return CardSwiper(
              cardsCount: state.movies.length,
              onSwipe: (previousIndex, currentIndex, direction) {
                if (direction == CardSwiperDirection.right) {
                  final movie = state.movies[previousIndex];
                  context.read<WatchlistCubit>().addToWatchlist(
                    movie,
                    selectedMood,
                  );
                }
                return true;
              },
              cardBuilder: (context, index, horizontalThreshold, verticalThreshold) {
                final movie = state.movies[index];
                return GestureDetector(
                  onLongPress: () async {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) =>
                          const Center(child: CircularProgressIndicator()),
                    );
                    final details = await context
                        .read<MovieCubit>()
                        .fetchMovieDetails(movie['id']);
                    Navigator.pop(context);

                    showModalBottomSheet(
                      context: context,
                      backgroundColor: Colors.grey[900],
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(25),
                        ),
                      ),
                      builder: (context) => Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              movie['title'],
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 15),
                            ListTile(
                              leading: const Icon(
                                Icons.play_circle,
                                color: Colors.red,
                              ),
                              title: const Text('Watch Trailer'),
                              onTap: () {
                                Navigator.pop(context);
                                _openTrailer(context, details['trailer_key']!);
                              },
                            ),
                            ListTile(
                              leading: const Icon(
                                Icons.star,
                                color: Colors.amber,
                              ),
                              title: Text(
                                'IMDb Rating: ${details['vote_average']}',
                              ),
                              onTap: () => _launchURL(
                                'https://www.imdb.com/title/${details['imdb_id']}',
                              ),
                            ),
                            ListTile(
                              leading: const Icon(
                                Icons.link,
                                color: Colors.blue,
                              ),
                              title: const Text('View on Rotten Tomatoes'),
                              onTap: () => _launchURL(
                                'https://www.rottentomatoes.com/search?search=${movie['title']}',
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      image: DecorationImage(
                        image: NetworkImage(
                          'https://image.tmdb.org/t/p/w500${movie['poster_path']}',
                        ),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        width: double.infinity,
                        color: Colors.black54,
                        padding: const EdgeInsets.all(10),
                        child: Text(
                          movie['title'],
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          }
          return const Center(child: Text('Select a mood first!'));
        },
      ),
    );
  }
}

// --- SCREEN 3: WATCHLIST ---
class WatchlistScreen extends StatelessWidget {
  const WatchlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Watchlist')),
      body: BlocBuilder<WatchlistCubit, List<Map<String, dynamic>>>(
        builder: (context, watchlist) {
          if (watchlist.isEmpty)
            return const Center(child: Text("No movies saved yet!"));
          return ListView.builder(
            itemCount: watchlist.length,
            itemBuilder: (context, index) {
              final movie = watchlist[index];
              return ListTile(
                leading: Image.network(
                  'https://image.tmdb.org/t/p/w92${movie['poster_path']}',
                ),
                title: Text(movie['title']),
                subtitle: Text('Saved during: ${movie['saved_mood']}'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => context
                      .read<WatchlistCubit>()
                      .removeFromWatchlist(movie['id']),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// --- SCREEN 4: STATISTICS ---
class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final watchlist = context.watch<WatchlistCubit>().state;

    String topMood = "None yet";
    if (watchlist.isNotEmpty) {
      var moodCounts = <String, int>{};
      for (var movie in watchlist) {
        String m = movie['saved_mood'] ?? "Unknown";
        moodCounts[m] = (moodCounts[m] ?? 0) + 1;
      }
      topMood = moodCounts.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Mood Stats')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.analytics, size: 100, color: Colors.blueAccent),
            const SizedBox(height: 20),
            Text(
              "Total Movies Liked: ${watchlist.length}",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              "Your Go-to Mood: $topMood",
              style: const TextStyle(fontSize: 18, color: Colors.greenAccent),
            ),
          ],
        ),
      ),
    );
  }
}

// --- NAVIGATION WRAPPER ---
class MainNavigationWrapper extends StatefulWidget {
  final String initialMood;
  const MainNavigationWrapper({super.key, required this.initialMood});

  @override
  State<MainNavigationWrapper> createState() => _MainNavigationWrapperState();
}

class _MainNavigationWrapperState extends State<MainNavigationWrapper> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> _screens = [
      DiscoveryScreen(selectedMood: widget.initialMood),
      const WatchlistScreen(),
      const StatsScreen(),
    ];

    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.style), label: 'Discover'),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Watchlist',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.analytics), label: 'Stats'),
        ],
      ),
    );
  }
}

// --- WATCHLIST LOGIC ---
class WatchlistCubit extends Cubit<List<Map<String, dynamic>>> {
  WatchlistCubit() : super([]);

  void addToWatchlist(Map<String, dynamic> movie, String mood) {
    if (!state.any((m) => m['id'] == movie['id'])) {
      final movieWithMood = {...movie, 'saved_mood': mood};
      emit([...state, movieWithMood]);
    }
  }

  void removeFromWatchlist(int id) {
    emit(state.where((m) => m['id'] != id).toList());
  }
}

// --- HELPERS ---
void _openTrailer(BuildContext context, String videoKey) async {
  if (videoKey.isEmpty) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("No trailer found")));
    return;
  }
  _launchURL('https://www.youtube.com/watch?v=$videoKey');
}

void _launchURL(String url) async {
  final uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
