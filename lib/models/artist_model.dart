class ArtistModel {
  final String id;
  final String name;
  final String website;
  final String joindate;
  final String image;
  final String? shorturl;
  final String? shareurl;

  ArtistModel({
    required this.id,
    required this.name,
    this.website = '',
    this.joindate = '',
    required this.image,
    this.shorturl,
    this.shareurl,
  });

  factory ArtistModel.fromJson(Map<String, dynamic> json) {
    String img = json['image'] ?? 'https://images.unsplash.com/photo-1501386761578-eac5c94b800a?w=500&auto=format&fit=crop';
    if (img.contains('usercontent.jamendo.com') && !img.contains('&width=')) {
      img = '$img&width=400';
    }
    return ArtistModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? 'Artist',
      website: json['website'] ?? '',
      joindate: json['joindate'] ?? '',
      image: img,
      shorturl: json['shorturl'],
      shareurl: json['shareurl'],
    );
  }
}
