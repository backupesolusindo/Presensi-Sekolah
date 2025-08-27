// import 'package:shared_preferences/shared_preferences.dart';
// import 'pusher_service.dart';
// import 'background_pusher_service.dart';

// class LogoutService {
//   static Future<void> performLogout() async {
//     try {
//       print("Starting logout process...");
      
//       // 1. Disconnect foreground Pusher
//       try {
//         await PusherService().disconnect();
//         print("Foreground Pusher disconnected");
//       } catch (e) {
//         print("Error disconnecting foreground Pusher: $e");
//       }
      
//       // 2. Stop background service
//       try {
//         await BackgroundPusherService.stopService();
//         print("Background service stopped");
//       } catch (e) {
//         print("Error stopping background service: $e");
//       }
      
//       // 3. Clear SharedPreferences
//       SharedPreferences prefs = await SharedPreferences.getInstance();
//       await prefs.remove('nama_wali');
//       await prefs.remove('no_hp');
//       await prefs.remove('password');
//       await prefs.setBool('is_logged_in', false);
//       await prefs.remove('background_user_phone');
      
//       print("Logout completed successfully");
      
//     } catch (e) {
//       print("Error during logout: $e");
//     }
//   }
// }