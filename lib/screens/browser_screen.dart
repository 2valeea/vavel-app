import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../providers/locale_provider.dart';

// ── Quick-access DApp bookmarks ───────────────────────────────────────────

class _Bookmark {
  final String label;
  final String url;
  final IconData icon;
  final Color color;
  const _Bookmark(this.label, this.url, this.icon, this.color);
}

const _kBookmarks = [
  _Bookmark(
      'TON DNS', 'https://dns.ton.org', Icons.language, Color(0xFF0098EA)),
  _Bookmark(
      'STON.fi', 'https://app.ston.fi', Icons.swap_horiz, Color(0xFF00BCD4)),
  _Bookmark('DeDust', 'https://dedust.io', Icons.water_drop_outlined,
      Color(0xFF7B61FF)),
  _Bookmark(
      'Raydium', 'https://raydium.io', Icons.bolt_outlined, Color(0xFF9945FF)),
  _Bookmark('Jupiter', 'https://jup.ag', Icons.public, Color(0xFF2979FF)),
  _Bookmark('TON NFT', 'https://getgems.io', Icons.diamond_outlined,
      Color(0xFFF7931A)),
];

// ── Browser screen ────────────────────────────────────────────────────────

class BrowserScreen extends ConsumerStatefulWidget {
  /// Optional URL to open immediately on launch.
  final String? initialUrl;

  const BrowserScreen({super.key, this.initialUrl});

  @override
  ConsumerState<BrowserScreen> createState() => _BrowserScreenState();
}

class _BrowserScreenState extends ConsumerState<BrowserScreen> {
  late final WebViewController? _controller;
  final _urlController = TextEditingController();

  bool _loading = false;
  bool _canGoBack = false;
  bool _canGoForward = false;
  double _loadProgress = 0;

  /// Whether the current platform supports WebView.
  bool get _webViewSupported => !kIsWeb;

  @override
  void initState() {
    super.initState();
    if (_webViewSupported) {
      final url = widget.initialUrl ?? 'https://ton.app';
      _urlController.text = url;
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(NavigationDelegate(
          onPageStarted: (url) {
            if (!mounted) return;
            setState(() {
              _loading = true;
              _urlController.text = url;
              _loadProgress = 0;
            });
          },
          onProgress: (progress) {
            if (!mounted) return;
            setState(() => _loadProgress = progress / 100.0);
          },
          onPageFinished: (url) async {
            if (!mounted) return;
            final back = await _controller!.canGoBack();
            final fwd = await _controller!.canGoForward();
            setState(() {
              _loading = false;
              _canGoBack = back;
              _canGoForward = fwd;
            });
          },
          onNavigationRequest: (request) {
            // Only allow http/https navigation
            if (!request.url.startsWith('http://') &&
                !request.url.startsWith('https://')) {
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ))
        ..loadRequest(Uri.parse(url));
    } else {
      _controller = null;
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  void _navigate(String input) {
    String url = input.trim();
    if (url.isEmpty) return;
    // If it looks like a bare domain or contains no scheme, add https://
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      if (url.contains('.') && !url.contains(' ')) {
        url = 'https://$url';
      } else {
        // Treat as a search query
        url =
            'https://www.google.com/search?q=${Uri.encodeQueryComponent(url)}';
      }
    }
    _controller?.loadRequest(Uri.parse(url));
    _urlController.text = url;
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: _AddressBar(
          controller: _urlController,
          loading: _loading,
          onSubmit: _navigate,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            tooltip: 'Reload',
            onPressed: () => _controller?.reload(),
          ),
        ],
        bottom: _loading
            ? PreferredSize(
                preferredSize: const Size.fromHeight(2),
                child: LinearProgressIndicator(
                  value: _loadProgress,
                  minHeight: 2,
                  backgroundColor: Colors.transparent,
                  valueColor: const AlwaysStoppedAnimation(Color(0xFF2979FF)),
                ),
              )
            : null,
      ),
      // ── Navigation bar ────────────────────────────────────────────────
      bottomNavigationBar: SafeArea(
        child: Container(
          height: 48,
          color: const Color(0xFF0D1B2E),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavButton(
                icon: Icons.arrow_back_ios_new,
                enabled: _canGoBack,
                onPressed: () => _controller?.goBack(),
              ),
              _NavButton(
                icon: Icons.arrow_forward_ios,
                enabled: _canGoForward,
                onPressed: () => _controller?.goForward(),
              ),
              _NavButton(
                icon: Icons.home_outlined,
                enabled: true,
                onPressed: () {
                  const home = 'https://ton.app';
                  _controller?.loadRequest(Uri.parse(home));
                  _urlController.text = home;
                },
              ),
              _NavButton(
                icon: Icons.bookmark_border,
                enabled: true,
                onPressed: () => _showBookmarks(context, s),
              ),
            ],
          ),
        ),
      ),
      body: _webViewSupported ? _buildWebView(s) : _buildUnsupported(s),
    );
  }

  Widget _buildWebView(s) {
    return WebViewWidget(controller: _controller!);
  }

  Widget _buildUnsupported(s) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.web_asset_off_outlined,
                size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              s.browserNotSupported,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 24),
            // Show bookmarks as buttons even on unsupported platforms
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: _kBookmarks
                  .map((b) => _BookmarkChip(bookmark: b, onTap: (_) {}))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  void _showBookmarks(BuildContext context, s) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A2A3E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  s.browserQuickAccess.toUpperCase(),
                  style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _kBookmarks
                      .map((b) => _BookmarkChip(
                            bookmark: b,
                            onTap: (url) {
                              Navigator.of(ctx).pop();
                              _navigate(url);
                            },
                          ))
                      .toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Address bar ───────────────────────────────────────────────────────────

class _AddressBar extends StatelessWidget {
  final TextEditingController controller;
  final bool loading;
  final ValueChanged<String> onSubmit;

  const _AddressBar({
    required this.controller,
    required this.loading,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2A3E),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Icon(
              loading ? Icons.refresh : Icons.lock_outline,
              size: 14,
              color: loading ? const Color(0xFF2979FF) : Colors.grey,
            ),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              style: const TextStyle(fontSize: 13, color: Colors.white),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.go,
              autocorrect: false,
              onSubmitted: onSubmit,
            ),
          ),
          if (controller.text.isNotEmpty)
            GestureDetector(
              onTap: () {
                controller.clear();
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.close, size: 14, color: Colors.grey),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Bottom nav button ─────────────────────────────────────────────────────

class _NavButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onPressed;

  const _NavButton({
    required this.icon,
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: 20),
      color: enabled ? Colors.white70 : Colors.white24,
      onPressed: enabled ? onPressed : null,
    );
  }
}

// ── Bookmark chip ─────────────────────────────────────────────────────────

class _BookmarkChip extends StatelessWidget {
  final _Bookmark bookmark;
  final ValueChanged<String> onTap;

  const _BookmarkChip({required this.bookmark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap(bookmark.url),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: bookmark.color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: bookmark.color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(bookmark.icon, color: bookmark.color, size: 16),
            const SizedBox(width: 8),
            Text(
              bookmark.label,
              style: TextStyle(
                  color: bookmark.color,
                  fontSize: 13,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
