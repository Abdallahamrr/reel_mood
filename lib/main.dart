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
          scaffoldBackgroundColor: const Color.fromARGB(255, 0, 0, 0),
        ),
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
    label: 'Drama',
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
    label: 'Sci-Fi',
    imageUrl:
        'https://variety.com/wp-content/uploads/2014/10/screen-shot-2014-10-22-at-11-36-12-am.png',
    genreId: 878,
  ),
  MoodData(
    label: 'Adventure',
    imageUrl: 'https://pbs.twimg.com/media/EVwIabZVcAAuXD_.jpg',
    genreId: 12,
  ),
  MoodData(
    label: 'Comedy',
    imageUrl:
        'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTp-IhBn3FQ0r3euLUPgq_z0yXwn_hfpLPlnA&s',
    genreId: 35,
  ),
  MoodData(
    label: 'Horror',
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

  void clearWatchlist() => emit([]);

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
    backgroundColor: const Color.fromARGB(255, 0, 0, 0),
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
            leading: const Icon(
              Icons.play_circle,
              color: Color.fromARGB(255, 212, 0, 0),
            ),
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

// --- MOOD SELECTION + SEARCH ---
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
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'ReelScope',
          style: TextStyle(fontWeight: FontWeight.w600, letterSpacing: 1.2),
        ),
        centerTitle: true,
        backgroundColor: Colors.black,
        elevation: 6,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsetsGeometry.only(top: 20.0),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFE50914).withOpacity(0.25),
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
                    prefixIcon: const Icon(
                      Icons.search,
                      color: Color(0xFFE50914),
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: Color(0xFF8E8E93),
                            ),
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
                            ? Image.network(
                                'https://image.tmdb.org/t/p/w92${movie['poster_path']}',
                              )
                            : const Icon(Icons.movie),
                        title: Text(movie['title'] ?? 'Unknown'),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.add_circle_outline,
                            color: Colors.greenAccent,
                          ),
                          onPressed: () {
                            context.read<WatchlistCubit>().addToWatchlist(
                              movie,
                              'Search',
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Added to Watchlist!'),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
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
                          context.read<MovieCubit>().fetchMovies(mood.label);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  DiscoveryScreen(selectedMood: mood.label),
                            ),
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [
                              BoxShadow(
                                color: const Color.fromARGB(255, 125, 7, 13),
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.network(mood.imageUrl, fit: BoxFit.cover),
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                      colors: [
                                        Colors.black.withOpacity(0.65),
                                        Colors.black.withOpacity(0.25),
                                      ],
                                    ),
                                  ),
                                ),
                                Center(
                                  child: Text(
                                    mood.label,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.6,
                                    ),
                                  ),
                                ),
                              ],
                            ),
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

// --- DISCOVERY SCREEN ---
class DiscoveryScreen extends StatelessWidget {
  final String selectedMood;
  const DiscoveryScreen({super.key, required this.selectedMood});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mood: $selectedMood'),
        elevation: 0,
        backgroundColor: Colors.black,
      ),
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

  final List<Widget> _screens = [
    const MoodSelectionScreen(),
    const WatchlistScreen(),
    const StatsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 1),
          child: Container(
            height: 70,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.25),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                IconButton(
                  icon: const Icon(Icons.explore, size: 32),
                  color: _selectedIndex == 0
                      ? const Color.fromARGB(255, 180, 25, 12)
                      : Colors.grey,
                  onPressed: () => setState(() => _selectedIndex = 0),
                ),
                IconButton(
                  icon: const Icon(Icons.playlist_add, size: 32),
                  color: _selectedIndex == 1
                      ? const Color.fromARGB(255, 180, 20, 9)
                      : Colors.grey,
                  onPressed: () => setState(() => _selectedIndex = 1),
                ),
                IconButton(
                  icon: const Icon(Icons.bar_chart, size: 32),
                  color: _selectedIndex == 2
                      ? const Color.fromARGB(255, 180, 25, 12)
                      : Colors.grey,
                  onPressed: () => setState(() => _selectedIndex = 2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- WATCHLIST SCREEN ---
class WatchlistScreen extends StatefulWidget {
  const WatchlistScreen({super.key});

  @override
  State<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends State<WatchlistScreen> {
  final Set<int> _expandedMovies = {};

  void _toggleExpanded(int movieId) {
    setState(() {
      if (_expandedMovies.contains(movieId)) {
        _expandedMovies.remove(movieId);
      } else {
        _expandedMovies.add(movieId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('My Watchlist'),
        centerTitle: true,
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: BlocBuilder<WatchlistCubit, List<Map<String, dynamic>>>(
        builder: (context, list) {
          if (list.isEmpty)
            return const Center(
              child: Text(
                'No movies saved yet',
                style: TextStyle(color: Color(0xFF8E8E93), fontSize: 18),
              ),
            );
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: list.length,
            itemBuilder: (context, i) {
              final movie = list[i];
              final isExpanded = _expandedMovies.contains(movie['id']);
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
                    Row(
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
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFFE50914,
                                  ).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  movie['saved_mood'],
                                  style: const TextStyle(
                                    color: Color(0xFFE50914),
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          color: const Color(0xFFE50914),
                          onPressed: () {
                            context.read<WatchlistCubit>().removeFromWatchlist(
                              movie['id'],
                            );
                          },
                        ),
                        IconButton(
                          icon: Icon(
                            isExpanded ? Icons.info : Icons.info_outline,
                            color: Colors.white,
                          ),
                          onPressed: () => _toggleExpanded(movie['id']),
                        ),
                      ],
                    ),
                    if (isExpanded)
                      FutureBuilder<Map<String, String>>(
                        future: context.read<MovieCubit>().fetchMovieDetails(
                          movie['id'],
                        ),
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
                                  onTap: () => _launchURL(
                                    'https://www.youtube.com/watch?v=${details['trailer_key']}',
                                  ),
                                  child: Row(
                                    children: const [
                                      Icon(
                                        Icons.play_circle,
                                        color: Color(0xFFD40000),
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Watch Trailer',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w500,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 6),
                                GestureDetector(
                                  onTap: () => _launchURL(
                                    'https://www.imdb.com/title/${details['imdb_id']}',
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.star,
                                        color: Colors.amber,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'IMDb Rating: ${details['vote_average']}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w500,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: BlocBuilder<WatchlistCubit, List<Map<String, dynamic>>>(
        builder: (context, list) {
          if (list.isEmpty) return const SizedBox.shrink();
          return Opacity(
            opacity: 0.85,
            child: FloatingActionButton.extended(
              backgroundColor: const Color.fromARGB(255, 159, 7, 14),
              icon: const Icon(Icons.delete_forever),
              label: const Text('Remove All'),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    backgroundColor: Colors.black,
                    title: const Text(
                      'Clear Watchlist?',
                      style: TextStyle(color: Colors.white),
                    ),
                    content: const Text(
                      'Are you sure you want to remove all movies from your watchlist?',
                      style: TextStyle(color: Colors.white70),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          context.read<WatchlistCubit>().clearWatchlist();
                          Navigator.pop(context);
                        },
                        child: const Text(
                          'Remove All',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

// --- STATS SCREEN ---
class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Stats'),
        centerTitle: true,
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: const Center(
        child: Text(
          'Stats Coming Soon!',
          style: TextStyle(color: Colors.white70),
        ),
      ),
    );
  }
}
