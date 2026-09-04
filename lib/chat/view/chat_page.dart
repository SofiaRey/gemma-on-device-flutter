import 'dart:async';

import 'package:fcl_2026_demo/chat/chat.dart';
import 'package:fcl_2026_demo/l10n/l10n.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The palette of the design: ink on white, one accent per state.
abstract final class ChatColors {
  static const ink = Color(0xFF171717);
  static const muted = Color(0xFF4D4D4D);
  static const line = Color(0x1A000000);
  static const fieldFill = Color(0xFFFAFAFA);
  static const fieldLine = Color(0x14000000);
  static const track = Color(0xFFEBEBEB);
  static const amber = Color(0xFFA35200);
  static const green = Color(0xFF0F7D32);
  static const blue = Color(0xFF006BFF);
  static const red = Color(0xFFD8001B);
}

/// Geist at the exact sizes of the design. Weight 450 exists because Geist
/// is a variable font, so `fontVariations` picks the axis value directly.
abstract final class ChatText {
  static const _sans = 'Geist';
  static const _mono = 'Geist Mono';

  static const state = TextStyle(
    fontFamily: _sans,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    height: 1.385,
  );
  static const title = TextStyle(
    fontFamily: _sans,
    fontSize: 32,
    fontVariations: [FontVariation.weight(450)],
    letterSpacing: -0.6,
    height: 1.25,
    color: ChatColors.ink,
  );
  static const lede = TextStyle(
    fontFamily: _sans,
    fontSize: 18,
    height: 1.556,
    color: ChatColors.muted,
  );
  static const caption = TextStyle(
    fontFamily: _sans,
    fontSize: 13,
    height: 1.385,
    color: ChatColors.muted,
  );
  static const specKey = TextStyle(
    fontFamily: _sans,
    fontSize: 14,
    height: 1.43,
    color: ChatColors.muted,
  );
  static const specValue = TextStyle(
    fontFamily: _mono,
    fontSize: 13,
    height: 1.385,
    color: ChatColors.ink,
  );
  static const button = TextStyle(
    fontFamily: _sans,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.43,
    color: Colors.white,
  );
  static const percent = TextStyle(
    fontFamily: _sans,
    fontSize: 48,
    fontWeight: FontWeight.w500,
    letterSpacing: -1.6,
    height: 1.167,
    color: ChatColors.ink,
  );
  static const header = TextStyle(
    fontFamily: _sans,
    fontSize: 20,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.2,
    height: 1.3,
    color: ChatColors.ink,
  );
  static const statValue = TextStyle(
    fontFamily: _sans,
    fontSize: 20,
    fontWeight: FontWeight.w500,
    height: 1.3,
    color: ChatColors.ink,
  );
  static const role = TextStyle(
    fontFamily: _sans,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    height: 1.385,
    color: ChatColors.muted,
  );
  static const count = TextStyle(
    fontFamily: _mono,
    fontSize: 13,
    height: 1.385,
    color: ChatColors.muted,
  );
  static const body = TextStyle(
    fontFamily: _sans,
    fontSize: 24,
    fontVariations: [FontVariation.weight(450)],
    height: 1.333,
  );
  static const input = TextStyle(
    fontFamily: _sans,
    fontSize: 14,
    height: 1.43,
    color: ChatColors.ink,
  );
}

class ChatPage extends StatelessWidget {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final cubit = ChatCubit();
        unawaited(cubit.initialize());
        return cubit;
      },
      child: const ChatView(),
    );
  }
}

class ChatView extends StatelessWidget {
  const ChatView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final status = context.select<ChatCubit, ChatStatus>(
      (cubit) => cubit.state.status,
    );
    return Scaffold(
      body: SafeArea(
        child: switch (status) {
          ChatStatus.checkingCache => _BusyScreen(
            label: l10n.checkingCacheState,
          ),
          ChatStatus.needsDownload => const _DownloadScreen(),
          ChatStatus.downloading => const _DownloadingScreen(),
          ChatStatus.loadingModel => _BusyScreen(
            label: l10n.loadingModelState,
          ),
          ChatStatus.ready || ChatStatus.generating => const _ChatScreen(),
          ChatStatus.error => const _ErrorScreen(),
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared pieces
// ---------------------------------------------------------------------------

/// Content column of the full-screen states: 24 on the sides, 32 between
/// sections, scrolls on short phones.
class _Page extends StatelessWidget {
  const _Page({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 32,
        children: children,
      ),
    );
  }
}

/// A 7 px dot and a label in the same color: the state indicator that
/// appears on every screen.
class _StateLabel extends StatelessWidget {
  const _StateLabel({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 8,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        Text(label, style: ChatText.state.copyWith(color: color)),
      ],
    );
  }
}

/// Key on the left, monospaced value on the right, hairline below.
class _SpecList extends StatelessWidget {
  const _SpecList({required this.rows});

  final Map<String, String> rows;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: ChatColors.line)),
      ),
      child: Column(
        children: [
          for (final entry in rows.entries)
            Container(
              height: 44,
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: ChatColors.line)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                spacing: 16,
                children: [
                  Text(entry.key, style: ChatText.specKey),
                  Text(entry.value, style: ChatText.specValue),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Full-width 44 px button. Ink by default, red for the destructive one.
class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.color = ChatColors.ink,
  });

  final String label;
  final VoidCallback onPressed;
  final Widget? icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(44),
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 8,
        children: [
          ?icon,
          Text(label, style: ChatText.button),
        ],
      ),
    );
  }
}

/// 8 px progress track. `null` animates, a value fills left to right.
class _Track extends StatelessWidget {
  const _Track({this.value});

  final double? value;

  @override
  Widget build(BuildContext context) {
    return LinearProgressIndicator(
      value: value,
      minHeight: 8,
      color: ChatColors.ink,
      backgroundColor: ChatColors.track,
      borderRadius: BorderRadius.circular(4),
    );
  }
}

// ---------------------------------------------------------------------------
// Checking cache, loading model
// ---------------------------------------------------------------------------

class _BusyScreen extends StatelessWidget {
  const _BusyScreen({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return _Page(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 16,
          children: [
            _StateLabel(label: label, color: ChatColors.muted),
            const _Track(),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 1 · Download
// ---------------------------------------------------------------------------

class _DownloadScreen extends StatelessWidget {
  const _DownloadScreen();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return _Page(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 16,
          children: [
            _StateLabel(
              label: l10n.notInstalledState,
              color: ChatColors.muted,
            ),
            Text(l10n.downloadTitle, style: ChatText.title),
            Text(l10n.downloadLede, style: ChatText.lede),
          ],
        ),
        _SpecList(
          rows: {
            l10n.specModelKey: 'Gemma3-1B-IT',
            l10n.specFormatKey: '.litertlm',
            l10n.specQuantizationKey: 'q4 · ekv4096',
            l10n.specEngineKey: 'LiteRT-LM',
            l10n.specDownloadSizeKey: const DownloadProgress().totalLabel,
          },
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 12,
          children: [
            _PrimaryButton(
              label: l10n.downloadButtonLabel,
              icon: const Icon(Icons.download, size: 16),
              onPressed: () => context.read<ChatCubit>().downloadModel(),
            ),
            Text(l10n.downloadCaption, style: ChatText.caption),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 2 · Downloading
// ---------------------------------------------------------------------------

class _DownloadingScreen extends StatelessWidget {
  const _DownloadingScreen();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final download = context.select<ChatCubit, DownloadProgress>(
      (cubit) => cubit.state.download,
    );
    final destination = defaultTargetPlatform == TargetPlatform.iOS
        ? l10n.destinationIos
        : l10n.destinationAndroid;
    return _Page(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 16,
          children: [
            _StateLabel(label: l10n.downloadingState, color: ChatColors.amber),
            Text(download.percentLabel, style: ChatText.percent),
            _Track(value: download.percent / 100),
          ],
        ),
        _SpecList(
          rows: {
            l10n.downloadedKey: download.downloadedLabel,
            l10n.rateKey: download.rateLabel,
            l10n.timeLeftKey: download.timeLeftLabel,
            l10n.destinationKey: destination,
          },
        ),
        Text(l10n.downloadingCaption, style: ChatText.caption),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 3 · Chat ready, 4 · Generating
// ---------------------------------------------------------------------------

class _ChatScreen extends StatelessWidget {
  const _ChatScreen();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _Header(),
        _StatStrip(),
        Expanded(child: _Transcript()),
        _Composer(),
      ],
    );
  }
}

/// The airplane-mode camera moment: green "Offline ready" while idle, blue
/// "Generating" while tokens stream.
class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final generating = context.select<ChatCubit, bool>(
      (cubit) => cubit.state.status == ChatStatus.generating,
    );
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: ChatColors.line)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(l10n.modelName, style: ChatText.header),
          if (generating)
            _StateLabel(label: l10n.generatingState, color: ChatColors.blue)
          else
            _StateLabel(
              label: l10n.offlineReadyState,
              color: ChatColors.green,
            ),
        ],
      ),
    );
  }
}

/// The five talking points, always on screen.
class _StatStrip extends StatelessWidget {
  const _StatStrip();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final metrics = context.select<ChatCubit, ChatMetrics>(
      (cubit) => cubit.state.metrics,
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: ChatColors.line)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 16,
        children: [
          Row(
            spacing: 16,
            children: [
              _Stat(label: l10n.metricSizeLabel, value: metrics.sizeLabel),
              _Stat(
                label: l10n.metricColdLoadLabel,
                value: metrics.coldLoadLabel,
              ),
              _Stat(
                label: l10n.metricTpsLabel,
                value: metrics.tokensPerSecondLabel,
              ),
            ],
          ),
          Row(
            spacing: 16,
            children: [
              _Stat(
                label: l10n.metricTtftLabel,
                value: metrics.timeToFirstTokenLabel,
              ),
              _Stat(
                label: l10n.metricMemoryLabel,
                value: metrics.peakMemoryLabel,
              ),
              const Spacer(),
            ],
          ),
          Text(l10n.metricsNote, style: ChatText.caption),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 4,
        children: [
          Text(label, style: ChatText.caption),
          Text(value, style: ChatText.statValue),
        ],
      ),
    );
  }
}

class _Transcript extends StatelessWidget {
  const _Transcript();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final messages = context.select<ChatCubit, List<ChatMessage>>(
      (cubit) => cubit.state.messages,
    );
    if (messages.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Align(
          alignment: Alignment.bottomLeft,
          child: Text(l10n.emptyTranscriptHint, style: ChatText.lede),
        ),
      );
    }
    // reverse + reversed list = free autoscroll while tokens stream in.
    return ListView.separated(
      reverse: true,
      padding: const EdgeInsets.all(24),
      itemCount: messages.length,
      separatorBuilder: (_, _) => const SizedBox(height: 32),
      itemBuilder: (context, index) {
        final message = messages[messages.length - 1 - index];
        final streaming = index == 0 && !message.isFromUser;
        return _Turn(message: message, streaming: streaming);
      },
    );
  }
}

/// One turn of the conversation: role label, then the text. The reply that
/// is still streaming adds a token counter and a caret.
class _Turn extends StatelessWidget {
  const _Turn({required this.message, required this.streaming});

  final ChatMessage message;
  final bool streaming;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final generating = context.select<ChatCubit, bool>(
      (cubit) => cubit.state.status == ChatStatus.generating,
    );
    final live = streaming && generating;
    final isUser = message.isFromUser;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        Row(
          spacing: 8,
          children: [
            Text(
              isUser ? l10n.userRoleLabel : l10n.modelName,
              style: ChatText.role,
            ),
            if (live)
              Text(
                l10n.tokenCountLabel(message.tokenCount),
                style: ChatText.count,
              ),
          ],
        ),
        if (message.text.isNotEmpty)
          Text(
            message.text,
            style: ChatText.body.copyWith(
              color: isUser ? ChatColors.muted : ChatColors.ink,
            ),
          ),
        if (live) const _Caret(),
      ],
    );
  }
}

class _Caret extends StatefulWidget {
  const _Caret();

  @override
  State<_Caret> createState() => _CaretState();
}

class _CaretState extends State<_Caret> with SingleTickerProviderStateMixin {
  late final _blink = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  )..repeat();

  @override
  void dispose() {
    _blink.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _blink.drive(
        TweenSequence([
          TweenSequenceItem(tween: ConstantTween(1), weight: 1),
          TweenSequenceItem(tween: ConstantTween(0), weight: 1),
        ]),
      ),
      child: Container(
        key: const Key('streaming_caret'),
        width: 3,
        height: 24,
        decoration: BoxDecoration(
          color: ChatColors.ink,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class _Composer extends StatefulWidget {
  const _Composer();

  @override
  State<_Composer> createState() => _ComposerState();
}

class _ComposerState extends State<_Composer> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send() {
    unawaited(context.read<ChatCubit>().sendMessage(_controller.text));
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final generating = context.select<ChatCubit, bool>(
      (cubit) => cubit.state.status == ChatStatus.generating,
    );
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: ChatColors.line)),
      ),
      child: generating
          ? _PrimaryButton(
              label: l10n.stopButtonLabel,
              color: ChatColors.red,
              icon: Container(
                width: 11,
                height: 11,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              onPressed: () => context.read<ChatCubit>().stopGeneration(),
            )
          : Row(
              spacing: 8,
              children: [
                Expanded(
                  child: Container(
                    height: 44,
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: ChatColors.fieldFill,
                      border: Border.all(color: ChatColors.fieldLine),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TextField(
                      controller: _controller,
                      onSubmitted: (_) => _send(),
                      style: ChatText.input,
                      cursorColor: ChatColors.ink,
                      decoration: InputDecoration(
                        hintText: l10n.inputHint,
                        hintStyle: ChatText.input.copyWith(
                          color: ChatColors.muted,
                        ),
                        isCollapsed: true,
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                IconButton.filled(
                  onPressed: _send,
                  icon: const Icon(Icons.arrow_upward, size: 16),
                  style: IconButton.styleFrom(
                    backgroundColor: ChatColors.ink,
                    foregroundColor: Colors.white,
                    fixedSize: const Size.square(44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

// ---------------------------------------------------------------------------
// Error
// ---------------------------------------------------------------------------

class _ErrorScreen extends StatelessWidget {
  const _ErrorScreen();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final message = context.select<ChatCubit, String?>(
      (cubit) => cubit.state.errorMessage,
    );
    return _Page(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 16,
          children: [
            _StateLabel(label: l10n.errorState, color: ChatColors.red),
            Text(
              message ?? '',
              maxLines: 8,
              overflow: TextOverflow.ellipsis,
              style: ChatText.lede,
            ),
          ],
        ),
        _PrimaryButton(
          label: l10n.retryButtonLabel,
          onPressed: () => context.read<ChatCubit>().retry(),
        ),
      ],
    );
  }
}
