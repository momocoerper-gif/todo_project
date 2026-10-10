
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/todo_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/finance_screen.dart';
import 'screens/village_screen.dart';

import 'theme/app_theme.dart';

import 'database/database_helper.dart';

import 'widgets/city_header.dart';

// --------------------------------------------------
// APP STARTEN
// --------------------------------------------------

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('de_DE');

  // SQLite-Datenbank initialisieren
  await DatabaseHelper.instance.database;
  
  runApp(const MyApp());
}

// --------------------------------------------------
// APP + THEME-VERWALTUNG
// --------------------------------------------------

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  static const String _themeKey = 'theme_mode';

  final SharedPreferencesAsync _preferences =
      SharedPreferencesAsync();
  // Aktuell ausgewähltes Theme
  ThemeMode _themeMode = ThemeMode.system;

  // Theme wechseln
  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  // Gespeichertes Theme beim Start laden
  Future<void> _loadTheme() async {
    final savedTheme = await _preferences.getString(_themeKey);

    if (!mounted) return;

    setState(() {
      _themeMode = switch (savedTheme) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };
    });
  }

  // Theme wechseln und speichern
  Future<void> toggleTheme(bool isDarkMode) async {
    final newMode =
        isDarkMode ? ThemeMode.dark : ThemeMode.light;

    setState(() {
      _themeMode = newMode;
    });

    await _preferences.setString(
      _themeKey,
      newMode.name,
    );
  }

  @override
  Widget build(BuildContext context) {
    final systemBrightness =
        MediaQuery.platformBrightnessOf(context);

    final isDarkMode = _themeMode == ThemeMode.dark ||
        (_themeMode == ThemeMode.system &&
            systemBrightness == Brightness.dark);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Meine To-do-App',

      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeMode,

      locale: const Locale('de', 'DE'),
      supportedLocales: const [
        Locale('de', 'DE'),
      ],

      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      home: MainScreen(
        isDarkMode: isDarkMode,
        onThemeChanged: toggleTheme,
      ),
    );
  }
}

// --------------------------------------------------
// HAUPTSCREEN + SIDEBAR
// --------------------------------------------------

class MainScreen extends StatefulWidget {
  final bool isDarkMode;
  final ValueChanged<bool> onThemeChanged;

  const MainScreen({
    super.key,
    required this.isDarkMode,
    required this.onThemeChanged,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  // Aktuell ausgewählter Screen
  int selectedIndex = 0;
  int todoRefreshVersion = 0;
  int calendarRefreshVersion = 0;
  int financeRefreshVersion = 0;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Titel der verschiedenen Screens
  final List<String> titles = const [
    'Dorfplatz',
    'Quests',
    'Kalender',
    'Schatzkammer',
    'Einstellungen',
  ];

  // Screen wechseln
  void changeScreen(int index, {bool closeDrawer = true}) {
    setState(() {
      selectedIndex = index;

      switch (index) {
        case 1:
          todoRefreshVersion++;
          break;

        case 2:
          calendarRefreshVersion++;
          break;
        
        case 3:
          financeRefreshVersion++;
          break;
      }
    });

    if (closeDrawer) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Screens
    final List<Widget> screens = [
      VillageScreen(
        onOpenMenu: () => _scaffoldKey.currentState?.openDrawer(),
        onOpenTodos: () {
          changeScreen(1, closeDrawer: false);
        },

        onOpenCalendar: () {
          changeScreen(2, closeDrawer: false);
        },

        onOpenFinance: () {
          changeScreen(3, closeDrawer: false);
        },
      ),

      TodoScreen(
        key: ValueKey('todo-$todoRefreshVersion'),
      ),

      CalendarScreen(
        key: ValueKey('calendar-$calendarRefreshVersion'),
      ),

      FinanceScreen(
        key: ValueKey('finance-$financeRefreshVersion'),
      ),

      SettingsScreen(
        isDarkMode: widget.isDarkMode,
        onThemeChanged: widget.onThemeChanged,
      ),
    ];

    return Scaffold(
      key: _scaffoldKey,
      // Extend the village behind the system status bar.
      // Other screens keep the original city AppBar.
      appBar: selectedIndex == 0 ? null : AppBar(
        // Titel des aktuellen Screens
        title: Text(
          titles[selectedIndex],
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                color: Colors.black,
                blurRadius: 6,
              ),
            ],
          ),
        ),

        // Hamburger-Menü und andere Icons
        foregroundColor: Colors.white,

        // Stadtbild direkt im Header
        flexibleSpace: Builder(
          builder: (context) {
            final isDark =
                Theme.of(context).brightness == Brightness.dark;

            return Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  isDark
                      ? 'assets/images/city_night.png'
                      : 'assets/images/city_day.png',
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                  filterQuality: FilterQuality.none,
                ),

                // Abdunklung für besser lesbaren Text
                Container(
                  color: Colors.black.withValues(alpha: 0.25),
                ),
              ],
            );
          },
        ),

        toolbarHeight: 85,
      ),


      // Sidebar
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              padding: EdgeInsets.zero,
              margin: EdgeInsets.zero,
              child: CityHeader(
                title: 'Meine To-do-App',
                height: 160,
              ),
            ),

            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Dorfplatz'),
              selected: selectedIndex == 0,
              onTap: () => changeScreen(0),
            ),

            ListTile(
              leading: const Icon(Icons.checklist),
              title: const Text('Quests'),
              selected: selectedIndex == 1,
              onTap: () => changeScreen(1),
            ),

            ListTile(
              leading: const Icon(Icons.calendar_month),
              title: const Text('Kalender'),
              selected: selectedIndex == 2,
              onTap: () => changeScreen(2),
            ),
            
            ListTile(
              leading: const Icon(Icons.account_balance_wallet_outlined),
              title: const Text('Schatzkammer'),
              selected: selectedIndex == 3,
              onTap: () => changeScreen(3),
            ),

            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Einstellungen'),
              selected: selectedIndex == 4,
              onTap: () => changeScreen(4),
            ),
          ],
        ),
      ),

      // Aktuell ausgewählter Screen
      // IndexedStack erhält den Zustand der Screens
      body: IndexedStack(
        index: selectedIndex,
        children: screens,
      ),
    );
  }
}
