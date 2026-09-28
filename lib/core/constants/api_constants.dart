class LanguageOption {
  final String code;
  final String name;
  final String nativeName;
  final String flag;
  final String? searchTag;

  const LanguageOption({
    required this.code,
    required this.name,
    required this.nativeName,
    required this.flag,
    this.searchTag,
  });
}

enum MusicSource {
  all,
  spotify,
  epidemicsound,
  soundcloud,
  jamendo,
}

extension MusicSourceExt on MusicSource {
  String get displayName {
    switch (this) {
      case MusicSource.all:
        return 'All Platforms';
      case MusicSource.spotify:
        return 'Spotify';
      case MusicSource.epidemicsound:
        return 'Epidemic Sound';
      case MusicSource.soundcloud:
        return 'SoundCloud';
      case MusicSource.jamendo:
        return 'Jamendo';
    }
  }

  String get shortName {
    switch (this) {
      case MusicSource.all:
        return 'ALL';
      case MusicSource.spotify:
        return 'SPOTIFY';
      case MusicSource.epidemicsound:
        return 'EPIDEMIC';
      case MusicSource.soundcloud:
        return 'SOUNDCLOUD';
      case MusicSource.jamendo:
        return 'JAMENDO';
    }
  }
}

class ApiConstants {
  // Epidemic Sound Partner API Config (Royalty Free)
  static const String epidemicBaseUrl = 'https://partner-content-api.epidemicsound.com';
  static const String epidemicApiKey = 'epidemic_live_0DTLwK7nOslEUykAOnLsWH4PM667uFhQZ';
  static const String epidemicPartnerUserId = 'msajad_harmoniq_user';

  // Jamendo API Config
  static const String baseUrl = 'https://api.jamendo.com/v3.0';
  static const String clientId = '1bcd4aa4'; // Jamendo Registered Client ID
  static const String format = 'jsonpretty';

  // Spotify Web API Config
  static const String spotifyBaseUrl = 'https://api.spotify.com/v1';
  static const String spotifyDefaultToken =
      'BQDp5OfEZmuOj5Sk9l4sywClFNnClDqpIPqFy4fIZcwJ5S_3HcdZEjTnDm0yIa5csTiYuCmpgc-xqpL0Qgg2CQSxjifoIkRaznnht_nYUtG7r9M9dH9YPrbIP0h0rjHTPyYw3r8UABXNsOTDxxqHs1Vc2e6zEHr_F0JbR2HRmFERbP1HvvdoWz5U3WZFFso6LL8GGtSL_IL5sbHdlUjDtHXiMpHugzevLuIw5pr2-QXXReZFXPDViyy_1aPN3a2xuRSrhOrL3F3Axy1SiFvigVSW_gjNG-lumf9ni0z5GkHZKRXLLOWQoum0r5v_vhR1nkb0_Qo';

  // SoundCloud API Config (Official Public API & v2 Endpoint)
  static const String soundCloudBaseUrl = 'https://api.soundcloud.com';
  static const String soundCloudV2BaseUrl = 'https://api-v2.soundcloud.com';
  static const String soundCloudClientId = 'a3e059563d7fd3372b49b37f00a00bcf'; // Public Client Token
  static const List<String> soundCloudFallbackClientIds = [
    'a3e059563d7fd3372b49b37f00a00bcf',
    '2t9loNfhTwczEJgwmvdge6aOXtonMHqx',
    'iZIs9mchVcX5lhVR1EzGCcyEVASSrihp',
    'FweeExecution65412987SndCldToken',
  ];

  // Endpoints
  static const String tracksEndpoint = '$baseUrl/tracks';
  static const String albumsEndpoint = '$baseUrl/albums';
  static const String artistsEndpoint = '$baseUrl/artists';
  static const String autocompleteEndpoint = '$baseUrl/autocomplete';

  // Popular Genres & Mood Tags
  static const List<String> genres = [
    'All',
    'Pop',
    'Electronic',
    'Lo-Fi',
    'Hip-Hop',
    'Rock',
    'Chillout',
    'Jazz',
    'Ambient',
    'Dance',
    'Classical',
    'Acoustic',
    'Bollywood',
    'Sufi',
    'Devotional',
    'R&B',
    'Indie',
    'Soul',
    'Metal',
    'Reggae',
    'Blues',
    'Country',
  ];

  // Comprehensive Searchable Languages (Including All Indian Regional Languages)
  static const List<LanguageOption> languages = [
    // Global
    LanguageOption(code: '', name: 'All Languages', nativeName: 'Worldwide Tracks', flag: '🌐'),

    // Indian Languages
    LanguageOption(code: 'hi', name: 'Hindi', nativeName: 'हिन्दी', flag: '🇮🇳', searchTag: 'hindi'),
    LanguageOption(code: 'pa', name: 'Punjabi', nativeName: 'ਪੰਜਾਬੀ', flag: '🇮🇳', searchTag: 'punjabi'),
    LanguageOption(code: 'ta', name: 'Tamil', nativeName: 'தமிழ்', flag: '🇮🇳', searchTag: 'tamil'),
    LanguageOption(code: 'te', name: 'Telugu', nativeName: 'తెలుగు', flag: '🇮🇳', searchTag: 'telugu'),
    LanguageOption(code: 'bn', name: 'Bengali', nativeName: 'বাংলা', flag: '🇮🇳', searchTag: 'bengali'),
    LanguageOption(code: 'ml', name: 'Malayalam', nativeName: 'മലയാളം', flag: '🇮🇳', searchTag: 'malayalam'),
    LanguageOption(code: 'kn', name: 'Kannada', nativeName: 'ಕನ್ನಡ', flag: '🇮🇳', searchTag: 'kannada'),
    LanguageOption(code: 'mr', name: 'Marathi', nativeName: 'मराठी', flag: '🇮🇳', searchTag: 'marathi'),
    LanguageOption(code: 'gu', name: 'Gujarati', nativeName: 'ગુજરાતી', flag: '🇮🇳', searchTag: 'gujarati'),
    LanguageOption(code: 'ur', name: 'Urdu', nativeName: 'اردو', flag: '🇮🇳', searchTag: 'urdu'),
    LanguageOption(code: 'bho', name: 'Bhojpuri', nativeName: 'भोजपुरी', flag: '🇮🇳', searchTag: 'bhojpuri'),
    LanguageOption(code: 'bgc', name: 'Haryanvi', nativeName: 'हरियाणवी', flag: '🇮🇳', searchTag: 'haryanvi'),
    LanguageOption(code: 'raj', name: 'Rajasthani', nativeName: 'राजस्थानी', flag: '🇮🇳', searchTag: 'rajasthani'),
    LanguageOption(code: 'or', name: 'Odia', nativeName: 'ଓଡ଼ିଆ', flag: '🇮🇳', searchTag: 'odia'),
    LanguageOption(code: 'as', name: 'Assamese', nativeName: 'অসমীয়া', flag: '🇮🇳', searchTag: 'assamese'),
    LanguageOption(code: 'sa', name: 'Sanskrit', nativeName: 'संस्कृतम्', flag: '🇮🇳', searchTag: 'sanskrit'),
    LanguageOption(code: 'ks', name: 'Kashmiri', nativeName: 'कॉशुर', flag: '🇮🇳', searchTag: 'kashmiri'),
    LanguageOption(code: 'sd', name: 'Sindhi', nativeName: 'سنڌي', flag: '🇮🇳', searchTag: 'sindhi'),
    LanguageOption(code: 'kok', name: 'Konkani', nativeName: 'कोंकणी', flag: '🇮🇳', searchTag: 'konkani'),

    // International Languages
    LanguageOption(code: 'en', name: 'English', nativeName: 'English', flag: '🇬🇧'),
    LanguageOption(code: 'es', name: 'Spanish', nativeName: 'Español', flag: '🇪🇸'),
    LanguageOption(code: 'fr', name: 'French', nativeName: 'Français', flag: '🇫🇷'),
    LanguageOption(code: 'de', name: 'German', nativeName: 'Deutsch', flag: '🇩🇪'),
    LanguageOption(code: 'it', name: 'Italian', nativeName: 'Italiano', flag: '🇮🇹'),
    LanguageOption(code: 'pt', name: 'Portuguese', nativeName: 'Português', flag: '🇵🇹'),
    LanguageOption(code: 'ru', name: 'Russian', nativeName: 'Русский', flag: '🇷🇺'),
    LanguageOption(code: 'ja', name: 'Japanese', nativeName: '日本語', flag: '🇯🇵'),
    LanguageOption(code: 'ko', name: 'Korean', nativeName: '한국어', flag: '🇰🇷'),
    LanguageOption(code: 'zh', name: 'Chinese', nativeName: '中文', flag: '🇨🇳'),
    LanguageOption(code: 'ar', name: 'Arabic', nativeName: 'العربية', flag: '🇸🇦'),
    LanguageOption(code: 'tr', name: 'Turkish', nativeName: 'Türkçe', flag: '🇹🇷'),
    LanguageOption(code: 'nl', name: 'Dutch', nativeName: 'Nederlands', flag: '🇳🇱'),
    LanguageOption(code: 'sv', name: 'Swedish', nativeName: 'Svenska', flag: '🇸🇪'),
    LanguageOption(code: 'pl', name: 'Polish', nativeName: 'Polski', flag: '🇵🇱'),
    LanguageOption(code: 'instrumental', name: 'Instrumental', nativeName: 'No Vocals', flag: '🎹'),
  ];
}
