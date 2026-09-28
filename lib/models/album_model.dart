class AlbumModel {
  final String id;
  final String name;
  final String releasedate;
  final String artistId;
  final String artistName;
  final String image;
  final String? zip;
  final String? shorturl;
  final String? shareurl;

  AlbumModel({
    required this.id,
    required this.name,
    required this.releasedate,
    required this.artistId,
    required this.artistName,
    required this.image,
    this.zip,
    this.shorturl,
    this.shareurl,
  });

  factory AlbumModel.fromJson(Map<String, dynamic> json) {
    String img = json['image'] ?? 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=500&auto=format&fit=crop';
    if (img.contains('usercontent.jamendo.com') && !img.contains('&width=')) {
      img = '$img&width=400';
    }
    return AlbumModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? 'Unknown Album',
      releasedate: json['releasedate'] ?? '',
      artistId: json['artist_id']?.toString() ?? '',
      artistName: json['artist_name'] ?? 'Various Artists',
      image: img,
      zip: json['zip'],
      shorturl: json['shorturl'],
      shareurl: json['shareurl'],
    );
  }
}
