import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fyx/components/avatar.dart' as component;
import 'package:fyx/components/content_box_layout.dart';
import 'package:fyx/components/post/post_thumbs.dart';
import 'package:fyx/components/pull_to_refresh_list.dart';
import 'package:fyx/controllers/AnalyticsProvider.dart';
import 'package:fyx/controllers/ApiController.dart';
import 'package:fyx/model/Settings.dart';
import 'package:fyx/model/post/PostThumbItem.dart';
import 'package:fyx/model/post/content/Regular.dart';
import 'package:fyx/model/reponses/FeedNoticesResponse.dart';
import 'package:fyx/pages/DiscussionPage.dart';
import 'package:fyx/theme/Helpers.dart';
import 'package:fyx/theme/L.dart';
import 'package:fyx/theme/skin/Skin.dart';
import 'package:fyx/theme/skin/SkinColors.dart';

class NoticesPage extends StatefulWidget {
  NoticesPage({Key? key}) : super(key: key);

  @override
  _NoticesPageState createState() => _NoticesPageState();
}

class _NoticesPageState extends State<NoticesPage> with WidgetsBindingObserver {
  int _refreshData = 0;

  refresh() {
    setState(() => _refreshData = DateTime.now().millisecondsSinceEpoch);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    AnalyticsProvider().setScreen('Notices', 'NoticesPage');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && ModalRoute.of(context)!.isCurrent) {
      this.refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    SkinColors colors = Skin.of(context).theme.colors;

    return CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
            middle: Text(L.NOTICES, style: TextStyle(color: colors.text)),
            leading: CupertinoNavigationBarBackButton(
              color: colors.primary,
              onPressed: () {
                Navigator.of(context, rootNavigator: true).pop();
              },
            )),
        child: PullToRefreshList(
            rebuild: _refreshData,
            dataProvider: (lastId) async {
              var result = await Future.delayed(const Duration(milliseconds: 300), () => ApiController().loadFeedNotices());
              var feed = result.data.map((NoticeItem item) {
                var highlight = false;
                item.replies.forEach((NoticeReplies reply) => highlight = reply.time > result.lastVisit ? true : highlight);
                item.thumbsUp.forEach((NoticeThumbsUp thumbUp) => highlight = thumbUp.time > result.lastVisit ? true : highlight);

                return ContentBoxLayout(
                  onTap: () => Navigator.of(context).pushNamed('/discussion', arguments: DiscussionPageArguments(item.idKlub, postId: item.idWu + 1)),
                  content: ContentRegular(item.content),
                  isHighlighted: highlight,
                  topRightWidget: Text(
                    item.wuRating > 0 ? '+${item.wuRating}' : item.wuRating.toString(),
                    style: TextStyle(
                        fontSize: Settings().fontSize * 0.9,
                        color: item.wuRating > 0 ? colors.success : (item.wuRating < 0 ? colors.danger : colors.grey)),
                  ),
                  topLeftWidget: Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pushNamed('/discussion', arguments: DiscussionPageArguments(item.idKlub)),
                      child: Text(
                        item.discussionName,
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: Settings().fontSize),
                      ),
                    ),
                  ),
                  bottomWidget: Column(
                    children: [
                      if (item.thumbsUp.length > 0)
                        PostThumbs(item.thumbsUp.map((thumb) => PostThumbItem.fromNoticeThumbsUp(thumb, result.lastVisit)).toList()),
                      if (item.replies.length > 0)
                        const SizedBox(
                          height: 8,
                        ),
                      if (item.replies.length > 0) buildReplies(context, item.replies, result.lastVisit),
                    ],
                  ),
                );
              }).toList();
              return DataProviderResult(feed);
            }));
  }

  Widget buildReplies(BuildContext context, List<NoticeReplies> replies, int lastVisit) {
    List<Widget> replyRows = replies.map((reply) {
      return GestureDetector(
        onTap: () => Navigator.of(context).pushNamed('/discussion', arguments: DiscussionPageArguments(reply.idKlub, postId: reply.idWu + 1)),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 5),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SizedBox(
                width: 5,
              ),
              component.Avatar(
                Helpers.avatarUrl(reply.nick),
                size: 22,
                isHighlighted: reply.time > lastVisit,
              ),
              SizedBox(
                width: 5,
              ),
              Expanded(
                  child: Padding(
                padding: const EdgeInsets.only(top: 6.0),
                child: Text(Helpers.stripHtmlTags(reply.text),
                    style: TextStyle(fontSize: 14, fontWeight: reply.time > lastVisit ? FontWeight.bold : FontWeight.normal)),
              ))
            ],
          ),
        ),
      );
    }).toList();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.reply_rounded, size: 22),
        Expanded(
          child: Column(
            children: replyRows,
          ),
        )
      ],
    );
  }
}
