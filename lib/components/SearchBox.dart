import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fyx/theme/skin/Skin.dart';
import 'package:fyx/theme/skin/SkinColors.dart';

class SearchBox extends ConsumerStatefulWidget {
  final ValueChanged? onSearch;
  final VoidCallback? onClear;
  final StateProvider<String?> provider;

  SearchBox({Key? key, this.onSearch, this.onClear, required this.provider}) : super(key: key);

  @override
  _SearchBoxState createState() => _SearchBoxState();
}

class _SearchBoxState extends ConsumerState<SearchBox> with TickerProviderStateMixin {
  String searchTerm = '';
  late AnimationController searchAnimation;
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();

    searchController.text = ref.read(widget.provider.notifier).state ?? '';
    searchAnimation = AnimationController(
        duration: const Duration(milliseconds: 700), vsync: this, value: ref.read(widget.provider.notifier).state == null ? 0 : 1);
  }

  @override
  Widget build(BuildContext context) {
    SkinColors colors = Skin.of(context).theme.colors;
    ref.listen<String?>(widget.provider, (_prev, _new) {
      if (_new == null) {
        searchAnimation.reverse();
      } else {
        searchAnimation.forward();
      }
    });

    return SizeTransition(
        sizeFactor: CurvedAnimation(
          curve: Curves.ease,
          parent: searchAnimation,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: CupertinoSearchTextField(
            placeholder: 'Hledej',
            controller: searchController,
            onSubmitted: (term) {
              ref.read(widget.provider.notifier).state = term;
              if (widget.onSearch != null) {
                widget.onSearch!(term);
              }
            },
            onSuffixTap: () {
              searchController.clear();
              ref.read(widget.provider.notifier).state = '';
              if (widget.onClear != null) {
                widget.onClear!();
              }
            },
            autocorrect: false,
          ),
          color: colors.barBackground,
        ));
  }
}
