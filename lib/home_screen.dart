import 'package:flutter/material.dart';
import 'package:flutter_playground/FAppBar.dart';
import 'package:flutter_playground/color_scheme.dart';
import 'package:flutter_playground/example_data.dart';
import 'package:rect_getter/rect_getter.dart';
import 'package:scroll_to_index/scroll_to_index.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  /// 使否展開
  bool isCollapsed = false;
  late AutoScrollController scrollController;
  late TabController tabController;

  /// 展開高度
  final double expandedHeight = 500.0;

  /// 頁面資料
  final PageData data = ExampleData.data;

  /// 折疊高度
  final double collapsedHeight = kToolbarHeight;

  /// Instantiate RectGetter
  final wholePage = RectGetter.createGlobalKey();
  Map<int, dynamic> itemKeys = {};

  /// prevent animate when press on tab bar
  /// 避免當我們點擊 tab bar 時，動畫還在動，還在計算。
  bool pauseRectGetterIndex = false;

  @override
  void initState() {
    /// tabController 出使話
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

  /// 取得螢幕可看到的 index 有哪些
  List<int> getVisibleItemsIndex() {
    // get ListView Rect
    Rect? rect = RectGetter.getRectFromKey(wholePage);
    List<int> items = [];
    if (rect == null) return items;
    itemKeys.forEach((index, key) {
      Rect? itemRect = RectGetter.getRectFromKey(key);
      if (itemRect == null) return;
      // y 軸座越大，代表越下面
      // 如果 item 上方的座標 比 listView 的下方的座標 的位置的大 代表不在畫面中。
      // bottom meaning => The offset of the bottom edge of this widget from the y axis.
      // top meaning => The offset of the top edge of this widget from the y axis.
      if (itemRect.top > rect.bottom) return;
      // 如果 item 下方的座標 比 listView 的上方的座標 的位置的小 代表不在畫面中。
      if (itemRect.bottom < rect.top) return;
      items.add(index);
    });

    return items;
  }

  /// 用來傳遞給 appBar 的 function
  void onCollapsed(bool value) {
    if (this.isCollapsed == value) return;
    setState(() => this.isCollapsed = value);
  }

  /// true表示消費掉當前通知不再向上一级NotificationListener傳遞通知，false則會再向上一级NotificationListener傳遞通知；
  bool onScrollNotification(ScrollNotification notification) {
    //print(notification.metrics.outOfRange);
    // 不想讓上一層知道，無需做動作。
    if (pauseRectGetterIndex) return true;
    // 取得標籤的長度
    int lastTabIndex = tabController.length - 1;
    // 取得現在畫面上可以看得到的 Items Index
    List<int> visibleItems = getVisibleItemsIndex();
    bool reachLastTabIndex = visibleItems.isNotEmpty &&
        visibleItems.last == lastTabIndex &&
        scrollController.position.pixels >=
            scrollController.position.maxScrollExtent;
    // 如果到達最後一個 index 就跳轉到最後一個 index
    if (reachLastTabIndex) {
      tabController.animateTo(lastTabIndex);
    } else {
      // 取得畫面中的 item 的中間值。例：2,3,4 中間的就是 3
      // 求一個數字列表的乘積
      int sumIndex = visibleItems.reduce((value, element) => value + element);
      // 5 ~/ 2 = 2  => Result is an int 取整數
      int middleIndex = sumIndex ~/ visibleItems.length;
      if (tabController.index != middleIndex)
        tabController.animateTo(middleIndex);
    }
    return false;
  }

  /// TabBar 的動畫。
  void animateAndScrollTo(int index) {
    pauseRectGetterIndex = true;
    tabController.animateTo(index);
    // Scroll 到 index 並使用 begin 的模式，結束後，把 pauseRectGetterIndex 設為 false 暫停執行 ScrollNotification
    scrollController
        .scrollToIndex(index, preferPosition: AutoScrollPosition.begin)
        .then((value) => pauseRectGetterIndex = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true, //是否延伸body至顶部。
      backgroundColor: scheme.background,
      body: RectGetter(
        key: wholePage,

        /// NotificationListener 是一個由下往上傳遞通知，true 阻止通知、false 傳遞通知，確保指監聽滾動的通知
        /// ScrollNotification => https://www.jianshu.com/p/d80545454944
        child: NotificationListener<ScrollNotification>(
          child: buildSliverScrollView(),
          onNotification: onScrollNotification,
        ),
      ),
    );
  }

  /// CustomScrollView + SliverList + SliverAppBar
  Widget buildSliverScrollView() {
    return CustomScrollView(
      controller: scrollController,
      slivers: [
        buildAppBar(),
        buildBody(),
      ],
    );
  }

  /// AppBar
  SliverAppBar buildAppBar() {
    return FAppBar(
      data: data,
      context: context,
      expandedHeight: expandedHeight,
      // 期許展開的高度
      collapsedHeight: collapsedHeight,
      // 折疊高度
      isCollapsed: isCollapsed,
      onCollapsed: onCollapsed,
      tabController: tabController,
      onTap: (index) => animateAndScrollTo(index),
    );
  }

  /// Body
  SliverList buildBody() {
    return SliverList(
      delegate: SliverChildListDelegate(List.generate(
        data.categories.length,
        (index) {
          return buildCategoryItem(index);
        },
      )),
    );
  }

  /// ListItem
  Widget buildCategoryItem(int index) {
    // 建立 itemKeys 的 Key
    itemKeys[index] = RectGetter.createGlobalKey();
    Category category = data.categories[index];
    return RectGetter(
      // 傳GlobalKey，之後可以 RectGetter.getRectFromKey(key) 的方式獲得 Rect
      key: itemKeys[index],
      child: AutoScrollTag(
        key: ValueKey(index),
        index: index,
        controller: scrollController,
        child: CategorySection(category: category),
      ),
    );
  }
}

/// 每一個 Category Section 的樣子。
class CategorySection extends StatelessWidget {
  TextTheme _textTheme(context) => Theme.of(context).textTheme;

  const CategorySection({
    Key? key,
    required this.category,
  }) : super(key: key);

  final Category category;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      margin: const EdgeInsets.only(bottom: 16),
      color: scheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTileHeader(context),
          _buildFoodTileList(context),
        ],
      ),
    );
  }

  /// Section Title
  Widget _buildFoodTileList(BuildContext context) {
    return Column(
      children: List.generate(
        category.foods.length,
        (index) {
          final food = category.foods[index];
          bool isLastIndex = index == category.foods.length - 1;
          return _buildFoodTile(
            food: food,
            context: context,
            isLastIndex: isLastIndex,
          );
        },
      ),
    );
  }

  /// FSection Header
  Widget _buildSectionTileHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        _sectionTitle(context),
        const SizedBox(height: 8.0),
        category.subtitle != null
            ? _sectionSubtitle(context)
            : const SizedBox(),
        const SizedBox(height: 16),
      ],
    );
  }

  /// Section Title 的 title
  Widget _sectionTitle(BuildContext context) {
    return Row(
      children: [
        if (category.isHotSale) _buildSectionHotSaleIcon(),
        Text(
          category.title,
          style: _textTheme(context).headline6,
          strutStyle: Helper.buildStrutStyle(_textTheme(context).headline6),
          // strutStyle: Helper.buildStrutStyle(_textTheme(context).headline6),
        )
      ],
    );
  }

  /// section Title 的 subTitle
  Widget _sectionSubtitle(BuildContext context) {
    return Text(
      category.subtitle!,
      style: _textTheme(context).subtitle2,
      strutStyle: Helper.buildStrutStyle(_textTheme(context).subtitle2),
    );
  }

  /// Section body 的 Food 樣式。
  Widget _buildFoodTile({
    required BuildContext context,
    required bool isLastIndex,
    required Food food,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildFoodDetail(food: food, context: context),
            _buildFoodImage(food.imageUrl),
          ],
        ),
        !isLastIndex ? const Divider(height: 16.0) : const SizedBox(height: 8.0)
      ],
    );
  }

  /// food Image
  Widget _buildFoodImage(String url) {
    return FadeInImage.assetNetwork(
      placeholder: 'images/transparent.png',
      image: url,
      width: 64,
    );
  }

  /// food Detail
  Widget _buildFoodDetail({
    required BuildContext context,
    required Food food,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(food.name, style: _textTheme(context).subtitle1),
        const SizedBox(height: 16),
        Row(
          children: [
            Text(
              "特價" + food.price + " ",
              style: _textTheme(context).caption,
              strutStyle: Helper.buildStrutStyle(_textTheme(context).caption),
            ),
            Text(
              food.comparePrice,
              strutStyle: Helper.buildStrutStyle(_textTheme(context).caption),
              style: _textTheme(context)
                  .caption
                  ?.copyWith(decoration: TextDecoration.lineThrough),
            ),
            const SizedBox(width: 8.0),
            if (food.isHotSale) _buildFoodHotSaleIcon(),
          ],
        ),
      ],
    );
  }

  /// Section HotSale Icon
  Widget _buildSectionHotSaleIcon() {
    return Container(
      margin: const EdgeInsets.only(right: 4.0),
      child: Icon(
        Icons.whatshot,
        color: scheme.primary,
        size: 20.0,
      ),
    );
  }

  /// Food HotSale Icon
  Widget _buildFoodHotSaleIcon() {
    return Container(
      child: Icon(Icons.whatshot, color: scheme.primary, size: 16.0),
      padding: const EdgeInsets.all(4.0),
      decoration: BoxDecoration(
        color: scheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16.0),
      ),
    );
  }
}

/// 餐廳的圖片形狀
class CustomShape extends CustomClipper<Path> {
  @override
  getClip(Size size) {
    double height = size.height;
    double width = size.width;
    var path = Path();
    path.lineTo(0, height - 30);
    path.quadraticBezierTo(width / 2, height, width, height - 30);
    path.lineTo(width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper oldClipper) => true;
}

/// 折扣卡片
class DiscountCard extends StatelessWidget {
  const DiscountCard({
    Key? key,
    required this.title,
    required this.subtitle,
  }) : super(key: key);

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    var textTheme = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 16.0,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 20,
      ),
      decoration: BoxDecoration(
        color: scheme.primary,
        borderRadius: BorderRadius.circular(10.0),
        image: DecorationImage(
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            scheme.primary.withOpacity(0.08),
            BlendMode.dstATop,
          ),
          image: AssetImage('images/pattern.png'),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: textTheme.subtitle1
                ?.copyWith(color: scheme.surface, fontWeight: FontWeight.w600),
          ),
          Text(
            subtitle,
            style: textTheme.bodyText2?.copyWith(
              color: scheme.surface,
            ),
          ),
        ],
      ),
    );
  }
}

/// AppBar 的按鈕
class FIconButton extends StatelessWidget {
  const FIconButton({
    Key? key,
    required this.iconData,
    required this.onPressed,
  }) : super(key: key);

  final IconData iconData;
  final void Function() onPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: IconButton(
        splashColor: Colors.transparent,
        onPressed: () => onPressed,
        icon: Container(
          height: 48,
          width: 48,
          decoration: buildBoxDecoration(),
          child: Icon(
            iconData,
            color: scheme.primary,
            size: 20,
          ),
        ),
      ),
    );
  }

  BoxDecoration buildBoxDecoration() {
    return BoxDecoration(
      shape: BoxShape.circle,
      color: scheme.surface,
    );
  }
}

/// App 餐廳圖片的地方
class HeaderClip extends StatelessWidget {
  const HeaderClip({
    Key? key,
    required this.data,
    required this.context,
  }) : super(key: key);

  final PageData data;
  final BuildContext context;

  @override
  Widget build(BuildContext _) {
    final textTheme = Theme.of(context).textTheme;
    return ClipPath(
      clipper: CustomShape(),
      child: Stack(
        children: [
          Container(
            height: 275,
            color: scheme.primary.withOpacity(0.3),
            child: FadeInImage.assetNetwork(
              placeholder: 'images/transparent.png',
              image: data.backgroundUrl,
              width: double.infinity,
              fit: BoxFit.fitWidth,
            ),
          ),
          // 目的 讓顏色變暗。
          Container(
            height: 275,
            color: scheme.secondary.withOpacity(0.7),
          ),
          Padding(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).viewPadding.top + kToolbarHeight,
            ),
            child: Column(
              children: [
                Text(
                  data.title,
                  style: textTheme.headline5?.copyWith(
                    color: scheme.surface,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8.0),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 4.0,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: scheme.surface),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Text(
                      "抵達時間: " + data.deliverTime,
                      style: textTheme.caption?.copyWith(color: scheme.surface),
                      strutStyle: StrutStyle(forceStrutHeight: true),
                    ),
                  ),
                ),
                const SizedBox(height: 8.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.star_rate_rounded,
                      size: 16,
                      color: scheme.surface,
                    ),
                    const SizedBox(width: 4.0),
                    Text(
                      data.rate.toString(),
                      style: textTheme.caption?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: scheme.surface,
                      ),
                    ),
                    const SizedBox(width: 4.0),
                    Text(
                      "(" + data.rateQuantity.toString() + ")",
                      style: textTheme.caption?.copyWith(
                        color: scheme.surface,
                      ),
                    ),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}

/// 宣傳框
class PromoText extends StatelessWidget {
  const PromoText({
    Key? key,
    required this.title,
  }) : super(key: key);

  final String title;
  @override
  Widget build(BuildContext context) {
    var textTheme = Theme.of(context).textTheme;
    // 這邊是距離上一層的 Stack 的 bottom left right
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 48,
        ),
        width: double.infinity,
        color: scheme.primary.withOpacity(0.1),
        child: Text(
          title,
          style: textTheme.bodyText1?.copyWith(color: scheme.primary),
        ),
      ),
    );
  }
}

class Helper {
  Helper._internal();

  static StrutStyle buildStrutStyle(TextStyle? textStyle) {
    return StrutStyle(
      forceStrutHeight: true,
      fontWeight: textStyle?.fontWeight,
      fontSize: textStyle?.fontSize,
      fontFamily: textStyle?.fontFamily,
      fontStyle: textStyle?.fontStyle,
      fontFamilyFallback: textStyle?.fontFamilyFallback,
      debugLabel: textStyle?.debugLabel,
    );
  }
}
