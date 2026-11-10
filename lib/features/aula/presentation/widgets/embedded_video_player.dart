import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../../../../core/theme/app_colors.dart';

/// Extrae el ID de un video de YouTube desde cualquier formato de URL
/// (`watch?v=`, `youtu.be/`, `shorts/`, `embed/`); null si no lo es.
String? extractYoutubeVideoId(String url) {
  final uri = Uri.tryParse(url.trim());
  if (uri == null) return null;

  final host = uri.host.toLowerCase().replaceAll('www.', '');
  if (host == 'youtu.be') {
    final id = uri.pathSegments.firstOrNull;
    return (id != null && id.isNotEmpty) ? id : null;
  }
  if (host == 'youtube.com' || host == 'm.youtube.com') {
    final byQuery = uri.queryParameters['v'];
    if (byQuery != null && byQuery.isNotEmpty) return byQuery;

    // /embed/ID, /shorts/ID, /live/ID
    final segments = uri.pathSegments;
    if (segments.length >= 2 &&
        const {'embed', 'shorts', 'live'}.contains(segments.first)) {
      return segments[1];
    }
  }
  return null;
}

/// Video de presentación de la lección, embebido en el propio aula.
///
/// Se renderiza SOLO cuando la URL es de YouTube (ver
/// [extractYoutubeVideoId]); el resto de contenidos (Drive, Telegram,
/// Zoom, .mp4 externos) siguen abriéndose con `launchUrl` fuera de la
/// app. Al terminar el video se dispara [onVideoEnded] (una sola vez
/// por reproducción) para auto-marcar la lección como completada.
class EmbeddedVideoPlayer extends StatefulWidget {
  const EmbeddedVideoPlayer({
    super.key,
    required this.url,
    this.onVideoEnded,
  });

  final String url;
  final VoidCallback? onVideoEnded;

  /// true si [url] es de YouTube y puede embeberse con este widget.
  static bool canEmbed(String url) => extractYoutubeVideoId(url) != null;

  @override
  State<EmbeddedVideoPlayer> createState() => _EmbeddedVideoPlayerState();
}

class _EmbeddedVideoPlayerState extends State<EmbeddedVideoPlayer> {
  late final YoutubePlayerController _controller;
  bool _endedReported = false;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController.fromVideoId(
      videoId: extractYoutubeVideoId(widget.url)!,
      autoPlay: false,
      params: const YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: true,
        mute: false,
        loop: false,
      ),
    );
    _controller.listen(_onPlayerChanged);
  }

  void _onPlayerChanged(YoutubePlayerValue value) {
    if (value.playerState != PlayerState.ended || _endedReported) return;
    _endedReported = true;
    widget.onVideoEnded?.call();
  }

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.play_circle_outline, color: AppColors.textDark, size: 22),
              SizedBox(width: 10),
              Text(
                'Video de la clase',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Vídeo acotado en ancho y centrado. En web el iframe de
          // YouTube captura el ratón (el cursor sobre él no desplaza la
          // página), así que dejar márgenes a los lados permite seguir
          // bajando el aula con el cursor fuera del vídeo.
          Align(
            alignment: Alignment.center,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: YoutubePlayer(
                  controller: _controller,
                  aspectRatio: 16 / 9,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Al terminar el video la lección se marcará como completada.',
            style: TextStyle(
              fontSize: 12.5,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _openExternally(widget.url),
              icon: const Icon(Icons.open_in_new, size: 18),
              label: const Text('Abrir en YouTube'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textDark,
                side: const BorderSide(color: Color(0xFFE5E7EB)),
                padding: const EdgeInsets.symmetric(vertical: 11),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openExternally(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
