import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'presentation/recordings/recordings_screen.dart';
import 'presentation/recordings/recordings_view_model.dart';

class SnorerApp extends StatelessWidget {
  const SnorerApp({super.key, required this.viewModel});

  final RecordingsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Snorer',
      debugShowCheckedModeBanner: false,
      theme: buildSnorerTheme(),
      home: RecordingsScreen(viewModel: viewModel),
    );
  }
}
