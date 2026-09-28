import 'package:flutter_test/flutter_test.dart';
import 'package:my_own_music/models/track_model.dart';
import 'package:my_own_music/models/album_model.dart';
import 'package:my_own_music/models/artist_model.dart';
import 'package:my_own_music/core/utils/time_formatter.dart';

void main() {
  test('TimeFormatter tests', () {
    expect(TimeFormatter.formatSeconds(125), '02:05');
    expect(TimeFormatter.formatSeconds(0), '00:00');
    expect(TimeFormatter.formatSeconds(3600), '60:00');
  });

  test('TrackModel json serialization test', () {
    final track = TrackModel(
      id: '101',
      name: 'Electric Neon Vibe',
      duration: 210,
      artistId: '12',
      artistName: 'SynthWave Artist',
      albumName: 'Neon Dreams',
      albumId: '55',
      albumImage: 'https://usercontent.jamendo.com?type=album&id=55',
      audioUrl: 'https://prod-1.storage.jamendo.com/?trackid=101',
      tags: ['synthwave', 'electronic'],
    );

    final json = track.toJson();
    final restored = TrackModel.fromJson(json);

    expect(restored.id, '101');
    expect(restored.name, 'Electric Neon Vibe');
    expect(restored.duration, 210);
    expect(restored.artistName, 'SynthWave Artist');
    expect(restored.source, 'jamendo');
  });

  test('SoundCloud TrackModel json serialization test', () {
    final scTrack = TrackModel(
      id: 'sc_998877',
      name: 'SoundCloud Indie Anthem',
      duration: 185,
      artistId: 'sc_user_1',
      artistName: 'SoundCloud Producer',
      albumName: 'EDM Pulse',
      albumId: 'sc_album_998877',
      albumImage: 'https://i1.sndcdn.com/artworks-sample.jpg',
      audioUrl: 'https://api-v2.soundcloud.com/media/soundcloud:tracks:998877/progressive/stream',
      tags: ['edm', 'dance'],
      source: 'soundcloud',
    );

    final json = scTrack.toJson();
    final restored = TrackModel.fromJson(json);

    expect(restored.id, 'sc_998877');
    expect(restored.isSoundCloud, true);
    expect(restored.source, 'soundcloud');
    expect(restored.name, 'SoundCloud Indie Anthem');
  });

  test('AlbumModel json serialization test', () {
    final json = {
      'id': '12345',
      'name': 'Electric Symphony',
      'releasedate': '2024-05-12',
      'artist_id': '88',
      'artist_name': 'Acoustic Master',
      'image': 'https://usercontent.jamendo.com?type=album&id=12345',
    };

    final album = AlbumModel.fromJson(json);
    expect(album.id, '12345');
    expect(album.name, 'Electric Symphony');
    expect(album.artistName, 'Acoustic Master');
    expect(album.releasedate, '2024-05-12');
  });

  test('ArtistModel json serialization test', () {
    final json = {
      'id': '777',
      'name': 'Mohammed Sajad VT',
      'image': 'https://usercontent.jamendo.com?type=artist&id=777',
      'website': 'https://instagram.com/mohammed.sajad.vt',
    };

    final artist = ArtistModel.fromJson(json);
    expect(artist.id, '777');
    expect(artist.name, 'Mohammed Sajad VT');
    expect(artist.website, 'https://instagram.com/mohammed.sajad.vt');
  });

  test('Spotify TrackModel json serialization test', () {
    final spTrack = TrackModel(
      id: 'sp_112233',
      name: 'Spotify Top Hit',
      duration: 205,
      artistId: 'sp_art_99',
      artistName: 'Top Chart Artist',
      albumName: 'Global Hit Album',
      albumId: 'sp_alb_99',
      albumImage: 'https://i.scdn.co/image/ab67616d0000b273sample',
      audioUrl: 'https://p.scdn.co/mp3-preview/sample.mp3',
      tags: ['spotify', 'chart'],
      source: 'spotify',
    );

    final json = spTrack.toJson();
    final restored = TrackModel.fromJson(json);

    expect(restored.id, 'sp_112233');
    expect(restored.isSpotify, true);
    expect(restored.source, 'spotify');
    expect(restored.name, 'Spotify Top Hit');
  });

  test('Epidemic Sound TrackModel json serialization test', () {
    final epTrack = TrackModel(
      id: 'es_14c7d465-a681-3af0-92f1-d1630b38ef14',
      name: 'Dandy Man',
      duration: 120,
      artistId: 'es_art_devil',
      artistName: 'Devil and the Perfects',
      albumName: 'Epidemic Sound Collection',
      albumId: 'es_album_royaltyfree',
      albumImage: 'https://cdn.epidemicsound.com/release-cover-images/b56a3340/3000x3000.png',
      audioUrl: '',
      tags: ['epidemicsound', 'reggae', 'happy'],
      source: 'epidemicsound',
    );

    final json = epTrack.toJson();
    final restored = TrackModel.fromJson(json);

    expect(restored.id, 'es_14c7d465-a681-3af0-92f1-d1630b38ef14');
    expect(restored.isEpidemic, true);
    expect(restored.source, 'epidemicsound');
    expect(restored.name, 'Dandy Man');
  });
}
