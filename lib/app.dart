import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'cubits/movie_cubit.dart';
import 'cubits/watchlist_cubit.dart';
import 'navigation/main_navigation_wrapper.dart';

class MovieScoutApp extends StatelessWidget {
  const MovieScoutApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => MovieCubit()),
        BlocProvider(create: (_) => WatchlistCubit()),
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
