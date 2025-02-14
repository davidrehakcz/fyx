import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fyx/components/text_icon.dart';
import 'package:fyx/controllers/AnalyticsProvider.dart';
import 'package:fyx/controllers/ApiController.dart';
import 'package:fyx/controllers/IApiProvider.dart';
import 'package:fyx/model/MainRepository.dart';
import 'package:fyx/pages/DiscussionPage.dart';
import 'package:fyx/pages/NewMessagePage.dart';
import 'package:fyx/theme/L.dart';
import 'package:fyx/theme/T.dart';
import 'package:fyx/theme/skin/Skin.dart';
import 'package:fyx/theme/skin/SkinColors.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class PostAvatarActionSheet extends StatelessWidget {
  final String user;
  final int idKlub;

  const PostAvatarActionSheet({Key? key, required this.user, required this.idKlub}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    SkinColors colors = Skin.of(context).theme.colors;

    return CupertinoActionSheet(
      title: Text(this.user),
      actions: [
        CupertinoActionSheetAction(
          child: TextIcon('Poslat zprávu', icon: Icons.mail),
          onPressed: () {
            Navigator.pop(context); // Close the sheet first.
            Navigator.of(context, rootNavigator: true).pushNamed('/new-message',
                arguments: NewMessageSettings(
                    hasInputField: true,
                    inputFieldPlaceholder: this.user,
                    onClose: () => T.success('👍 Zpráva poslána.', bg: colors.success),
                    onSubmit: (String? inputField, String message, List<Map<ATTACHMENT, dynamic>> attachments) async {
                      if (inputField == null) return false;

                      var response = await ApiController().sendMail(inputField, message, attachments: attachments);
                      return response.isOk;
                    }));
          },
        ),
        CupertinoActionSheetAction(
          child: TextIcon('Pouze příspěvky tohoto ID', icon: MdiIcons.magnify),
          onPressed: () {
            Navigator.of(context).pop();
            Navigator.of(context).pushNamed('/discussion', arguments: DiscussionPageArguments(idKlub, filterByUser: this.user));
          },
        ),
        Visibility(
          visible: user != MainRepository().credentials!.nickname,
          child: CupertinoActionSheetAction(
              child: TextIcon(
                '${L.POST_SHEET_BLOCK} @${user}',
                icon: Icons.block,
                iconColor: colors.danger,
              ),
              isDestructiveAction: true,
              onPressed: () {
                Navigator.of(context, rootNavigator: true).pop();
                showCupertinoDialog(
                    context: context,
                    builder: (BuildContext context) => new CupertinoAlertDialog(
                          title: Text('Blokovat uživatele?'),
                          content: Text('Skutečně chcete blokovat ID @$user?'),
                          actions: [
                            CupertinoDialogAction(
                              child: Text('Ne'),
                              onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
                            ),
                            CupertinoDialogAction(
                              child: Text('Ano'),
                              isDestructiveAction: true,
                              onPressed: () {
                                MainRepository().settings.blockUser(user);
                                T.success(L.TOAST_USER_BLOCKED, bg: colors.success);
                                Navigator.of(context).pop();
                                AnalyticsProvider().logEvent('blockUser');
                              },
                            ),
                          ],
                        ));
              }),
        ),
      ],
    );
  }
}
