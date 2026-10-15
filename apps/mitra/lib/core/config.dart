/// Semua konfigurasi dikirim lewat --dart-define saat build (lihat README).
/// Jika SUPABASE_URL kosong, aplikasi jalan di MODE DEMO (data dummy, tanpa server).
class Config {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const fcmApiKey = String.fromEnvironment('FCM_API_KEY');
  static const fcmAppId = String.fromEnvironment('FCM_APP_ID');
  static const fcmSenderId = String.fromEnvironment('FCM_SENDER_ID');
  static const fcmProjectId = String.fromEnvironment('FCM_PROJECT_ID');

  static bool get demo => supabaseUrl.isEmpty || supabaseAnonKey.isEmpty;
  static bool get fcmEnabled =>
      fcmApiKey.isNotEmpty && fcmAppId.isNotEmpty && fcmProjectId.isNotEmpty;
}
