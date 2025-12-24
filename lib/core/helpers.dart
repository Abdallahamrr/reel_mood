import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubits/movie_cubit.dart';

Future<void> launchURL(String url) async {
  final uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

void showDetailsSheet(
  BuildContext context,
  dynamic movie,
  Map<String, String> details,
) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.black,
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
            leading: const Icon(Icons.play_circle, color: Color.fromARGB(255, 212, 0, 0)),
            title: const Text('Watch Trailer'),
            onTap: () => launchURL(
              'https://www.youtube.com/watch?v=${details['trailer_key']}',
            ),
          ),
          ListTile(
            leading: const Icon(Icons.star, color: Colors.amber),
            title: Text('IMDb Rating: ${details['vote_average']}'),
            onTap: () => launchURL('https://www.imdb.com/title/${details['imdb_id']}'),
          ),
        ],
      ),
    ),
  );
}

Future<void> handleLongPress(BuildContext context, dynamic movie) async {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(child: CircularProgressIndicator()),
  );
  final details = await context.read<MovieCubit>().fetchMovieDetails(movie['id']);
  Navigator.pop(context);
  showDetailsSheet(context, movie, details);
}
