import 'package:flutter/material.dart';
import 'package:flutter_playground/FAppBar.dart';
import 'package:flutter_playground/color_scheme.dart';
import 'package:flutter_playground/example_data.dart';
import 'package:rect_getter/rect_getter.dart';
import 'package:scroll_to_index/scroll_to_index.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  bool isCollapsed = false;

  late AutoScrollController scrollController;
  late TabController tabController;

  final double expandedHeight = 500.0;

  final PageData data = ExampleData.data;

  final double collapsedHeight = kToolbarHeight;

  final wholePage = RectGetter.createGlobalKey();
  Map<int, dynamic> itemKeys = {};

  bool pauseRectGetterIndex = false;

  @override
  void initState() {
    tabController = TabController(length: data.categories.length, vsync: this);
    scrollController = AutoScrollController();
    super.initState();
  }

  @override
  void dispose() {
    scrollController.dispose();
    tabController.dispose();
    super.dispose();
  }

  List<int> getVisibleItemsIndex() {
    Rect? rect = RectGetter.getRectFromKey(wholePage);
    List<int> items = [];
    if (rect == null) return items;

    itemKeys.forEach((index, key) {
      Rect? itemRect = RectGetter.getRectFromKey(key);
      if (itemRect == null) return;
      if (itemRect.top > rect.bottom) return;
      if (itemRect.bottom < rect.top) return;
      items.add(index);
    });
    return items;
  }

  void onCollapsed(bool value) {
    if (this.isCollapsed == value) return;
    setState(() {
      this.isCollapsed = value;
    });
  }

  bool onScrollNotification(ScrollNotification notification) {
    if (pauseRectGetterIndex) return true;
    int lastTabIndex = tabController.length - 1;
    List<int> visibleItems = this.getVisibleItemsIndex();

    bool reachLastTabIndex = visibleItems.isNotEmpty &&
        visibleItems.length <= 2 &&
        visibleItems.last == lastTabIndex;

    if (reachLastTabIndex) {
      tabController.animateTo(lastTabIndex);
    } else {
      int sumIndex = visibleItems.reduce((value, element) => value + element);
      int middleIndex = sumIndex ~/ visibleItems.length;
      if (tabController.index != middleIndex) {
        tabController.animateTo(middleIndex);
      }
    }
    return false;
  }

  void animateAndScrollTo(int index) {
    pauseRectGetterIndex = true;
    tabController.animateTo(index);
    scrollController
        .scrollToIndex(index, preferPosition: AutoScrollPosition.begin)
        .then((value) => pauseRectGetterIndex = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: scheme.background,
      body: RectGetter(
        key: wholePage,
        child: NotificationListener<ScrollNotification>(
            child: buildSliverScrollView(),
            onNotification: onScrollNotification),
      ),
    );
  }

  Widget buildSliverScrollView() {
    return CustomScrollView(
      controller: scrollController,
      slivers: [
        buildAppBar(),
        buildBody(),
      ],
    );
  }

  SliverAppBar buildAppBar() {
    return FAppBar(
        data: data,
        context: context,
        isCollapsed: isCollapsed,
        expandedHeight: expandedHeight,
        collapsedHeight: collapsedHeight,
        onCollapsed: onCollapsed,
        onTap: (index) => animateAndScrollTo(index),
        tabController: tabController);
  }

  SliverList buildBody() {
    return SliverList(
      delegate: SliverChildListDelegate(List.generate(
          data.categories.length, (index) => buildCategoryItem(index))),
    );
  }

  Widget buildCategoryItem(int index) {
    itemKeys[index] = RectGetter.createGlobalKey();
    Category category = data.categories[index];
    return RectGetter(
        key: itemKeys[index],
        child: AutoScrollTag(
          key: ValueKey(index),
          index: index,
          controller: scrollController,
          child: CategorySection(category: category),
        ));
  }
}
