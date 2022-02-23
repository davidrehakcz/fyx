import 'package:fyx/model/enums/PostTypeEnum.dart';
import 'package:fyx/model/post/Content.dart';
import 'package:fyx/model/post/dice/DiceComputedValues.dart';
import 'package:fyx/model/post/dice/DiceRoll.dart';

class ContentDice extends Content {
  String _reason = '';
  int _diceCount = 0;
  int _diceSides = 0;
  int _allowRollsUntil = 0;
  int _showRollsAfter = 0;
  List<DiceRoll> _rolls = <DiceRoll>[];
  DiceComputedValues? _computedValues;

  String get reason => _reason;

  int get diceCount => _diceCount;

  int get diceSides => _diceSides;

  int get allowRollsUntil => _allowRollsUntil;

  int get showRollsAfter => _showRollsAfter;

  bool get userDidRoll => _computedValues?.userDidRoll ?? true;

  List<DiceRoll> get rolls => _rolls;

  ContentDice.fromJson(Map<String, dynamic> json) : super(PostTypeEnum.dice, isCompact: false) {
    _reason = json['reason'] ?? '';
    _diceCount = json['dice_count'] ?? 0;
    _diceSides = json['dice_sides'] ?? 0;
    _allowRollsUntil = json['allow_rolls_until'] != null ? DateTime.parse(json['allow_rolls_until']).millisecondsSinceEpoch : 0;
    _showRollsAfter = json['show_rolls_after'] != null ? DateTime.parse(json['show_rolls_after']).millisecondsSinceEpoch : 0;
    if (json['rolls'] != null) {
      _rolls = <DiceRoll>[];
       (json['rolls'] as List<dynamic>).forEach((userRoll) {
        _rolls.add(new DiceRoll.fromJson(userRoll as Map<String, dynamic>));
      });
    }
    if (json['computed_values'] != null) {
      _computedValues = DiceComputedValues.fromJson(json['computed_values']);
    }
  }
}
