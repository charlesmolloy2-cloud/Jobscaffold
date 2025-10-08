import 'package:flutter/material.dart';
import 'more_menu.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';

class AppNavScaffold extends StatefulWidget {
  final List<Widget> tabs; // logical tabs (without More)
  final List<BottomNavigationBarItem> items; // logical items (without More)
  final int initialIndex; // logical index
  final List<Widget?>? floatingActionButtons; // logical FABs
  final List<String>? appBarTitles; // logical titles
  final List<Widget>? appBarActions;
  final Widget? topBanner;
  final List<Widget?>? topBanners; // logical per-tab banners
  final ValueChanged<int>? onTabChanged; // logical index callback
  final bool includeMoreTab; // insert a More tab
  final int? moreTabIndex; // where to insert More among logical tabs (default end)
  final double bottomNavIconSize; // to allow smaller icons

  const AppNavScaffold({
    super.key,
    required this.tabs,
    required this.items,
    this.initialIndex = 0,
    this.floatingActionButtons,
    this.appBarTitles,
    this.appBarActions,
    this.topBanner,
    this.topBanners,
    this.onTabChanged,
    this.includeMoreTab = true,
    this.moreTabIndex,
    this.bottomNavIconSize = 24,
  });

  @override
  State<AppNavScaffold> createState() => _AppNavScaffoldState();
}

class _AppNavScaffoldState extends State<AppNavScaffold> {
  late int _currentIndex; // actual index (including More if present)

  @override
  void initState() {
    super.initState();
    // Map initial logical index to actual index by accounting for More position
    final baseLen = widget.items.length;
    final desiredMore = widget.moreTabIndex ?? baseLen;
    final moreIndex = widget.includeMoreTab ? desiredMore.clamp(0, baseLen) : null;
    int actualFromLogical(int logical) => moreIndex == null ? logical : (logical >= moreIndex ? logical + 1 : logical);
    _currentIndex = actualFromLogical(widget.initialIndex);
  }

  @override
  Widget build(BuildContext context) {
    // Base logical lists
    final baseTabs = List<Widget>.from(widget.tabs);
    final baseItems = List<BottomNavigationBarItem>.from(widget.items);
    final List<String>? baseTitles = widget.appBarTitles != null ? List<String>.from(widget.appBarTitles!) : null;

    // Compute More position among logical tabs
    int? moreIndex;
    if (widget.includeMoreTab) {
      final desired = widget.moreTabIndex ?? baseItems.length; // default end
      moreIndex = desired.clamp(0, baseItems.length);
    }

    // Build actual lists with optional More
    final tabs = <Widget>[];
    final items = <BottomNavigationBarItem>[];
    final List<String>? appBarTitles = baseTitles != null ? <String>[] : null;
    for (int i = 0; i < baseTabs.length; i++) {
      if (moreIndex != null && i == moreIndex) {
        tabs.add(const SizedBox.shrink());
        items.add(const BottomNavigationBarItem(icon: Icon(Icons.more_horiz), label: 'More'));
        if (appBarTitles != null) appBarTitles.add('More');
      }
      tabs.add(baseTabs[i]);
      items.add(baseItems[i]);
      if (appBarTitles != null) appBarTitles.add(baseTitles![i]);
    }
    if (moreIndex != null && moreIndex == baseTabs.length) {
      tabs.add(const SizedBox.shrink());
      items.add(const BottomNavigationBarItem(icon: Icon(Icons.more_horiz), label: 'More'));
      if (appBarTitles != null) appBarTitles.add('More');
    }

    int logicalFromActual(int actual) => moreIndex == null ? actual : (actual > moreIndex ? actual - 1 : actual);

    // Ensure current selection doesn't land on More
    int safeCurrentIndex = _currentIndex.clamp(0, items.length - 1);
    if (moreIndex != null && safeCurrentIndex == moreIndex) {
      safeCurrentIndex = (safeCurrentIndex + 1).clamp(0, items.length - 1);
    }
    final logicalIndex = logicalFromActual(safeCurrentIndex);

    // Resolve active top banner (logical)
    Widget? activeTopBanner;
    if (widget.topBanners != null && logicalIndex < widget.topBanners!.length) {
      activeTopBanner = widget.topBanners![logicalIndex];
    }
    activeTopBanner ??= widget.topBanner;

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth > 900;
        return Scaffold(
          appBar: appBarTitles != null
              ? AppBar(
                  title: Text(appBarTitles[safeCurrentIndex]),
                  actions: [
                    ...(widget.appBarActions ?? const []),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'reduce_motion') {
                          final appState = context.read<AppState>();
                          appState.setReduceMotion(!appState.reduceMotion);
                        }
                      },
                      itemBuilder: (context) {
                        final reduce = context.select<AppState, bool>((s) => s.reduceMotion);
                        return [
                          CheckedPopupMenuItem<String>(
                            value: 'reduce_motion',
                            checked: reduce,
                            child: const Text('Reduce motion'),
                          ),
                        ];
                      },
                    ),
                  ],
                )
              : null,
          body: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: wide ? 900 : double.infinity),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (activeTopBanner != null) activeTopBanner,
                  Expanded(
                    child: IndexedStack(
                      index: safeCurrentIndex,
                      children: tabs,
                    ),
                  ),
                ],
              ),
            ),
          ),
          floatingActionButton: (widget.floatingActionButtons != null && logicalIndex < widget.floatingActionButtons!.length)
              ? Padding(
                  padding: EdgeInsets.only(
                    right: wide ? (constraints.maxWidth - 900) / 2 : 0,
                  ),
                  child: widget.floatingActionButtons![logicalIndex],
                )
              : null,
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: safeCurrentIndex,
            iconSize: widget.bottomNavIconSize,
            items: items
                .map((item) => BottomNavigationBarItem(
                      icon: Semantics(label: item.label, child: item.icon),
                      label: item.label,
                    ))
                .toList(),
            onTap: (i) {
              if (moreIndex != null && i == moreIndex) {
                showModalBottomSheet(
                  context: context,
                  builder: (_) => const MoreMenu(),
                  isScrollControlled: true,
                );
              } else {
                setState(() => _currentIndex = i);
                widget.onTabChanged?.call(logicalFromActual(i));
              }
            },
            type: BottomNavigationBarType.fixed,
          ),
        );
      },
    );
  }
}
