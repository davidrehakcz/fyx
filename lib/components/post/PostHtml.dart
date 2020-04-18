import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_html/html_parser.dart';
import 'package:flutter_html/style.dart';
import 'package:fyx/PlatformTheme.dart';
import 'package:fyx/components/post/PostHeroAttachment.dart';
import 'package:fyx/components/post/Spoiler.dart';
import 'package:fyx/model/post/Content.dart';
import 'package:fyx/model/provider/SettingsModel.dart';
import 'package:fyx/pages/DiscussionPage.dart';
import 'package:html/dom.dart' as dom;
import 'package:provider/provider.dart';

class PostHtml extends StatelessWidget {
  final Content content;

  PostHtml(this.content);

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsModel>(
        builder: (context, settings, child) => Html(
              data: settings.useHeroPosts ? content.body : content.rawBody,
              style: {"html": Style.fromTextStyle(PlatformTheme.of(context).textTheme.textStyle ?? PlatformTheme.of(context).textTheme.body1)},
              customRender: {
                'span': (
                  RenderContext context,
                  Widget parsedChild,
                  Map<String, String> attributes,
                  dom.Element element,
                ) {
                  if (element.classes.contains('spoiler')) {
                    return Spoiler(element.text);
                  }
                  return null;
                }
              },
              onImageTap: (String src) {
                Navigator.of(context).pushNamed('/gallery', arguments: GalleryArguments(src, images: content.images));
              },
              onLinkTap: (String link) async {
                print(link);

                // Click through to another discussion
                RegExp topicTest = new RegExp(r"^\?l=topic;id=([0-9]+)$");
                Iterable<RegExpMatch> topicMatches = topicTest.allMatches(link);
                if (topicMatches.length == 1) {
                  var id = int.parse(topicMatches.elementAt(0).group(1));
                  var arguments = DiscussionPageArguments(id);
                  DiscussionPage.deeplinkDepth++;
                  Navigator.of(context, rootNavigator: true).pushNamed('/discussion', arguments: arguments);
                  return;
                }

                // Click through to another discussion with message deeplink
                RegExp topicDeeplinkTest = new RegExp(r"^\?l=topic;id=([0-9]+);wu=([0-9]+)$");
                Iterable<RegExpMatch> topicDeeplinkMatches = topicDeeplinkTest.allMatches(link);
                if (topicDeeplinkMatches.length == 1) {
                  var id = int.parse(topicDeeplinkMatches.elementAt(0).group(1));
                  var wu = int.parse(topicDeeplinkMatches.elementAt(0).group(2)) + 1;
                  var arguments = DiscussionPageArguments(id, postId: wu);
                  DiscussionPage.deeplinkDepth++;
                  Navigator.of(context, rootNavigator: true).pushNamed('/discussion', arguments: arguments);
                  return;
                }

                PlatformTheme.openLink(link);
              },
            ));
  }
}
