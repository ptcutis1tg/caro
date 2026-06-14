import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class AudioManager {
  static final AudioManager instance = AudioManager._internal();
  
  final AudioPlayer _sfxPlayer = AudioPlayer();
  final AudioPlayer _bgmPlayer = AudioPlayer();
  
  bool _isMuted = false;

  AudioManager._internal() {
    _bgmPlayer.setReleaseMode(ReleaseMode.loop);
    _bgmPlayer.setVolume(0.35);
    _sfxPlayer.setVolume(0.85);
  }

  bool get isMuted => _isMuted;

  void toggleMute() {
    _isMuted = !_isMuted;
    if (_isMuted) {
      _bgmPlayer.setVolume(0);
      _sfxPlayer.setVolume(0);
    } else {
      _bgmPlayer.setVolume(0.35);
      _sfxPlayer.setVolume(0.85);
    }
  }

  Future<void> playStartup() async {
    if (_isMuted) return;
    try {
      await _sfxPlayer.stop();
      await _sfxPlayer.play(AssetSource('audio/win7_startup.wav'));
    } catch (e) {
      debugPrint('Error playing startup audio: $e');
    }
  }

  Future<void> playShutdown() async {
    if (_isMuted) return;
    try {
      await _sfxPlayer.stop();
      await _sfxPlayer.play(AssetSource('audio/win7_shutdown.wav'));
    } catch (e) {
      debugPrint('Error playing shutdown audio: $e');
    }
  }

  Future<void> playWin() async {
    if (_isMuted) return;
    try {
      await _sfxPlayer.stop();
      await _sfxPlayer.play(AssetSource('audio/win.wav'));
    } catch (e) {
      debugPrint('Error playing win audio: $e');
    }
  }

  Future<void> playLose() async {
    if (_isMuted) return;
    try {
      await _sfxPlayer.stop();
      await _sfxPlayer.play(AssetSource('audio/lose.wav'));
    } catch (e) {
      debugPrint('Error playing lose audio: $e');
    }
  }

  Future<void> playMove() async {
    if (_isMuted) return;
    try {
      // Re-initialize player stream if it's already playing, or just stop and start.
      // A quick stop & play works fine for simple move ticks.
      await _sfxPlayer.stop();
      await _sfxPlayer.play(AssetSource('audio/move.wav'));
    } catch (e) {
      debugPrint('Error playing move audio: $e');
    }
  }

  Future<void> startPvPBgm() async {
    if (_isMuted) return;
    try {
      await _bgmPlayer.stop();
      await _bgmPlayer.play(AssetSource('audio/pvp_bgm.wav'));
    } catch (e) {
      debugPrint('Error starting PvP BGM: $e');
    }
  }

  Future<void> stopPvPBgm() async {
    try {
      await _bgmPlayer.stop();
    } catch (e) {
      debugPrint('Error stopping PvP BGM: $e');
    }
  }
}
