import 'package:flutter/material.dart';
import '../models/genre.dart';

class GenreTile extends StatelessWidget {
  final GenreData genre;
  final VoidCallback onTap;

  const GenreTile({super.key, required this.genre, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: const Color.fromARGB(120, 106, 1, 1),
              blurRadius: 6,
              spreadRadius: 2,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(genre.imageUrl, fit: BoxFit.cover),
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
                  genre.label,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
