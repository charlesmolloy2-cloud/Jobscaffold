import 'package:flutter/material.dart';
import 'more_menu.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';

class AppNavScaffold extends StatefulWidget {
	final List<Widget> tabs;
	final List<BottomNavigationBarItem> items;
	final int initialIndex;
	final List<Widget?>? floatingActionButtons;
	final List<String>? appBarTitles;
  final List<Widget>? appBarActions;
  final Widget? topBanner;

	const AppNavScaffold({
		super.key,
		required this.tabs,
		required this.items,
		this.initialIndex = 0,
		this.floatingActionButtons,
		this.appBarTitles,
    this.appBarActions,
    this.topBanner,
	});

	@override
	State<AppNavScaffold> createState() => _AppNavScaffoldState();
}

class _AppNavScaffoldState extends State<AppNavScaffold> {
	late int _currentIndex;

	@override
	void initState() {
		super.initState();
		_currentIndex = widget.initialIndex;
	}

			@override
			Widget build(BuildContext context) {
				// Add a More tab at the end
				final tabs = List<Widget>.from(widget.tabs)
					..add(const SizedBox.shrink());
				final items = List<BottomNavigationBarItem>.from(widget.items)
					..add(const BottomNavigationBarItem(icon: Icon(Icons.more_horiz), label: 'More'));
				final List<String>? appBarTitles = widget.appBarTitles != null
					? (List<String>.from(widget.appBarTitles!)..add('More'))
					: null;

					return LayoutBuilder(
					builder: (context, constraints) {
						final wide = constraints.maxWidth > 900;
						return Scaffold(
								appBar: appBarTitles != null
										? AppBar(
												title: Text(appBarTitles[_currentIndex]),
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
												if (widget.topBanner != null) widget.topBanner!,
												Expanded(
													child: IndexedStack(
														index: _currentIndex,
														children: tabs,
													),
												),
											],
										),
									),
								),
							floatingActionButton: widget.floatingActionButtons != null && _currentIndex < widget.floatingActionButtons!.length
									? Padding(
											padding: EdgeInsets.only(
												right: wide ? (constraints.maxWidth - 900) / 2 : 0,
											),
											child: widget.floatingActionButtons![_currentIndex],
										)
									: null,
							bottomNavigationBar: BottomNavigationBar(
								currentIndex: _currentIndex,
								items: items
										.map((item) => BottomNavigationBarItem(
															icon: Semantics(
																label: item.label,
																child: item.icon,
															),
															label: item.label,
														))
										.toList(),
								onTap: (i) {
									if (i == items.length - 1) {
										// Show More menu as modal bottom sheet
										showModalBottomSheet(
											context: context,
											builder: (_) => const MoreMenu(),
											isScrollControlled: true,
										);
									} else {
										setState(() => _currentIndex = i);
									}
								},
								type: BottomNavigationBarType.fixed,
							),
						);
					},
				);
			}
}
