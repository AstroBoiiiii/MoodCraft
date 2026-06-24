import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/firebase/bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Guarded: no-ops in dev stub mode until `flutterfire configure` is run.
  await bootstrapFirebase();
  runApp(const ProviderScope(child: MoodCraftApp()));
}
