import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_colors.dart';

class AppUpdateInfo {
  final String latestVersion;
  final String releaseName;
  final String changelog;
  final String downloadUrl;
  final bool isMandatory;

  AppUpdateInfo({
    required this.latestVersion,
    required this.releaseName,
    required this.changelog,
    required this.downloadUrl,
    this.isMandatory = false,
  });
}

class UpdateService {
  static final UpdateService _instance = UpdateService._internal();
  factory UpdateService() => _instance;
  UpdateService._internal();

  // Current App Version
  static const String currentVersion = '1.0.0';
  
  // GitHub repository / raw version endpoint (fallback to GitHub Releases API)
  static const String githubRepo = 'Mohammedsajadvt/Harmoniq-Music';

  /// Check for updates from GitHub Releases
  Future<AppUpdateInfo?> checkForUpdate() async {
    try {
      final uri = Uri.parse('https://api.github.com/repos/$githubRepo/releases/latest');
      final response = await http.get(uri).timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final tagName = (data['tag_name']?.toString() ?? '').replaceAll('v', '').trim();
        final releaseName = data['name']?.toString() ?? 'New Version Available';
        final body = data['body']?.toString() ?? '• Performance enhancements and bug fixes\n• Full-length 320kbps HD audio streaming\n• Background playback & lockscreen notifications';
        
        String downloadUrl = data['html_url']?.toString() ?? 'https://github.com/$githubRepo/releases';
        final List assets = data['assets'] ?? [];
        if (assets.isNotEmpty) {
          final apkAsset = assets.firstWhere(
            (a) => a['name'].toString().endsWith('.apk'),
            orElse: () => assets.first,
          );
          downloadUrl = apkAsset['browser_download_url'] ?? downloadUrl;
        }

        if (_isNewerVersion(tagName, currentVersion)) {
          return AppUpdateInfo(
            latestVersion: tagName,
            releaseName: releaseName,
            changelog: body,
            downloadUrl: downloadUrl,
          );
        }
      }
    } catch (e) {
      debugPrint('ℹ️ [UpdateService] No update or network offline: $e');
    }
    return null;
  }

  bool _isNewerVersion(String latest, String current) {
    if (latest.isEmpty) return false;
    final latestParts = latest.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final currentParts = current.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    for (int i = 0; i < latestParts.length && i < currentParts.length; i++) {
      if (latestParts[i] > currentParts[i]) return true;
      if (latestParts[i] < currentParts[i]) return false;
    }
    return latestParts.length > currentParts.length;
  }

  /// Show premium Update Dialog
  static void showUpdateDialog(BuildContext context, AppUpdateInfo update) {
    showDialog(
      context: context,
      barrierDismissible: !update.isMandatory,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161A24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Colors.white12, width: 1.2),
        ),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Update Available!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'Version ${update.latestVersion}',
                    style: const TextStyle(
                      color: AppColors.secondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              update.releaseName,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              constraints: const BoxConstraints(maxHeight: 180),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF0F1219),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white10),
              ),
              child: SingleChildScrollView(
                child: Text(
                  update.changelog,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12.5,
                    height: 1.45,
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          if (!update.isMandatory)
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'Later',
                style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w600),
              ),
            ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final uri = Uri.parse(update.downloadUrl);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 4,
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.download_rounded, size: 18),
                SizedBox(width: 6),
                Text(
                  'Update Now',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
