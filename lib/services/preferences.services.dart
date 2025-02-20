import 'package:shared_preferences/shared_preferences.dart';

// Save data
void saveData(String key, String value) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  prefs.setString(key, value);
}

// Retrieve data
Future<String?> getData(String key) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getString(key);
}

Future<void> resetSharedPreferences() async {
  SharedPreferences preferences = await SharedPreferences.getInstance();
  await preferences.clear(); // Clear all key-value pairs
}
