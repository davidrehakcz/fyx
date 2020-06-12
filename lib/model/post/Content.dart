import 'package:fyx/PlatformTheme.dart';
import 'package:fyx/model/post/Image.dart';
import 'package:fyx/model/post/Link.dart';
import 'package:fyx/model/post/Video.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart';
import 'package:html_unescape/html_unescape.dart';

class Content {
  String _body;
  String _rawBody;

  /// If the post have consecutive images = ON
  /// Consecutive images means there are now characters other than
  /// whitespaces and <br> in between of images.
  bool _consecutiveImages = false;

  List<Image> _images = [];
  List<Link> _emptyLinks = [];
  List<Video> _videos = [];

  Content(this._body) {
    _rawBody = _body;
    this._tagAllImageLinks(); // This updates the raw body.

    _body = HtmlUnescape().convert(_body);
    this._cleanupBody();
    this._parseEmbeds();
    this._parseAttachedImages();
    this._parseEmptyLinks();
  }

  String get strippedContent => parse(parse(_body).body.text).documentElement.text.trim();

  String get body => _body;

  String get rawBody => _rawBody;

  List<Image> get images => _images;

  bool get consecutiveImages => _consecutiveImages;

  List<Link> get emptyLinks => _emptyLinks;

  List<Video> get videos => _videos;

  List<dynamic> get attachments {
    var list = [];
    list.addAll(_images);
    list.addAll(_videos);
    return list;
  }

  Map<String, dynamic> get attachmentsWithFeatured {
    var cloneImages = List.from(_images);
    var cloneVideos = List.from(_videos);

    dynamic getFeatured = () {
      if (cloneImages.length > 0) {
        final featured = cloneImages[0];
        cloneImages.removeAt(0);
        return featured;
      }

      if (cloneVideos.length > 0) {
        final featured = cloneVideos[0];
        cloneVideos.removeAt(0);
        return featured;
      }
    };

    var featured = getFeatured();

    var attachments = [];
    attachments.addAll(cloneImages);
    attachments.addAll(cloneVideos);
    return {'featured': featured, 'attachments': attachments};
  }

  void _cleanupBody() {
    // Remove all HTML comments
    _body = _body.replaceAll(RegExp(r'<!--(.*?)-->'), '');

    // Remove trailing <br>
    var startBr = RegExp(r'^(((\s*)<\s*br\s*\/?\s*>(\s*))*)', caseSensitive: false);
    _body = _body.replaceAll(startBr, '');

    var trailingBr = RegExp(r'(((\s*)<\s*br\s*\/?\s*>(\s*))*)$', caseSensitive: false);
    _body = _body.replaceAll(trailingBr, '');
  }

  /// Parse emebeded videos.
  /// TODO: Others than YouTube. Vimeo? Soundcloud?
  void _parseEmbeds() {
    try {
      var document = parse(_body);
      var youtubes = document.querySelectorAll('div[data-embed-type="youtube"]');
      youtubes.forEach((el) {
        // If the video does not have preview, it's invalid Nyx attachment, therefore we skip it and handle it as a normal post.
        if (el.querySelector('img') == null) {
          return;
        }

        var video = Video(
            id: el.attributes['data-embed-value'],
            type: Video.findVideoType(el.attributes['data-embed-type']),
            image: el.querySelector('a').attributes['href'],
            thumb: el.querySelector('img').attributes['src']);

        // Remove the video element from the content.
        this._videos.add(video);

        while (el.nextElementSibling?.localName == 'br') {
          el.nextElementSibling.remove();
        }
        el.remove();
      });
      _body = document.body.innerHtml;
    } catch (error) {
      PlatformTheme.error(error.toString());
    }
  }

  /// Parse attached images
  /// For some reason the a>img[src] selector also selects standalone <img/> files
  /// -> Solved. It's the Nyx API. It wraps all images into the <a> tag with full image and replaces the img with thumbnail.
  void _parseAttachedImages() {
    Document document = parse(_body);

    RegExp reg = RegExp(r'^((?!<img).)*(((<a([^>]*?)>)?(\s*)<img([^>]*?)>(\s*)(<\/\s*a\s*>)?(\s*(\s*<\s*br\s*\/?\s*>\s*)*\s*))*)$', caseSensitive: false, dotAll: true);
    _consecutiveImages = reg.hasMatch(_body);

    document.querySelectorAll('a > img[src]').forEach((Element el) {
      var thumb = el.attributes['src'];
      var image = el.parent.attributes['href'];
      _images.add(Image(image, thumb));

      while (el.parent.nextElementSibling?.localName == 'br') {
        el.parent.nextElementSibling.remove();
      }

      if (_consecutiveImages) {
        el.parent.remove();
      }
    });
    _body = document.body.innerHtml;
  }

  void _tagAllImageLinks() {
    Document document = parse(_rawBody);
    document.querySelectorAll('a > img').forEach((Element el) {
      el.parent.classes.add('image-link');
    });
    _rawBody = document.body.innerHtml;
  }

  ///
  /// Nyx wraps all images to a link. So if we pick the images to the gallery, there will be empty links if the image has been wrapped by user.
  ///
  /// Example
  /// Post: <a href="google.com"><img src="img.png"></a>
  /// Nyx API returns: <a href="google.com"><a href="img.png"><img src="i.nyx.cz/thumb.jpg"></a></a>
  ///
  void _parseEmptyLinks() {
    RegExp r = RegExp(r'<a[^>]*?>\s*<\/a>', caseSensitive: false, multiLine: true);
    r.allMatches(_body).forEach((match) {
      String element = match.group(0);
      Document html = parse(element);
      String url = html.querySelector('a').attributes['href'];
      if (url != null) {
        _emptyLinks.add(Link(url));
        _body = _body.replaceFirst(element, '');
      }
    });
  }
}
