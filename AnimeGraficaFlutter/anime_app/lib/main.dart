import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'src/data/datasources/anime_api_client.dart';
import 'src/presentation/bloc/anime_bloc.dart';
import 'src/presentation/screens/anime_list_screen.dart';

void main() => runApp(const AnimeApp());

class AnimeApp extends StatelessWidget {
  const AnimeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider(
      create: (_) => AnimeApiClient(),
      child: BlocProvider(
        create: (ctx) =>
            AnimeBloc(ctx.read<AnimeApiClient>())..add(const AnimesLoaded()),
        child: MaterialApp(
          title: 'Animes',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorSchemeSeed: Colors.deepPurple,
            useMaterial3: true,
          ),
          home: const AnimeListScreen(),
        ),
      ),
    );
  }
}
