import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:get/get.dart';

class LegalDocumentView extends StatefulWidget {
  const LegalDocumentView({
    super.key,
    required this.title,
    required this.assetPath,
    this.showAgreementAction = false,
    this.agreementButtonLabel = 'I Agree',
  });

  final String title;
  final String assetPath;
  final bool showAgreementAction;
  final String agreementButtonLabel;

  @override
  State<LegalDocumentView> createState() => _LegalDocumentViewState();
}

class _LegalDocumentViewState extends State<LegalDocumentView> {
  final ScrollController _scrollController = ScrollController();
  _ParsedMarkdown? _cachedParsed;
  String? _cachedRawMarkdown;
  int _activeSectionIndex = 0;
  bool _showBackToTop = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: FutureBuilder<String>(
        future: rootBundle.loadString(widget.assetPath),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.description_outlined,
                      size: 36,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'legal_load_error'.tr,
                      style: theme.textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          final data = snapshot.data!;
          final lastUpdated = _extractLastUpdated(data);
          final parsed = _getParsedMarkdown(data);
          final markdownStyle = MarkdownStyleSheet.fromTheme(theme).copyWith(
            p: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
            h1: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            h2: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            listBullet: theme.textTheme.bodyMedium,
            blockSpacing: 14,
            horizontalRuleDecoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
            ),
          );

          return NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              final pixels = notification.metrics.pixels;
              final shouldShowBackToTop = pixels > 320;
              if (shouldShowBackToTop != _showBackToTop) {
                setState(() {
                  _showBackToTop = shouldShowBackToTop;
                });
              }

              if (notification is ScrollUpdateNotification ||
                  notification is UserScrollNotification ||
                  notification is ScrollEndNotification) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;
                  _updateActiveSectionIndex(parsed);
                });
              }
              return false;
            },
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              children: [
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(color: theme.colorScheme.outlineVariant),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Icon(
                          Icons.gavel_rounded,
                          size: 18,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.title,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (lastUpdated != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  'legal_last_updated'.trParams({
                                    'date': lastUpdated,
                                  }),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (parsed.sections.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(color: theme.colorScheme.outlineVariant),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'legal_toc_title'.tr,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...List.generate(parsed.sections.length, (index) {
                            final section = parsed.sections[index];
                            final isActive = _activeSectionIndex == index;
                            return InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: () {
                                setState(() {
                                  _activeSectionIndex = index;
                                });
                                final targetContext =
                                    section.key.currentContext;
                                if (targetContext != null) {
                                  Scrollable.ensureVisible(
                                    targetContext,
                                    duration: const Duration(milliseconds: 350),
                                    curve: Curves.easeInOut,
                                  );
                                }
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 6,
                                  horizontal: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? theme.colorScheme.primaryContainer
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.chevron_right,
                                      size: 16,
                                      color: isActive
                                          ? theme.colorScheme.primary
                                          : theme.colorScheme.onSurfaceVariant,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        section.title,
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                              fontWeight: isActive
                                                  ? FontWeight.w700
                                                  : FontWeight.w500,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(color: theme.colorScheme.outlineVariant),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (parsed.intro.trim().isNotEmpty)
                          MarkdownBody(
                            data: parsed.intro,
                            selectable: true,
                            styleSheet: markdownStyle,
                            shrinkWrap: false,
                          ),
                        ...parsed.sections.map(
                          (section) => Container(
                            key: section.key,
                            margin: const EdgeInsets.only(top: 10),
                            child: MarkdownBody(
                              data: '## ${section.title}\n\n${section.content}',
                              selectable: true,
                              styleSheet: markdownStyle,
                              shrinkWrap: false,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: widget.showAgreementAction
          ? SafeArea(
              minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Card(
                elevation: 0,
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: theme.colorScheme.outlineVariant),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: Text(widget.agreementButtonLabel),
                    ),
                  ),
                ),
              ),
            )
          : null,
      floatingActionButton: AnimatedScale(
        scale: _showBackToTop ? 1 : 0,
        duration: const Duration(milliseconds: 180),
        child: FloatingActionButton.small(
          tooltip: 'legal_back_to_top_tooltip'.tr,
          onPressed: _showBackToTop
              ? () {
                  _scrollController.animateTo(
                    0,
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeInOut,
                  );
                }
              : null,
          child: const Icon(Icons.keyboard_arrow_up_rounded),
        ),
      ),
    );
  }

  _ParsedMarkdown _getParsedMarkdown(String markdown) {
    if (_cachedParsed != null && _cachedRawMarkdown == markdown) {
      return _cachedParsed!;
    }

    final parsed = _parseSections(markdown);
    _cachedRawMarkdown = markdown;
    _cachedParsed = parsed;
    _activeSectionIndex = 0;
    return parsed;
  }

  void _updateActiveSectionIndex(_ParsedMarkdown parsed) {
    if (parsed.sections.isEmpty) return;

    const viewportAnchorY = 170.0;
    var closestPassedIndex = -1;
    var closestPassedDy = -99999.0;
    var firstUpcomingIndex = -1;
    var firstUpcomingDy = 99999.0;

    for (var i = 0; i < parsed.sections.length; i++) {
      final context = parsed.sections[i].key.currentContext;
      if (context == null) continue;
      final renderObject = context.findRenderObject();
      if (renderObject is! RenderBox) continue;

      final dy = renderObject.localToGlobal(Offset.zero).dy;
      if (dy <= viewportAnchorY && dy > closestPassedDy) {
        closestPassedDy = dy;
        closestPassedIndex = i;
      }
      if (dy > viewportAnchorY && dy < firstUpcomingDy) {
        firstUpcomingDy = dy;
        firstUpcomingIndex = i;
      }
    }

    final newIndex = closestPassedIndex >= 0
        ? closestPassedIndex
        : (firstUpcomingIndex >= 0 ? firstUpcomingIndex : _activeSectionIndex);

    if (newIndex != _activeSectionIndex) {
      setState(() {
        _activeSectionIndex = newIndex;
      });
    }
  }

  String? _extractLastUpdated(String markdown) {
    final match = RegExp(r'\*\*Last Updated:\*\*\s*(.+)').firstMatch(markdown);
    return match?.group(1)?.trim();
  }

  _ParsedMarkdown _parseSections(String markdown) {
    final sectionRegex = RegExp(r'^##\s+(.+)$', multiLine: true);
    final matches = sectionRegex.allMatches(markdown).toList();

    if (matches.isEmpty) {
      return _ParsedMarkdown(intro: markdown, sections: const []);
    }

    final intro = markdown.substring(0, matches.first.start).trim();
    final sections = <_MarkdownSection>[];

    for (var i = 0; i < matches.length; i++) {
      final current = matches[i];
      final start = current.end;
      final end = i + 1 < matches.length
          ? matches[i + 1].start
          : markdown.length;
      final title = (current.group(1) ?? '').trim();
      final content = markdown.substring(start, end).trim();

      sections.add(
        _MarkdownSection(title: title, content: content, key: GlobalKey()),
      );
    }

    return _ParsedMarkdown(intro: intro, sections: sections);
  }
}

class _ParsedMarkdown {
  const _ParsedMarkdown({required this.intro, required this.sections});

  final String intro;
  final List<_MarkdownSection> sections;
}

class _MarkdownSection {
  const _MarkdownSection({
    required this.title,
    required this.content,
    required this.key,
  });

  final String title;
  final String content;
  final GlobalKey key;
}
