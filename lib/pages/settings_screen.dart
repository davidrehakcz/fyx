import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fyx/FyxApp.dart';
import 'package:fyx/controllers/AnalyticsProvider.dart';
import 'package:fyx/controllers/ApiController.dart';
import 'package:fyx/model/MainRepository.dart';
import 'package:fyx/model/enums/DefaultView.dart';
import 'package:fyx/model/enums/FirstUnreadEnum.dart';
import 'package:fyx/model/enums/ThemeEnum.dart';
import 'package:fyx/model/provider/ThemeModel.dart';
import 'package:fyx/pages/InfoPage.dart';
import 'package:fyx/theme/L.dart';
import 'package:fyx/theme/T.dart';
import 'package:fyx/theme/skin/Skin.dart';
import 'package:fyx/theme/skin/SkinColors.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:settings_ui/settings_ui.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _compactMode = false;
  bool _autocorrect = false;
  DefaultView _defaultView = DefaultView.latest;
  FirstUnreadEnum _firstUnread = FirstUnreadEnum.button;

  @override
  void initState() {
    super.initState();
    _compactMode = MainRepository().settings.useCompactMode;
    _autocorrect = MainRepository().settings.useAutocorrect;
    _defaultView = MainRepository().settings.defaultView;
    _firstUnread = MainRepository().settings.firstUnread;
    AnalyticsProvider().setScreen('Settings', 'SettingsPage');
  }

  SettingsTile _firstUnreadFactory(String label, FirstUnreadEnum value, {Widget? description}) {
    return SettingsTile(
      title: Text(label),
      trailing: _firstUnread == value ? Icon(CupertinoIcons.check_mark) : null,
      description: description,
      onPressed: (_) {
        setState(() => _firstUnread = value);
        MainRepository().settings.firstUnread = value;
      },
    );
  }

  SettingsTile _defaultViewFactory(String label, DefaultView value) {
    return SettingsTile(
      title: Text(label),
      trailing: _defaultView == value ? Icon(CupertinoIcons.check_mark) : null,
      onPressed: (_) {
        setState(() => _defaultView = value);
        MainRepository().settings.defaultView = value;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    SkinColors colors = Skin.of(context).theme.colors;

    var pkg = MainRepository().packageInfo;
    var version = '${pkg.version} (${pkg.buildNumber})';

    return CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
            middle: Text(
              L.SETTINGS,
              style: TextStyle(color: colors.text),
            ),
            leading: CupertinoNavigationBarBackButton(
              color: colors.primary,
              onPressed: () {
                Navigator.of(context, rootNavigator: true).pop();
              },
            )),
        child: CupertinoScrollbar(
          child: SettingsList(
            lightTheme: SettingsThemeData(
                settingsSectionBackground: colors.barBackground,
                settingsListBackground: colors.background,
                settingsTileTextColor: colors.text,
                tileHighlightColor: colors.primary.withOpacity(0.1),
                dividerColor: colors.background),
            sections: [
              SettingsSection(
                title: Text('Příspěvky'),
                tiles: <SettingsTile>[
                  SettingsTile.switchTile(
                    onToggle: (bool value) {
                      setState(() => _autocorrect = value);
                      MainRepository().settings.useAutocorrect = value;
                    },
                    initialValue: _autocorrect,
                    leading: Icon(Icons.spellcheck),
                    title: Text('Autocorrect'),
                  ),
                  SettingsTile.switchTile(
                    onToggle: (bool value) {
                      setState(() => _compactMode = value);
                      MainRepository().settings.useCompactMode = value;
                    },
                    initialValue: _compactMode,
                    leading: Icon(Icons.view_compact),
                    title: Text('Kompaktní zobrazení'),
                    description: Text(
                      'Kompaktní zobrazení je zobrazení obrázků po stranách pokud to obsah příspěvku dovoluje (nedojde tak k narušení kontextu).',
                    ),
                  ),
                ],
              ),
              SettingsSection(
                title: Text('První nepřečtený'),
                tiles: <SettingsTile>[
                  _firstUnreadFactory('Vypnuto', FirstUnreadEnum.off),
                  _firstUnreadFactory('Zobrazovat tlačítko', FirstUnreadEnum.button),
                  _firstUnreadFactory('Automaticky odskočit', FirstUnreadEnum.autoscroll,
                      description: Text('Funguje pouze na prvních 100 nepřečtených.')),
                ],
              ),
              SettingsSection(
                title: Text('Výchozí obrazovka'),
                tiles: <SettingsTile>[
                  _defaultViewFactory('Poslední stav', DefaultView.latest),
                  _defaultViewFactory('Historie (vše)', DefaultView.history),
                  _defaultViewFactory('Historie (nepřečtené)', DefaultView.historyUnread),
                  _defaultViewFactory('Sledované (vše)', DefaultView.bookmarks),
                  _defaultViewFactory('Sledované (nepřečtené)', DefaultView.bookmarksUnread),
                ],
              ),
              SettingsSection(
                title: Text('Vzhled'),
                tiles: <SettingsTile>[
                  SettingsTile.navigation(
                    title: Text('Barevný režim'),
                    value: Text((() {
                      switch (MainRepository().settings.theme) {
                        case ThemeEnum.light:
                          return 'Světlý';

                        case ThemeEnum.dark:
                          return 'Tmavý';

                        case ThemeEnum.system:
                          return 'Podle systému';
                      }
                    })()),
                    onPressed: (context) => Navigator.of(context).pushNamed('/settings/design'),
                  ),
                ],
              ),
              SettingsSection(
                title: Text('Paměť'),
                tiles: <SettingsTile>[
                  SettingsTile(
                    title: Text('Blokovaných uživatelů'),
                    trailing: ValueListenableBuilder(
                        valueListenable: MainRepository().settings.box.listenable(keys: ['blockedUsers']),
                        builder: (BuildContext context, value, Widget? child) {
                          return Text(
                            MainRepository().settings.blockedUsers.length.toString(),
                            style: TextStyle(color: colors.text),
                          );
                        }),
                  ),
                  SettingsTile(
                    title: Text('Skrytých příspěvků'),
                    trailing: ValueListenableBuilder(
                        valueListenable: MainRepository().settings.box.listenable(keys: ['blockedPosts']),
                        builder: (BuildContext context, value, Widget? child) {
                          return Text(
                            MainRepository().settings.blockedPosts.length.toString(),
                            style: TextStyle(color: colors.text),
                          );
                        }),
                  ),
                  SettingsTile(
                    title: Text('Skryté pošty'),
                    trailing: ValueListenableBuilder(
                        valueListenable: MainRepository().settings.box.listenable(keys: ['blockedMails']),
                        builder: (BuildContext context, value, Widget? child) {
                          return Text(
                            MainRepository().settings.blockedMails.length.toString(),
                            style: TextStyle(color: colors.text),
                          );
                        }),
                  ),
                  SettingsTile(
                      title: Text('Resetovat', style: TextStyle(color: colors.danger), textAlign: TextAlign.center),
                      onPressed: (_) {
                        MainRepository().settings.resetBlockedContent();
                        T.success(L.SETTINGS_CACHE_RESET, bg: colors.success);
                        AnalyticsProvider().logEvent('resetBlockedContent');
                      }),
                ],
              ),
              SettingsSection(title: Text('Informace'), tiles: <SettingsTile>[
                SettingsTile.navigation(
                  leading: Icon(Icons.volunteer_activism),
                  title: Text(L.BACKERS),
                  onPressed: (_) => Navigator.of(context).pushNamed('/settings/info',
                      arguments: InfoPageSettings(L.BACKERS, 'https://raw.githubusercontent.com/lucien144/fyx/develop/BACKERS.md')),
                ),
                SettingsTile.navigation(
                  leading: Icon(Icons.info),
                  title: Text(L.ABOUT),
                  onPressed: (_) => Navigator.of(context).pushNamed('/settings/info',
                      arguments: InfoPageSettings(L.ABOUT, 'https://raw.githubusercontent.com/lucien144/fyx/develop/ABOUT.md')),
                ),
                SettingsTile.navigation(
                  leading: Icon(Icons.bug_report),
                  title: Text(L.SETTINGS_BUGREPORT),
                  onPressed: (_) {
                    T.prefillGithubIssue(appContext: MainRepository(), user: MainRepository().credentials!.nickname);
                    AnalyticsProvider().logEvent('reportBug');
                  },
                ),
                SettingsTile.navigation(
                  leading: Icon(Icons.gavel),
                  title: Text(L.TERMS),
                  onPressed: (_) {
                    T.openLink('https://nyx.cz/terms');
                    AnalyticsProvider().logEvent('openTerms');
                  },
                )
              ]),
              SettingsSection(
                tiles: [
                  SettingsTile(
                    title: Text(
                      L.GENERAL_LOGOUT,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colors.danger),
                    ),
                    onPressed: (_) {
                      ApiController().logout();
                      Navigator.of(context, rootNavigator: true).pushNamed('/login');
                      AnalyticsProvider().logEvent('logout');
                    },
                  ),
                  if (FyxApp.isDev)
                    SettingsTile(
                      title: Text(
                        '${L.GENERAL_LOGOUT} (bez resetu)',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: colors.danger),
                      ),
                      onPressed: (_) {
                        ApiController().logout(removeAuthrorization: false);
                        Navigator.of(context, rootNavigator: true).pushNamed('/login');
                      },
                    )
                ],
              ),
              CustomSettingsSection(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Text(
                    'Verze: $version',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: colors.disabled, fontFamily: 'JetBrainsMono', fontSize: 13),
                  ),
                ),
              )
            ],
          ),
        ));
  }
}
