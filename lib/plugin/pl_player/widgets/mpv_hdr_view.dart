import 'dart:io' show Platform;

import 'package:PiliPlus/plugin/pl_player/widgets/native_hdr_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show PlatformViewHitTestBehavior;
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';

class MpvHdrView extends StatelessWidget {
  const MpvHdrView({
    required this.player,
    required this.width,
    required this.height,
    this.aspectRatio,
    super.key,
  });

  final NativePlayer player;
  final int? width;
  final int? height;
  final double? aspectRatio;

  @override
  Widget build(BuildContext context) {
    final w = width ?? 1920;
    final h = height ?? 1080;
    return SizedBox(
      width: (aspectRatio ?? (w > 0 && h > 0 ? w / h : 16 / 9)) * 360,
      height: 360,
      child: Platform.isAndroid
          ? _MpvSurface(player: player)
          : const Center(
              child: Text(
                'HDR 视频在 mpv 原生窗口播放',
                style: TextStyle(color: Colors.white),
              ),
            ),
    );
  }
}

class _MpvSurface extends StatefulWidget {
  const _MpvSurface({required this.player});

  final NativePlayer player;

  @override
  State<_MpvSurface> createState() => _MpvSurfaceState();
}

class _MpvSurfaceState extends State<_MpvSurface> {
  static const _viewType = 'piliplus/mpv_hdr';
  static const _failure = 'mpv HDR 画面初始化失败。请关闭「mpv HDR 直出（实验）」后重新打开视频。';

  MethodChannel? _channel;
  bool _attached = false;
  bool _failed = false;

  void _detach() {
    if (!_attached) return;
    _attached = false;
    final player = widget.player;
    if (player.disposed) return;
    player
      ..setProperty('vid', 'no')
      ..setOption('vo', 'null')
      ..setOption('wid', '0');
  }

  Future<void> _onSurface(MethodCall call) async {
    if (call.method != 'surface' || !mounted || widget.player.disposed) return;
    final wid = call.arguments as int;
    if (wid <= 0) {
      _detach();
      if (wid < 0) {
        setState(() => _failed = true);
        await widget.player.pause();
      }
      return;
    }
    _detach();
    _attached = true;
    widget.player
      ..setOption('wid', wid.toString())
      ..setOption('vo', 'mediacodec_embed')
      ..setProperty('vid', 'auto');
  }

  @override
  void dispose() {
    _detach();
    _channel?.setMethodCallHandler(null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return const Center(
        child: Text(_failure, style: TextStyle(color: Colors.white)),
      );
    }
    return HdrSurfaceComposition(
      errorMessage: _failure,
      onAvailability: (ready) async {
        if (!ready && !widget.player.disposed) await widget.player.pause();
      },
      builder: (context) => PlatformViewLink(
        viewType: _viewType,
        surfaceFactory: (_, controller) => AndroidViewSurface(
          controller: controller as AndroidViewController,
          hitTestBehavior: PlatformViewHitTestBehavior.transparent,
          gestureRecognizers: const {},
        ),
        onCreatePlatformView: (params) {
          _channel = MethodChannel('$_viewType/${params.id}')
            ..setMethodCallHandler(_onSurface);
          final controller = PlatformViewsService.initExpensiveAndroidView(
            id: params.id,
            viewType: params.viewType,
            layoutDirection: Directionality.of(context),
            onFocus: () => params.onFocusChanged(true),
          );
          return controller
            ..addOnPlatformViewCreatedListener(params.onPlatformViewCreated)
            ..create();
        },
      ),
    );
  }
}
