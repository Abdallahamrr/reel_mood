import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:device_preview/device_preview.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("Dotenv Error: $e");
  }
  try {
    HydratedBloc.storage = await HydratedStorage.build(
      storageDirectory: kIsWeb
          ? HydratedStorage.webStorageDirectory
          : await getApplicationDocumentsDirectory(),
    );
  } catch (e) {
    debugPrint("Storage Error: $e");
  }

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
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: const Color(0xFF121212),
        ),
        // CHANGED: Home is now the Navigation Wrapper
        home: const MainNavigationWrapper(),
      ),
    );
  }
}

// --- MODELS ---
class MoodData {
  final String label, imageUrl;
  final int genreId;
  MoodData({
    required this.label,
    required this.imageUrl,
    required this.genreId,
  });
}

final List<MoodData> moodsList = [
  MoodData(
    label: 'Nostalgic',
    imageUrl:
        'https://i.ytimg.com/vi/EE1LYF_J0vE/hq720.jpg?sqp=-oaymwEhCK4FEIIDSFryq4qpAxMIARUAAAAAGAElAADIQj0AgKJD&rs=AOn4CLArdFwtjlZh9QCH1fFykSO_zRXTtw',
    genreId: 10751,
  ),
  MoodData(
    label: 'Sad',
    imageUrl:
        'https://static0.srcdn.com/wordpress/wp-content/uploads/2023/11/matthew-mcconaughey-crying-in-interstellar.jpg',
    genreId: 18,
  ),
  MoodData(
    label: 'Romance',
    imageUrl:
        'https://imgix.ranker.com/user_node_img/33/641410/original/641410-photo-u-1637993469',
    genreId: 10749,
  ),
  MoodData(
    label: 'Action',
    imageUrl:
        'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQFj82XraC_Jil95onsJTXzYZg2n-MM2mQVWg&s',
    genreId: 28,
  ),
  MoodData(
    label: 'Funny',
    imageUrl:
        'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTp-IhBn3FQ0r3euLUPgq_z0yXwn_hfpLPlnA&s',
    genreId: 35,
  ),
  MoodData(
    label: 'Scared',
    imageUrl:
        'https://www.thevintagenews.com/wp-content/uploads/sites/65/2019/02/img_9569-21-02-19-09-50-fx.jpg',
    genreId: 27,
  ),
];

// --- LOGIC ---
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

  void fetchMovies(String moodLabel) async {
    if (_apiKey.isEmpty) return;
    emit(MovieLoading());
    try {
      final mood = moodsList.firstWhere((m) => m.label == moodLabel);
      Map<String, dynamic> params = {
        'api_key': _apiKey,
        'with_genres': mood.genreId,
        'sort_by': 'popularity.desc',
      };
      if (moodLabel == 'Nostalgic') {
        params['release_date.lte'] = '2010-12-31';
        params['with_genres'] = '18,10751';
      }
      final response = await Dio().get(
        'https://api.themoviedb.org/3/discover/movie',
        queryParameters: params,
      );
      emit(MovieLoaded(response.data['results']));
    } catch (e) {
      debugPrint(e.toString());
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
        'vote_average': (response.data['vote_average'] as num)
            .toDouble()
            .toStringAsFixed(1),
      };
    } catch (e) {
      return {'trailer_key': '', 'imdb_id': '', 'vote_average': 'N/A'};
    }
  }
}

class WatchlistCubit extends HydratedCubit<List<Map<String, dynamic>>> {
  WatchlistCubit() : super([]);
  void addToWatchlist(Map<String, dynamic> movie, String mood) {
    if (!state.any((m) => m['id'] == movie['id']))
      emit([
        ...state,
        {...movie, 'saved_mood': mood},
      ]);
  }

  void removeFromWatchlist(int id) {
    emit(state.where((m) => m['id'] != id).toList());
  }

  @override
  Map<String, dynamic>? toJson(List<Map<String, dynamic>> state) => {
    'watchlist': state,
  };
  @override
  List<Map<String, dynamic>>? fromJson(Map<String, dynamic> json) =>
      List<Map<String, dynamic>>.from(json['watchlist']);
}

// --- GLOBAL HELPERS ---
void _launchURL(String url) async {
  final uri = Uri.parse(url);
  if (await canLaunchUrl(uri))
    await launchUrl(uri, mode: LaunchMode.externalApplication);
}

void _showDetailsSheet(
  BuildContext context,
  dynamic movie,
  Map<String, String> details,
) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.grey[900],
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
    ),
    builder: (_) => Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            movie['title'] ?? 'Unknown',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),
          ListTile(
            leading: const Icon(Icons.play_circle, color: Colors.red),
            title: const Text('Watch Trailer'),
            onTap: () => _launchURL(
              'https://www.youtube.com/watch?v=${details['trailer_key']}',
            ),
          ),
          ListTile(
            leading: const Icon(Icons.star, color: Colors.amber),
            title: Text('IMDb Rating: ${details['vote_average']}'),
            onTap: () =>
                _launchURL('https://www.imdb.com/title/${details['imdb_id']}'),
          ),
        ],
      ),
    ),
  );
}

Future<void> _handleLongPress(BuildContext context, dynamic movie) async {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(child: CircularProgressIndicator()),
  );
  final details = await context.read<MovieCubit>().fetchMovieDetails(
    movie['id'],
  );
  Navigator.pop(context); // Close loading
  _showDetailsSheet(context, movie, details);
}

// --- UPDATED SCREEN 1: MOOD SELECTION + SEARCH ---
class MoodSelectionScreen extends StatefulWidget {
  const MoodSelectionScreen({super.key});
  @override
  State<MoodSelectionScreen> createState() => _MoodSelectionScreenState();
}

class _MoodSelectionScreenState extends State<MoodSelectionScreen> {
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
      appBar: AppBar(title: const Text('ReelMood'), centerTitle: true),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              onChanged: _onSearch,
              decoration: InputDecoration(
                hintText: 'Search any movie...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _searchController.clear();
                          _onSearch('');
                          _searchFocusNode.unfocus();
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey[900],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
              ),
            ),
          ),
          Expanded(
            child: _searchResults.isNotEmpty
                ? ListView.builder(
                    itemCount: _searchResults.length,
                    itemBuilder: (context, i) {
                      final movie = _searchResults[i];
                      return ListTile(
                        onLongPress: () => _handleLongPress(context, movie),
                        leading: movie['poster_path'] != null
                            ? Image.network('https://image.tmdb.org/t/p/w92${movie['poster_path']}')
                            : const Icon(Icons.movie),
                        title: Text(movie['title'] ?? 'Unknown'),
                        trailing: IconButton(
                          icon: const Icon(Icons.add_circle_outline, color: Colors.greenAccent),
                          onPressed: () {
                            context.read<WatchlistCubit>().addToWatchlist(movie, 'Search');
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Added to Watchlist!')));
                          },
                        ),
                      );
                    },
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 1.1,
                      crossAxisSpacing: 15,
                      mainAxisSpacing: 15,
                    ),
                    itemCount: moodsList.length,
                    itemBuilder: (context, index) {
                      final mood = moodsList[index];
                      return GestureDetector(
                        onTap: () {
                          // Fetch movies then PUSH the discovery screen on top
                          context.read<MovieCubit>().fetchMovies(mood.label);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DiscoveryScreen(selectedMood: mood.label),
                            ),
                          );
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.network(mood.imageUrl, fit: BoxFit.cover),
                              Container(color: Colors.black45),
                              Center(child: Text(mood.label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// --- SCREEN 2: DISCOVERY ---
class DiscoveryScreen extends StatelessWidget {
  final String selectedMood;
  const DiscoveryScreen({super.key, required this.selectedMood});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Mood: $selectedMood'), elevation: 0),
      body: BlocBuilder<MovieCubit, MovieState>(
        builder: (context, state) {
          if (state is MovieLoading)
            return const Center(child: CircularProgressIndicator());
          if (state is MovieLoaded) {
            return CardSwiper(
              cardsCount: state.movies.length,
              onSwipe: (prev, curr, dir) {
                if (dir == CardSwiperDirection.right)
                  context.read<WatchlistCubit>().addToWatchlist(
                    state.movies[prev],
                    selectedMood,
                  );
                return true;
              },
              cardBuilder: (context, index, x, y) {
                final movie = state.movies[index];
                return GestureDetector(
                  onLongPress: () => _handleLongPress(context, movie),
                  child: Container(
                    margin: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25),
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
                        padding: const EdgeInsets.all(20),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.vertical(
                            bottom: Radius.circular(25),
                          ),
                        ),
                        child: Text(
                          movie['title'] ?? '',
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
          return const Center(child: Text('Pick a mood!'));
        },
      ),
    );
  }
}

// --- NAVIGATION WRAPPER ---
class MainNavigationWrapper extends StatefulWidget {
  const MainNavigationWrapper({super.key});
  @override
  State<MainNavigationWrapper> createState() => _MainNavigationWrapperState();
}

class _MainNavigationWrapperState extends State<MainNavigationWrapper> {
  int _selectedIndex = 0;
  
  // List of root screens
  final List<Widget> _screens = [
    const MoodSelectionScreen(),
    const WatchlistScreen(),
    const StatsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack( // Keeps scroll positions alive when switching tabs
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: Colors.greenAccent,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Explore'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Watchlist'),
          BottomNavigationBarItem(icon: Icon(Icons.insights), label: 'Stats'),
        ],
      ),
    );
  }
}

// --- WATCHLIST & STATS ---
class WatchlistScreen extends StatelessWidget {
  const WatchlistScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Watchlist')),
      body: BlocBuilder<WatchlistCubit, List<Map<String, dynamic>>>(
        builder: (context, list) {
          if (list.isEmpty) return const Center(child: Text("Empty list"));
          return ListView.builder(
            itemCount: list.length,
            itemBuilder: (context, i) => ListTile(
              onLongPress: () => _handleLongPress(context, list[i]),
              leading: list[i]['poster_path'] != null
                  ? Image.network(
                      'https://image.tmdb.org/t/p/w92${list[i]['poster_path']}',
                    )
                  : const Icon(Icons.movie),
              title: Text(list[i]['title'] ?? 'Unknown'),
              subtitle: Text('Context: ${list[i]['saved_mood']}'),
              trailing: IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () => context
                    .read<WatchlistCubit>()
                    .removeFromWatchlist(list[i]['id']),
              ),
            ),
          );
        },
      ),
    );
  }
}

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final count = context.watch<WatchlistCubit>().state.length;
    return Scaffold(
      appBar: AppBar(title: const Text('Stats')),
      body: Center(
        child: Text(
          "You liked $count movies!",
          style: const TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
