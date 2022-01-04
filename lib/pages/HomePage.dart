import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:fyx/FyxApp.dart';
import 'package:fyx/components/Avatar.dart' as ca;
import 'package:fyx/components/DiscussionListItem.dart';
import 'package:fyx/components/ListHeader.dart';
import 'package:fyx/components/NotificationBadge.dart';
import 'package:fyx/components/PullToRefreshList.dart';
import 'package:fyx/controllers/AnalyticsProvider.dart';
import 'package:fyx/controllers/ApiController.dart';
import 'package:fyx/model/BookmarkedDiscussion.dart';
import 'package:fyx/model/MainRepository.dart';
import 'package:fyx/model/enums/DefaultView.dart';
import 'package:fyx/model/provider/NotificationsModel.dart';
import 'package:fyx/pages/MailboxPage.dart';
import 'package:fyx/theme/L.dart';
import 'package:fyx/theme/T.dart';
import 'package:fyx/theme/skin/Skin.dart';
import 'package:fyx/theme/skin/SkinColors.dart';
import 'package:provider/provider.dart';

enum ETabs { history, bookmarks }
enum ERefreshData { bookmarks, mail, all }

class HomePageArguments {
  final pageIndex;

  HomePageArguments(this.pageIndex);
}

class HomePage extends StatefulWidget {
  static const int SCREEN_BOOKMARKS = 0;
  static const int SCREEN_MAILBOX = 1;

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with RouteAware, WidgetsBindingObserver {
  late final PageController bookmarkTabsController;
  late final PageController screenController;

  ETabs activeTab = ETabs.history;
  int _screenId = 0;
  Map<String, int> _refreshData = {'bookmarks': 0, 'mail': 0};
  bool _filterUnread = false;
  DefaultView _defaultView = DefaultView.history;
  List<int> _toggledCategories = [];
  HomePageArguments? _arguments;
  bool _historySearch = false;
  String _historySearchTerm = '';
  bool _bookmarksSearch = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance?.addObserver(this);

    _defaultView =
        MainRepository().settings.defaultView == DefaultView.latest ? MainRepository().settings.latestView : MainRepository().settings.defaultView;
    _filterUnread = [DefaultView.bookmarksUnread, DefaultView.historyUnread].indexOf(_defaultView) >= 0;

    activeTab = [DefaultView.history, DefaultView.historyUnread].indexOf(_defaultView) >= 0 ? ETabs.history : ETabs.bookmarks;

    screenController = PageController(initialPage: 0);

    bookmarkTabsController = PageController(initialPage: activeTab == ETabs.history ? 0 : 1);
    bookmarkTabsController.addListener(() {
      this.updateLatestView();

      if (bookmarkTabsController.position.userScrollDirection == ScrollDirection.idle) {
        // Tap on SegmentedControl changes the activeTab itself
        return;
      }
      if (bookmarkTabsController.position.userScrollDirection == ScrollDirection.forward && bookmarkTabsController.page! < .5) {
        // If the drag is towards history, change the activeTab to update SegmentedControl
        setState(() => activeTab = ETabs.history);
      } else if (bookmarkTabsController.position.userScrollDirection == ScrollDirection.reverse && bookmarkTabsController.page! >= .5) {
        // Other way around
        setState(() => activeTab = ETabs.bookmarks);
      }
    });

    // Request for push notifications
    MainRepository().notifications.request();

    AnalyticsProvider().setUser(MainRepository().credentials!.nickname);
    AnalyticsProvider().setUserProperty('photoWidth', MainRepository().settings.photoWidth.toString());
    AnalyticsProvider().setUserProperty('photoQuality', MainRepository().settings.photoQuality.toString());
    AnalyticsProvider().setUserProperty('autocorrect', MainRepository().settings.useAutocorrect.toString());
    AnalyticsProvider().setUserProperty('compactMode', MainRepository().settings.useCompactMode.toString());
    AnalyticsProvider().setUserProperty('defaultView', MainRepository().settings.defaultView.toString());
    AnalyticsProvider().setUserProperty('blockedMails', MainRepository().settings.blockedMails.length.toString());
    AnalyticsProvider().setUserProperty('blockedPosts', MainRepository().settings.blockedPosts.length.toString());
    AnalyticsProvider().setUserProperty('blockedUsers', MainRepository().settings.blockedUsers.length.toString());
    AnalyticsProvider().setScreen('Home', 'HomePage');
  }

  @override
  void dispose() {
    bookmarkTabsController.dispose();
    screenController.dispose();
    FyxApp.routeObserver.unsubscribe(this);
    WidgetsBinding.instance?.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // If we omit the Route check, there's very rare issue during authorization
    // See: https://github.com/lucien144/fyx/issues/57
    if (state == AppLifecycleState.resumed && ModalRoute.of(context)!.isCurrent) {
      this.refreshData(_screenId == HomePage.SCREEN_MAILBOX ? ERefreshData.mail : ERefreshData.bookmarks);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    FyxApp.routeObserver.subscribe(this, ModalRoute.of(context));
  }

  // Called when the current route has been pushed.
  void didPopNext() {
    this.refreshData(ERefreshData.bookmarks);
  }

  void didPush() {
    // Called when the current route has been pushed.
  }

  void didPop() {
    // Called when the current route has been popped off.
  }

  void didPushNext() {
    // Called when a new route has been pushed, and the current route is no longer visible.
  }

  void refreshData(ERefreshData type) {
    setState(() {
      switch (type) {
        case ERefreshData.bookmarks:
          _refreshData['bookmarks'] = DateTime.now().millisecondsSinceEpoch;
          break;
        case ERefreshData.mail:
          _refreshData['mail'] = DateTime.now().millisecondsSinceEpoch;
          break;
        default:
          _refreshData['bookmarks'] = DateTime.now().millisecondsSinceEpoch;
          _refreshData['mail'] = DateTime.now().millisecondsSinceEpoch;
          break;
      }
    });
  }

  Widget actionSheet(BuildContext context) {
    return CupertinoActionSheet(
        title: Text('Přihlášen jako: ${MainRepository().credentials!.nickname}'),
        actions: <Widget>[
          CupertinoActionSheetAction(
              child: Text(L.SETTINGS),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context, rootNavigator: true).pushNamed('/settings');
              }),
          CupertinoActionSheetAction(
              child: Text('⚠️ ${L.SETTINGS_BUGREPORT}'),
              onPressed: () {
                T.prefillGithubIssue(appContext: MainRepository(), user: MainRepository().credentials!.nickname);
                AnalyticsProvider().logEvent('reportBug');
              }),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          child: Text(L.GENERAL_CANCEL),
          onPressed: () {
            Navigator.pop(context);
          },
        ));
  }

  @override
  Widget build(BuildContext context) {
    if (ApiController().buildContext == null || ApiController().buildContext.hashCode != context.hashCode) {
      ApiController().buildContext = context;
    }

    final Object? _objArguments = ModalRoute.of(context)?.settings.arguments;
    if (_objArguments != null) {
      _arguments = _objArguments as HomePageArguments;
      _screenId = _arguments?.pageIndex;
    }

    return WillPopScope(
        onWillPop: () async => false,
        child: Column(
          children: [
            Expanded(
                child: PageView(
              scrollBehavior: CupertinoScrollBehavior(),
              physics: NeverScrollableScrollPhysics(),
              children: [_buildBookmarks(context), _buildMails(context)],
              controller: screenController,
            )),
            _buildTabBar(context)
          ],
        ));
  }

  Widget _buildTabBar(BuildContext context) {
    SkinColors colors = Skin.of(context).theme.colors;

    return Container(
      height: 50 + MediaQuery.of(context).padding.bottom,
      color: colors.barBackground,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
              child: Icon(_filterUnread ? Icons.bookmarks : Icons.bookmarks_outlined,
                  size: 34, color: _screenId == HomePage.SCREEN_BOOKMARKS ? null : colors.disabled),
              onTap: () {
                setState(() {
                  // Toggle read/unread bookmarks
                  if (_screenId == HomePage.SCREEN_BOOKMARKS) {
                    _filterUnread = !_filterUnread;
                    this.refreshData(ERefreshData.bookmarks);
                  }

                  _toggledCategories = []; // Reset the category toggle
                  _screenId = HomePage.SCREEN_BOOKMARKS; // Update pageIndex

                  // Jump to the correct screen if needed
                  if (screenController.page != _screenId) {
                    screenController.jumpToPage(_screenId);
                  }

                  // Update the latest view for invoking the app on last view
                  this.updateLatestView();
                });

                // Jump to correct tab
                // TODO: Isn't there a better way to do this?
                WidgetsBinding.instance!.addPostFrameCallback((_) {
                  bookmarkTabsController.jumpToPage(activeTab == ETabs.history ? 0 : 1);
                });
              }),
          GestureDetector(
            onTap: () {
              setState(() => _screenId = HomePage.SCREEN_MAILBOX);
              screenController.jumpToPage(_screenId);
              this.refreshData(ERefreshData.mail);
            },
            child: Consumer<NotificationsModel>(
              builder: (context, notifications, child) => NotificationBadge(
                  widget: Icon(Icons.email_outlined, size: 42, color: _screenId == HomePage.SCREEN_MAILBOX ? null : colors.disabled),
                  counter: notifications.newMails,
                  isVisible: notifications.newMails > 0),
            ),
          ),
          GestureDetector(
            child: Icon(Icons.more_horiz, size: 34, color: colors.disabled),
            onTap: () => showCupertinoModalPopup(context: context, builder: (BuildContext context) => actionSheet(context)),
          )
        ],
      ),
    );
  }

  _buildBookmarks(BuildContext context) {
    return CupertinoTabView(builder: (context) {
      return CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
            leading: Consumer<NotificationsModel>(
                builder: (context, notifications, child) => NotificationBadge(
                    widget: CupertinoButton(
                        padding: EdgeInsets.zero,
                        minSize: kMinInteractiveDimensionCupertino - 10,
                        child: Icon(
                          Icons.notifications_none,
                          size: 30,
                        ),
                        onPressed: () => Navigator.of(context, rootNavigator: true).pushNamed('/notices')),
                    isVisible: notifications.newNotices > 0,
                    counter: notifications.newNotices)),
            trailing: CupertinoButton(
              padding: EdgeInsets.zero,
              minSize: kMinInteractiveDimensionCupertino - 10,
              child: Icon(
                Icons.search,
                size: 30,
              ),
              onPressed: () {
                setState(() {
                  _historySearch = activeTab == ETabs.history ? !_historySearch : _historySearch;
                  _bookmarksSearch = activeTab == ETabs.bookmarks ? !_bookmarksSearch : _bookmarksSearch;
                });
              },
            ),
            middle: CupertinoSegmentedControl(
              groupValue: activeTab,
              onValueChanged: (ETabs value) {
                setState(() => activeTab = value);
                bookmarkTabsController.animateToPage(ETabs.values.indexOf(value), duration: Duration(milliseconds: 300), curve: Curves.easeInOut);
              },
              children: {
                ETabs.history: Padding(
                  child: Text('Historie'),
                  padding: EdgeInsets.symmetric(horizontal: 16),
                ),
                ETabs.bookmarks: Padding(
                  child: Text('Sledované'),
                  padding: EdgeInsets.symmetric(horizontal: 16),
                ),
              },
            )),
        child: PageView(
          controller: bookmarkTabsController,
          onPageChanged: (int index) => this.updateLatestView(isInverted: true),
          pageSnapping: true,
          children: <Widget>[
            // -----
            // HISTORY PULL TO REFRESH
            // -----
            PullToRefreshList(
                hasSearch: _historySearch,
                onSearch: (term) => setState(() => _historySearchTerm = term),
                searchTerm: _historySearchTerm,
                searchLabel: 'Filtrovat historii',
                rebuild: _refreshData['bookmarks'] ?? 0,
                dataProvider: (lastId, searchTerm) async {
                  List<DiscussionListItem> withReplies = [];
                  var result = await ApiController().loadHistory();
                  var data = result.discussions
                      .map((discussion) => BookmarkedDiscussion.fromJson(discussion))
                      .where((discussion) => this._filterUnread ? discussion.unread > 0 : true)
                      .where((discussion) => searchTerm.length > 0 ? discussion.name.contains(RegExp(searchTerm, caseSensitive: false)) : true)
                      .map((discussion) => DiscussionListItem(discussion))
                      .where((discussionListItem) {
                    if (discussionListItem.discussion.replies > 0) {
                      withReplies.add(discussionListItem);
                      return false;
                    }
                    return true;
                  }).toList();
                  data.insertAll(0, withReplies);
                  return DataProviderResult(data);
                }),
            // -----
            // BOOKMARKS PULL TO REFRESH
            // -----
            PullToRefreshList(
                rebuild: _refreshData['bookmarks'] ?? 0,
                hasSearch: _bookmarksSearch,
                searchLabel: 'Hledat v klubech',
                dataProvider: (lastId, searchTerm) async {
                  var categories = [];
                  var result = await ApiController().loadBookmarks();

                  result.bookmarks.forEach((_bookmark) {
                    List<DiscussionListItem> withReplies = [];
                    var discussion = _bookmark.discussions
                        .where((discussion) {
                          // Filter by tapping on category headers
                          // If unread filter is ON
                          if (this._filterUnread) {
                            if (_toggledCategories.indexOf(_bookmark.categoryId) >= 0) {
                              // If unread filter is ON and category toggle is ON, display discussions
                              return true;
                            } else {
                              // If unread filter is ON and category toggle is OFF, display unread discussions only
                              return discussion.unread > 0;
                            }
                          } else {
                            if (_toggledCategories.indexOf(_bookmark.categoryId) >= 0) {
                              // If unread filter is OFF and category toggle is ON, hide discussions
                              return false;
                            }
                          }
                          // If unread filter is OFF and category toggle is OFF, show discussions
                          return true;
                        })
                        .map((discussion) => DiscussionListItem(discussion))
                        .where((discussionListItem) {
                          if (discussionListItem.discussion.replies > 0) {
                            withReplies.add(discussionListItem);
                            return false;
                          }
                          return true;
                        })
                        .toList();
                    discussion.insertAll(0, withReplies);
                    categories.add({
                      'header': ListHeader(_bookmark.categoryName, onTap: () {
                        if (_toggledCategories.indexOf(_bookmark.categoryId) >= 0) {
                          // Hide discussions in the category
                          setState(() => _toggledCategories.remove(_bookmark.categoryId));
                        } else {
                          // Show discussions in the category
                          setState(() => _toggledCategories.add(_bookmark.categoryId));
                        }
                        this.refreshData(ERefreshData.bookmarks);
                      }),
                      'items': discussion
                    });
                  });
                  return DataProviderResult(categories);
                }),
          ],
        ),
      );
    });
  }

  _buildMails(BuildContext context) {
    SkinColors colors = Skin.of(context).theme.colors;
    return CupertinoTabView(builder: (context) {
      return CupertinoPageScaffold(
          navigationBar: CupertinoNavigationBar(
              trailing: GestureDetector(
                child: ca.Avatar(
                  MainRepository().credentials!.avatar,
                  size: 26,
                ),
                onTap: () {
                  showCupertinoModalPopup(context: context, builder: (BuildContext context) => actionSheet(context));
                },
              ),
              middle: Text(
                'Pošta',
                style: TextStyle(color: colors.text),
              )),
          child: MailboxPage(
            refreshData: _refreshData['mail'] ?? 0,
          ));
    });
  }

  // isInverted
  // Sometimes the activeTab var is changed after the listener where we call updateLatestView() finishes.
  // Therefore, the var activeTab needs to be handled as inverted.
  void updateLatestView({bool isInverted: false}) {
    DefaultView latestView = activeTab == ETabs.history ? DefaultView.history : DefaultView.bookmarks;
    if (isInverted) {
      latestView = activeTab == ETabs.history ? DefaultView.bookmarks : DefaultView.history;
    }

    if (_filterUnread) {
      latestView = latestView == DefaultView.bookmarks ? DefaultView.bookmarksUnread : DefaultView.historyUnread;
    }
    MainRepository().settings.latestView = latestView;
  }
}
