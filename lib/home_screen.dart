import 'package:flutter/material.dart';
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

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
