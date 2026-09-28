class TrackModel {
  final String id;
  final String name;
  final int duration;
  final String artistId;
  final String artistName;
  final String albumName;
  final String albumId;
  final String albumImage;
  final String audioUrl;
  final String? audioDownloadUrl;
  final String? releaseDate;
  final String? shareUrl;
  final String? licenseUrl;
  final List<String> tags;
  final String? localFilePath;
  final String source; // 'jamendo' or 'soundcloud'

  TrackModel({
    required this.id,
    required this.name,
    required this.duration,
    required this.artistId,
    required this.artistName,
    required this.albumName,
    required this.albumId,
    required this.albumImage,
    required this.audioUrl,
    this.audioDownloadUrl,
    this.releaseDate,
    this.shareUrl,
    this.licenseUrl,
    this.tags = const [],
    this.localFilePath,
    this.source = 'jamendo',
  });

  bool get isLocal => localFilePath != null && localFilePath!.isNotEmpty;
  bool get isSaavn => source == 'saavn';
  bool get isSpotify => source == 'spotify';
  bool get isEpidemic => source == 'epidemicsound';
  bool get isSoundCloud => source == 'soundcloud';
  bool get isJamendo => source == 'jamendo';

  factory TrackModel.fromJson(Map<String, dynamic> json) {
    List<String> parsedTags = [];
    if (json['musicinfo'] != null && json['musicinfo']['tags'] != null) {
      final tagsData = json['musicinfo']['tags'];
      if (tagsData is Map) {
        if (tagsData['genres'] is List) {
          parsedTags.addAll(List<String>.from(tagsData['genres']));
        }
      }
    } else if (json['tags'] is List) {
      parsedTags.addAll(List<String>.from(json['tags']));
    }

    String imageUrl = json['image'] ??
        json['album_image'] ??
        'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=500&auto=format&fit=crop';

    if (imageUrl.contains('usercontent.jamendo.com') && !imageUrl.contains('&width=')) {
      imageUrl = '$imageUrl&width=400';
    }

    return TrackModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? 'Unknown Track',
      duration: (json['duration'] is int)
          ? json['duration']
          : (int.tryParse(json['duration']?.toString() ?? '0') ?? 0),
      artistId: json['artist_id']?.toString() ?? '',
      artistName: json['artist_name'] ?? 'Unknown Artist',
      albumName: json['album_name'] ?? 'Single',
      albumId: json['album_id']?.toString() ?? '',
      albumImage: imageUrl,
      audioUrl: json['audio'] ?? '',
      audioDownloadUrl: json['audiodownload'],
      releaseDate: json['releasedate'],
      shareUrl: json['shareurl'] ?? json['shorturl'],
      licenseUrl: json['license_ccurl'],
      tags: parsedTags,
      localFilePath: json['local_file_path'],
      source: json['source'] ?? 'jamendo',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'duration': duration,
      'artist_id': artistId,
      'artist_name': artistName,
      'album_name': albumName,
      'album_id': albumId,
      'album_image': albumImage,
      'audio': audioUrl,
      'audiodownload': audioDownloadUrl,
      'releasedate': releaseDate,
      'shareurl': shareUrl,
      'license_ccurl': licenseUrl,
      'tags': tags,
      'local_file_path': localFilePath,
      'source': source,
    };
  }

  TrackModel copyWith({
    String? id,
    String? name,
    int? duration,
    String? artistId,
    String? artistName,
    String? albumName,
    String? albumId,
    String? albumImage,
    String? audioUrl,
    String? audioDownloadUrl,
    String? releaseDate,
    String? shareUrl,
    String? licenseUrl,
    List<String>? tags,
    String? localFilePath,
    String? source,
  }) {
    return TrackModel(
      id: id ?? this.id,
      name: name ?? this.name,
      duration: duration ?? this.duration,
      artistId: artistId ?? this.artistId,
      artistName: artistName ?? this.artistName,
      albumName: albumName ?? this.albumName,
      albumId: albumId ?? this.albumId,
      albumImage: albumImage ?? this.albumImage,
      audioUrl: audioUrl ?? this.audioUrl,
      audioDownloadUrl: audioDownloadUrl ?? this.audioDownloadUrl,
      releaseDate: releaseDate ?? this.releaseDate,
      shareUrl: shareUrl ?? this.shareUrl,
      licenseUrl: licenseUrl ?? this.licenseUrl,
      tags: tags ?? this.tags,
      localFilePath: localFilePath ?? this.localFilePath,
      source: source ?? this.source,
    );
  }
}
