// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

void main() {
  testWidgets('AnimatedCrossFade test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const Center(
        child: const AnimatedCrossFade(
          firstChild: const SizedBox(
            width: 100.0,
            height: 100.0
          ),
          secondChild: const SizedBox(
            width: 200.0,
            height: 200.0
          ),
          duration: const Duration(milliseconds: 200),
          crossFadeState: CrossFadeState.showFirst
        )
      )
    );

    expect(find.byType(FadeTransition), findsNWidgets(2));
    RenderBox box = tester.renderObject(find.byType(AnimatedCrossFade));
    expect(box.size.width, equals(100.0));
    expect(box.size.height, equals(100.0));

    await tester.pumpWidget(
      const Center(
        child: const AnimatedCrossFade(
          firstChild: const SizedBox(
            width: 100.0,
            height: 100.0
          ),
          secondChild: const SizedBox(
            width: 200.0,
            height: 200.0
          ),
          duration: const Duration(milliseconds: 200),
          crossFadeState: CrossFadeState.showSecond
        )
      )
    );

    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(FadeTransition), findsNWidgets(2));
    box = tester.renderObject(find.byType(AnimatedCrossFade));
    expect(box.size.width, equals(150.0));
    expect(box.size.height, equals(150.0));
  });

  testWidgets('AnimatedCrossFade test showSecond', (WidgetTester tester) async {
    await tester.pumpWidget(
      const Center(
        child: const AnimatedCrossFade(
          firstChild: const SizedBox(
            width: 100.0,
            height: 100.0
          ),
          secondChild: const SizedBox(
            width: 200.0,
            height: 200.0
          ),
          duration: const Duration(milliseconds: 200),
          crossFadeState: CrossFadeState.showSecond
        )
      )
    );

    expect(find.byType(FadeTransition), findsNWidgets(2));
    final RenderBox box = tester.renderObject(find.byType(AnimatedCrossFade));
    expect(box.size.width, equals(200.0));
    expect(box.size.height, equals(200.0));
  });

  testWidgets('AnimatedCrossFade alignment', (WidgetTester tester) async {
    final Key firstKey = new UniqueKey();
    final Key secondKey = new UniqueKey();

    await tester.pumpWidget(
      new Center(
        child: new AnimatedCrossFade(
          alignment: FractionalOffset.bottomRight,
          firstChild: new SizedBox(
            key: firstKey,
            width: 100.0,
            height: 100.0
          ),
          secondChild: new SizedBox(
            key: secondKey,
            width: 200.0,
            height: 200.0
          ),
          duration: const Duration(milliseconds: 200),
          crossFadeState: CrossFadeState.showFirst
        )
      )
    );

    await tester.pumpWidget(
      new Center(
        child: new AnimatedCrossFade(
          alignment: FractionalOffset.bottomRight,
          firstChild: new SizedBox(
            key: firstKey,
            width: 100.0,
            height: 100.0
          ),
          secondChild: new SizedBox(
            key: secondKey,
            width: 200.0,
            height: 200.0
          ),
          duration: const Duration(milliseconds: 200),
          crossFadeState: CrossFadeState.showSecond
        )
      )
    );

    await tester.pump(const Duration(milliseconds: 100));

    final RenderBox box1 = tester.renderObject(find.byKey(firstKey));
    final RenderBox box2 = tester.renderObject(find.byKey(secondKey));
    expect(box1.localToGlobal(Offset.zero), const Offset(275.0, 175.0));
    expect(box2.localToGlobal(Offset.zero), const Offset(275.0, 175.0));
  });

  Widget crossFadeWithWatcher({bool towardsSecond: false}) {
    return new AnimatedCrossFade(
      firstChild: const _TickerWatchingWidget(),
      secondChild: new Container(),
      crossFadeState: towardsSecond ? CrossFadeState.showSecond : CrossFadeState.showFirst,
      duration: const Duration(milliseconds: 50),
    );
  }

  testWidgets('AnimatedCrossFade preserves widget state', (WidgetTester tester) async {
    await tester.pumpWidget(crossFadeWithWatcher());

    _TickerWatchingWidgetState findState() => tester.state(find.byType(_TickerWatchingWidget));
    final _TickerWatchingWidgetState state = findState();

    await tester.pumpWidget(crossFadeWithWatcher(towardsSecond: true));
    for (int i = 0; i < 3; i += 1) {
      await tester.pump(const Duration(milliseconds: 25));
      expect(findState(), same(state));
    }
  });

  testWidgets('AnimatedCrossFade switches off TickerMode and semantics on faded out widget', (WidgetTester tester) async {
    ExcludeSemantics findSemantics() {
      return tester.widget(find.descendant(
        of: find.byKey(const ValueKey<CrossFadeState>(CrossFadeState.showFirst)),
        matching: find.byType(ExcludeSemantics),
      ));
    }

    await tester.pumpWidget(crossFadeWithWatcher());

    final _TickerWatchingWidgetState state = tester.state(find.byType(_TickerWatchingWidget));
    expect(state.ticker.muted, false);
    expect(findSemantics().excluding, false);

    await tester.pumpWidget(crossFadeWithWatcher(towardsSecond: true));
    for (int i = 0; i < 2; i += 1) {
      await tester.pump(const Duration(milliseconds: 25));
      // Animations are kept alive in the middle of cross-fade
      expect(state.ticker.muted, false);
      // Semantics are turned off immediately on the widget that's fading out
      expect(findSemantics().excluding, true);
    }

    // In the final state both animations and semantics should be off on the
    // widget that's faded out.
    await tester.pump(const Duration(milliseconds: 25));
    expect(state.ticker.muted, true);
    expect(findSemantics().excluding, true);
  });
}

class _TickerWatchingWidget extends StatefulWidget {
  const _TickerWatchingWidget();

  @override
  State<StatefulWidget> createState() => new _TickerWatchingWidgetState();
}

class _TickerWatchingWidgetState extends State<_TickerWatchingWidget> with SingleTickerProviderStateMixin {
  Ticker ticker;

  @override
  void initState() {
    super.initState();
    ticker = createTicker((_) {})..start();
  }

  @override
  Widget build(BuildContext context) => new Container();

  @override
  void dispose() {
    ticker.dispose();
    super.dispose();
  }
}
