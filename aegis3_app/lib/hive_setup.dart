import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

/// Global reference to keep boxes open
final Map<String, Box> _openBoxes = {};

Future<void> setupHive() async {
  final dir = await getApplicationDocumentsDirectory();
  Hive.init(dir.path);

  // Pre-open commonly used boxes
  await openProfileBox();

  // Register adapters here if you use them
  // Hive.registerAdapter(UserProfileAdapter());
}

/// Open and cache the profile box
Future<Box> openProfileBox() async {
  if (_openBoxes.containsKey('userProfileBox')) {
    return _openBoxes['userProfileBox']!;
  }

  final box = await Hive.openBox('userProfileBox');
  _openBoxes['userProfileBox'] = box;
  return box;
}

/// Close all boxes (call this on app dispose if needed)
Future<void> closeAllBoxes() async {
  for (var box in _openBoxes.values) {
    await box.close();
  }
  _openBoxes.clear();
}
