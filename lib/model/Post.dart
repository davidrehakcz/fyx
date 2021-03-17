// ignore_for_file: non_constant_identifier_names
import 'package:fyx/model/post/Content.dart';

class Post {
  final bool isCompact;
  int idKlub;
  int _id_wu;
  String _nick;
  int _time;
  int _wu_rating;
  String _wu_type;
  String myRating;
  bool _reminder;
  bool _canBeRated;
  bool _canBeDeleted;
  bool _canBeReminded;

  Content _content;

  Post.fromJson(Map<String, dynamic> json, this.idKlub, { this.isCompact }) {
    this._id_wu = json['id'];
    this._content = Content(json['content'], isCompact: this.isCompact);
    this._nick = json['username'];
    this._time = DateTime.parse(json['inserted_at'] ?? '0').millisecondsSinceEpoch;
    this._wu_rating = json['rating'] ?? 0;
    this._wu_type = json['type'];
    this.myRating = json['my_rating'] ?? 'none'; // positive / negative / negative_visible / none TODO: enums
    this._reminder = json['reminder'] ?? false;
    this._canBeRated = json['can_be_rated'] ?? false;
    this._canBeDeleted = json['can_be_deleted'] ?? false;
    this._canBeReminded = json['can_be_reminded'] ?? false;
  }

  Content get content => _content;

  String get type => _wu_type;

  int get rating => _wu_rating;

  set rating(val) => _wu_rating = val;

  int get time => _time;

  String get avatar => 'https://i.nyx.cz/${this.nick.substring(0, 1)}/${this.nick}.gif';

  String get nick => _nick.toUpperCase();

  int get id => _id_wu;

  // ignore: unnecessary_getters_setters
  bool get hasReminder => _reminder;

  String get link => 'https://www.nyx.cz/index.php?l=topic;id=${this.idKlub};wu=${this.id}';

  // ignore: unnecessary_getters_setters
  set hasReminder(bool value) => _reminder = value;

  bool get canBeReminded => _canBeReminded;

  bool get canBeDeleted => _canBeDeleted;

  bool get canBeRated => _canBeRated;
}
