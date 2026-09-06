import 'package:audioplayers/audioplayers.dart';

enum SoundEffect { points, gameStart, tap, happy, sad, allDone }

/// Keeps short effects separate from the future looping music channel.
class AudioService {
  AudioService._();

  static final instance = AudioService._();

  final Map<SoundEffect, AudioPlayer> _effects = {};
  AudioPlayer? _music;
  String? _musicPath;

  static const _paths = {
    SoundEffect.points: 'sounds/points.wav',
    SoundEffect.gameStart: 'sounds/game_start.wav',
    SoundEffect.tap: 'sounds/tap.wav',
    SoundEffect.happy: 'sounds/happy.wav',
    SoundEffect.sad: 'sounds/sad.wav',
    SoundEffect.allDone: 'sounds/all_done.wav',
  };

  Future<void> preload() async {
    try {
      await Future.wait(SoundEffect.values.map(_playerFor));
    } catch (_) {}
  }

  Future<void> play(SoundEffect effect) async {
    try {
      final player = await _playerFor(effect);
      await player.stop();
      await player.resume();
    } catch (_) {}
  }

  Future<void> playMusic(String assetPath, {double volume = 1}) async {
    final player = _music ??= AudioPlayer();
    try {
      await player.setReleaseMode(ReleaseMode.loop);
      await player.setVolume(volume);
      if (_musicPath != assetPath) {
        _musicPath = assetPath;
        await player.setSource(AssetSource(assetPath));
      }
      await player.resume();
    } catch (_) {}
  }

  Future<void> pauseMusic() async {
    try {
      await _music?.pause();
    } catch (_) {}
  }

  Future<void> resumeMusic() async {
    try {
      await _music?.resume();
    } catch (_) {}
  }

  Future<void> setMusicVolume(double volume) async {
    try {
      await _music?.setVolume(volume);
    } catch (_) {}
  }

  Future<void> stopMusic() async {
    try {
      await _music?.stop();
    } catch (_) {}
  }

  Future<void> dispose() async {
    for (final player in _effects.values) {
      await player.dispose();
    }
    await _music?.dispose();
    _effects.clear();
    _music = null;
    _musicPath = null;
  }

  Future<AudioPlayer> _playerFor(SoundEffect effect) async {
    final player = _effects.putIfAbsent(effect, AudioPlayer.new);
    if (player.source != null) return player;
    await player.setReleaseMode(ReleaseMode.stop);
    await player.setSource(AssetSource(_paths[effect]!));
    return player;
  }
}
