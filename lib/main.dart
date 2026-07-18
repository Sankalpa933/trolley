import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final authProvider = AuthProvider();
  await authProvider.checkInitialAuth();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => authProvider),
        ChangeNotifierProvider(create: (_) => TrolleyProvider()),
      ],
      child: const TrolleyApp(),
    ),
  );
}

// =========================================================================
// ULTRA MODERN PREMIUM DARK SLATE THEME CONFIGURATION
// =========================================================================
class AppTheme {
  static const Color darkBg = Color(0xFF121212);
  static const Color surfaceCard = Color(0xFF1E1E1E);
  static const Color surfaceCardLight = Color(0xFF2A2A2A);
  static const Color accentNeonGreen = Color(0xFF00B0FF);
  static const Color textLight = Color(0xFFFFFFFF);
  static const Color textMuted = Color(0xFFA0A0A0);

  static Color getStoreColor(String store) {
    switch (store.toUpperCase()) {
      case "KEELLS":
        return const Color(0xFF4CAF50);
      case "CARGILLS":
        return const Color(0xFFE53935);
      case "SPAR":
        return const Color(0xFF2E7D32);
      case "GLOMARK":
        return const Color(0xFFFF9800);
      case "LAUGFS":
        return const Color(0xFFFFD54F);
      default:
        return const Color(0xFF00B0FF);
    }
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: darkBg,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: accentNeonGreen,
        surface: surfaceCard,
        background: darkBg,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceCard,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: accentNeonGreen, width: 1.5),
        ),
        hintStyle: const TextStyle(color: textMuted, fontSize: 14),
      ),
    );
  }
}

class TrolleyApp extends StatelessWidget {
  const TrolleyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Trolley',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          return auth.isAuthenticated
              ? const AppNavigationShell()
              : const AuthView();
        },
      ),
    );
  }
}

// =========================================================================
// STATE MANAGEMENT LAYERS (AUTH & TROLLEY WITH LIVE AISLE FETCH)
// =========================================================================
class AuthProvider with ChangeNotifier {
  final String _baseUrl = 'http://localhost:5000/api';
  bool _isLoading = false;
  String? _errorMessage;
  String? _userName;
  String? _userEmail;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get userName => _userName;
  String? get userEmail => _userEmail;
  bool get isAuthenticated => _userName != null;

  Future<void> checkInitialAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    if (token != null) {
      _userName = prefs.getString('user_name');
      _userEmail = prefs.getString('user_email') ?? 'shopper@example.com';
      notifyListeners();
    }
  }

  Future<bool> executeRegister(
    String name,
    String email,
    String password,
  ) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': name, 'email': email, 'password': password}),
      );
      _isLoading = false;
      final data = jsonDecode(res.body);

      if (res.statusCode == 201) {
        notifyListeners();
        return true;
      } else {
        _errorMessage = data['error'] ?? 'Registration failed.';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Could not contact backend server.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> executeLogin(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );
      _isLoading = false;
      final data = jsonDecode(res.body);

      if (res.statusCode == 200 && data['token'] != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', data['token']);
        await prefs.setString('user_name', data['user']['name'] ?? 'User');
        await prefs.setString('user_email', data['user']['email'] ?? email);
        _userName = data['user']['name'];
        _userEmail = data['user']['email'];
        notifyListeners();
        return true;
      } else {
        _errorMessage = data['error'] ?? 'Invalid credentials details.';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Could not establish server authentication connection.';
      notifyListeners();
      return false;
    }
  }

  Future<void> executeLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    await prefs.remove('user_name');
    await prefs.remove('user_email');
    _userName = null;
    _userEmail = null;
    notifyListeners();
  }
}

class TrolleyProvider with ChangeNotifier {
  final String _baseUrl = 'http://localhost:5000/api';
  List<dynamic> _items = [];
  List<dynamic> _historyLists = [];

  List<dynamic> _dynamicCatalog = [];
  bool _isCatalogLoading = false;

  String _selectedSupermarket = 'GENERAL';
  bool _isLoading = false;

  // NEW: List State Tracking
  bool _isListFinalized = false;

  List<dynamic> get items => _items;
  List<dynamic> get historyLists => _historyLists;
  List<dynamic> get dynamicCatalog => _dynamicCatalog;
  bool get isCatalogLoading => _isCatalogLoading;
  String get selectedSupermarket => _selectedSupermarket;
  bool get isLoading => _isLoading;
  bool get isListFinalized => _isListFinalized; // Expose boolean tracking

  // NEW: Presentation Action Methods
  void finalizeList() {
    _isListFinalized = true;
    notifyListeners();
  }

  void editListDraft() {
    _isListFinalized = false;
    notifyListeners();
  }

  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token') ?? '';
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<void> fetchActiveTrolley() async {
    _isLoading = true;
    notifyListeners();
    try {
      final headers = await _getHeaders();
      final res = await http.post(
        Uri.parse('$_baseUrl/shopping-list/add-item'),
        headers: headers,
        body: jsonEncode({'originalText': 'FETCH_INITIAL_LOAD'}),
      );
      if (res.statusCode == 201 || res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['list'] != null) {
          _selectedSupermarket =
              data['list']['selectedSupermarket'] ?? 'GENERAL';
          _items = (data['list']['items'] as List? ?? [])
              .where((item) => item['originalText'] != 'FETCH_INITIAL_LOAD')
              .toList();
        }
      }
    } catch (e) {
      debugPrint("❌ Error fetching active trolley: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
      fetchMarketplaceCatalog();
    }
  }

  Future<void> fetchMarketplaceCatalog() async {
    _isCatalogLoading = true;
    notifyListeners();
    try {
      final headers = await _getHeaders();
      final res = await http.post(
        Uri.parse('$_baseUrl/catalog/aisles'),
        headers: headers,
        body: jsonEncode({'supermarket': _selectedSupermarket}),
      );
      if (res.statusCode == 200) {
        _dynamicCatalog = jsonDecode(res.body);
      }
    } catch (e) {
      debugPrint("❌ Failed fetching live catalog matrix: $e");
    } finally {
      _isCatalogLoading = false;
      notifyListeners();
    }
  }

  Future<void> addGroceryItem(String text, String quantity) async {
    if (text.trim().isEmpty) return;
    _isLoading = true;
    _isListFinalized = false; // NEW: Revert to draft layout mode on new add
    notifyListeners();

    try {
      final headers = await _getHeaders();
      final res = await http.post(
        Uri.parse('$_baseUrl/shopping-list/add-item'),
        headers: headers,
        body: jsonEncode({
          'originalText': text,
          'quantity': quantity,
          'selectedSupermarket': _selectedSupermarket,
        }),
      );
      if (res.statusCode == 201) {
        final data = jsonDecode(res.body);
        _items = (data['list']['items'] as List? ?? [])
            .where((item) => item['originalText'] != 'FETCH_INITIAL_LOAD')
            .toList();
      }
    } catch (e) {
      debugPrint("❌ Error adding item: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchTrolleyHistory() async {
    try {
      final headers = await _getHeaders();
      final res = await http.get(
        Uri.parse('$_baseUrl/shopping-list/history'),
        headers: headers,
      );
      if (res.statusCode == 200) {
        _historyLists = jsonDecode(res.body);
        notifyListeners();
      }
    } catch (e) {
      debugPrint("❌ Error running history engine: $e");
    }
  }

  Future<void> checkoutActiveCart() async {
    _isLoading = true;
    notifyListeners();
    try {
      final headers = await _getHeaders();
      final res = await http.post(
        Uri.parse('$_baseUrl/shopping-list/checkout'),
        headers: headers,
      );
      if (res.statusCode == 200) {
        _items = [];
        _isListFinalized = false; // Reset to default clean state
        await fetchTrolleyHistory();
      }
    } catch (e) {
      debugPrint("❌ Error checking out: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void updateSupermarket(String? newStore) {
    if (newStore == null) return;
    _selectedSupermarket = newStore;
    fetchMarketplaceCatalog();
    notifyListeners();
  }
}

// =========================================================================
// MAIN APP NAVIGATION SHELL
// =========================================================================
class AppNavigationShell extends StatefulWidget {
  const AppNavigationShell({super.key});

  @override
  State<AppNavigationShell> createState() => _AppNavigationShellState();
}

class _AppNavigationShellState extends State<AppNavigationShell> {
  int _currentIndex = 0;

  final List<Widget> _tabs = [
    const InitialWorkspacePage(),
    const TrolleyHistoryView(),
    const ProfileDetailsView(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _tabs[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: AppTheme.accentNeonGreen,
        unselectedItemColor: AppTheme.textMuted,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppTheme.surfaceCard,
        elevation: 10,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.explore_rounded),
            label: 'Explore',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_rounded),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// =========================================================================
// EYE-CATCHING HOME MARKETPLACE TAB
// =========================================================================
class InitialWorkspacePage extends StatefulWidget {
  const InitialWorkspacePage({super.key});

  @override
  State<InitialWorkspacePage> createState() => _InitialWorkspacePageState();
}

class _InitialWorkspacePageState extends State<InitialWorkspacePage> {
  final _itemController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');

  String _selectedUnitType = 'Packs';
  String _homeSubTab = 'catalog';
  String? _focusedAisleCategory;

  final List<Map<String, dynamic>> _popularSuggestions = [
    {"name": "Keeri Samba Rice", "qty": "5 kg", "icon": Icons.grain_rounded},
    {
      "name": "Maliban Biscuit Pack",
      "qty": "2 Packs",
      "icon": Icons.cookie_rounded,
    },
    {"name": "Dhal (Parippu)", "qty": "1 kg", "icon": Icons.radar_rounded},
    {
      "name": "Anchor Milk Powder",
      "qty": "1 Packs",
      "icon": Icons.water_drop_rounded,
    },
    {"name": "Astra Margarine", "qty": "1 Pcs", "icon": Icons.layers_rounded},
    {
      "name": "Pelwatte Butter",
      "qty": "1 Pcs",
      "icon": Icons.breakfast_dining_rounded,
    },
    {
      "name": "Ceylon Bread Loaf",
      "qty": "1 Pcs",
      "icon": Icons.bakery_dining_rounded,
    },
    {
      "name": "Fresh Tomatoes",
      "qty": "500 g",
      "icon": Icons.fiber_manual_record_rounded,
    },
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TrolleyProvider>(context, listen: false).fetchActiveTrolley();
    });
  }

  @override
  void dispose() {
    _itemController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final trolley = Provider.of<TrolleyProvider>(context);

    final List<String> stores = [
      "GENERAL",
      "KEELLS",
      "CARGILLS",
      "SPAR",
      "GLOMARK",
      "LAUGFS",
    ];
    final Color storeAccent = AppTheme.getStoreColor(
      trolley.selectedSupermarket,
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.darkBg,
        surfaceTintColor: Colors.transparent,
        title: Row(
          children: [
            Icon(Icons.location_on_rounded, color: storeAccent, size: 22),
            const SizedBox(width: 6),
            Text(
              '${trolley.selectedSupermarket} Engine',
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 20,
                color: AppTheme.textLight,
              ),
            ),
          ],
        ),
        actions: [
          // IMPORTANT: Check Out button now ONLY appears once the user has finalized their sorted map list!
          if (trolley.items.isNotEmpty && trolley.isListFinalized)
            Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: ElevatedButton.icon(
                onPressed: trolley.isLoading
                    ? null
                    : () => trolley.checkoutActiveCart(),
                icon: const Icon(Icons.archive_rounded, size: 16),
                label: const Text('Save Cart'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentNeonGreen,
                  foregroundColor: AppTheme.darkBg,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            color: AppTheme.surfaceCard,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ayubowan, ${auth.userName ?? "Shopper"} 👋',
                      style: const TextStyle(
                        fontWeight: FontWeight.w400,
                        fontSize: 13,
                        color: AppTheme.textMuted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Explore Market Aisle Maps',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppTheme.textLight,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceCardLight,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: trolley.selectedSupermarket,
                      dropdownColor: AppTheme.surfaceCard,
                      style: const TextStyle(
                        color: AppTheme.textLight,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      items: stores
                          .map(
                            (String store) => DropdownMenuItem<String>(
                              value: store,
                              child: Text(store),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        trolley.updateSupermarket(val);
                        setState(() => _focusedAisleCategory = null);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _itemController,
                    decoration: const InputDecoration(
                      hintText: 'What are you tracking?',
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: AppTheme.accentNeonGreen,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: TextField(
                    controller: _quantityController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(
                      hintText: 'Qty',
                      contentPadding: EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceCard,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedUnitType,
                      dropdownColor: AppTheme.surfaceCard,
                      style: const TextStyle(
                        color: AppTheme.textLight,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      items: ['Packs', 'Pcs', 'kg', 'g', 'ml', 'L']
                          .map(
                            (String unit) => DropdownMenuItem<String>(
                              value: unit,
                              child: Text(unit),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        if (val != null)
                          setState(() => _selectedUnitType = val);
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: trolley.isLoading
                      ? null
                      : () async {
                          if (_itemController.text.trim().isNotEmpty) {
                            final operationalQty =
                                "${_quantityController.text} $_selectedUnitType";
                            await trolley.addGroceryItem(
                              _itemController.text,
                              operationalQty,
                            );
                            _itemController.clear();
                            setState(() {
                              _quantityController.text = '1';
                              _selectedUnitType = 'Packs';
                            });
                          }
                        },
                  style: IconButton.styleFrom(
                    backgroundColor: AppTheme.accentNeonGreen,
                    padding: const EdgeInsets.all(14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  icon: trolley.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: AppTheme.darkBg,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.send_rounded, color: AppTheme.darkBg),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                _buildSubTabButton('✨ Popular', 'popular'),
                _buildSubTabButton('⊞ Catalog Explorer', 'catalog'),
                _buildSubTabButton(
                  '🛒 Active Run (${trolley.items.length})',
                  'active',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _buildActiveSubView(trolley, storeAccent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubTabButton(String label, String tabKey) {
    final isSelected = _homeSubTab == tabKey;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppTheme.darkBg : AppTheme.textLight,
            fontWeight: FontWeight.bold,
          ),
        ),
        selected: isSelected,
        selectedColor: AppTheme.accentNeonGreen,
        backgroundColor: AppTheme.surfaceCard,
        showCheckmark: false,
        // FIX: Changed BorderRadius.circular to BorderRadius.all with Radius.circular
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
          side: BorderSide.none,
        ),
        onSelected: (_) => setState(() => _homeSubTab = tabKey),
      ),
    );
  }

  Widget _buildActiveSubView(TrolleyProvider trolley, Color storeAccent) {
    if (trolley.isCatalogLoading && _homeSubTab == 'catalog') {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.accentNeonGreen),
      );
    }

    if (_homeSubTab == 'popular') {
      return GridView.builder(
        key: PageStorageKey('popular_${trolley.selectedSupermarket}'),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 200,
          mainAxisExtent: 60,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: _popularSuggestions.length,
        itemBuilder: (context, index) {
          final sug = _popularSuggestions[index];
          return InkWell(
            onTap: () => trolley.addGroceryItem(sug['name'], sug['qty']),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.surfaceCard,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Icon(
                    sug['icon'] as IconData,
                    color: AppTheme.accentNeonGreen,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      sug['name'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(
                    Icons.add_circle_outline_rounded,
                    color: AppTheme.textMuted,
                    size: 18,
                  ),
                ],
              ),
            ),
          );
        },
      );
    } else if (_homeSubTab == 'catalog') {
      if (trolley.dynamicCatalog.isEmpty) {
        return const Center(
          child: Text(
            "No live categories generated for this marketplace yet.",
            style: TextStyle(color: AppTheme.textMuted),
          ),
        );
      }

      if (_focusedAisleCategory != null) {
        final currentAisle = trolley.dynamicCatalog.firstWhere(
          (element) => element['title'] == _focusedAisleCategory,
          orElse: () => trolley.dynamicCatalog.first,
        );
        final List<dynamic> itemsInAisle = currentAisle['items'] ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 4,
              ),
              child: TextButton.icon(
                onPressed: () => setState(() => _focusedAisleCategory = null),
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 14,
                  color: AppTheme.accentNeonGreen,
                ),
                label: const Text(
                  'Back to Aisle Catalog',
                  style: TextStyle(
                    color: AppTheme.accentNeonGreen,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8,
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.layers_outlined,
                    color: AppTheme.accentNeonGreen,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${currentAisle['title']} Aisle Feed',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: itemsInAisle.length,
                itemBuilder: (context, idx) {
                  final itemName = itemsInAisle[idx].toString();
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceCard,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      title: Text(
                        itemName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.add_circle_rounded,
                          color: AppTheme.accentNeonGreen,
                        ),
                        onPressed: () =>
                            trolley.addGroceryItem(itemName, "1 Packs"),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      }

      return GridView.builder(
        key: PageStorageKey('catalog_${trolley.selectedSupermarket}'),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 180,
          mainAxisExtent: 140,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: trolley.dynamicCatalog.length,
        itemBuilder: (context, index) {
          final aisle = trolley.dynamicCatalog[index];
          final colorStr = aisle['color']?.toString() ?? '#00B0FF';
          final parsedColor = Color(
            int.parse(colorStr.replaceAll('#', '0xFF')),
          );

          return InkWell(
            onTap: () => setState(
              () => _focusedAisleCategory = aisle['title'] as String,
            ),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.surfaceCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.surfaceCardLight, width: 1),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: parsedColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.grid_view_rounded,
                      color: parsedColor,
                      size: 26,
                    ),
                  ),
                  Text(
                    aisle['title'] as String,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppTheme.textLight,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      );
    } else {
      // =========================================================================
      // DYNAMIC ACTIVE RUN (DRAFT LIST vs FINALIZED AISLE MAP)
      // =========================================================================
      if (trolley.items.isEmpty) {
        return const Center(
          child: Text(
            "Your active trolley runtime is empty.",
            style: TextStyle(color: AppTheme.textMuted),
          ),
        );
      }

      if (!trolley.isListFinalized) {
        // --- 1. DRAFT MODE: Simple Clean List Layout ---
        final reversedItems = trolley.items.reversed.toList();
        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: reversedItems.length,
                itemBuilder: (context, index) {
                  final item = reversedItems[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.surfaceCardLight,
                        width: 1,
                      ),
                    ),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: storeAccent.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.shopping_bag_outlined,
                          color: storeAccent,
                          size: 18,
                        ),
                      ),
                      title: Text(
                        item['standardizedName'] ?? item['originalText'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textLight,
                        ),
                      ),
                      trailing: Text(
                        item['quantity'] ?? '1 Packs',
                        style: const TextStyle(
                          color: AppTheme.textMuted,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => trolley.finalizeList(),
                  icon: const Icon(Icons.auto_awesome_mosaic_rounded),
                  label: const Text(
                    'Finalize List & Sort into Aisles',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentNeonGreen,
                    foregroundColor: AppTheme.darkBg,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      } else {
        // --- 2. FINALIZED MODE: Premium Grouped Aisle Blocks ---
        Map<String, List<dynamic>> groupedItems = {};
        for (var item in trolley.items) {
          String cat = item['category'] ?? 'General';
          groupedItems.putIfAbsent(cat, () => []).add(item);
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 4.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Sorted Aisle Map',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppTheme.textLight,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => trolley.editListDraft(),
                    icon: const Icon(
                      Icons.edit_note_rounded,
                      size: 18,
                      color: AppTheme.accentNeonGreen,
                    ),
                    label: const Text(
                      'Edit Draft',
                      style: TextStyle(
                        color: AppTheme.accentNeonGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: groupedItems.keys.length,
                itemBuilder: (context, index) {
                  String category = groupedItems.keys.elementAt(index);
                  List<dynamic> catItems = groupedItems[category]!;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppTheme.surfaceCardLight,
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Aisle Header Banner
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: const BoxDecoration(
                            color: AppTheme.surfaceCardLight,
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(15),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.category_rounded,
                                color: storeAccent,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                category,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.textLight,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Items Under Aisle
                        ...catItems
                            .map(
                              (item) => Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.circle,
                                          size: 6,
                                          color: AppTheme.textMuted,
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          item['standardizedName'] ??
                                              item['originalText'],
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      item['quantity'] ?? '1 Packs',
                                      style: const TextStyle(
                                        color: AppTheme.textMuted,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      }
    }
  }
}

// =========================================================================
// PRESENTATION VIEW WIDGETS: ORDERS / PREVIOUS CARTS TAB
// =========================================================================
class TrolleyHistoryView extends StatefulWidget {
  const TrolleyHistoryView({super.key});

  @override
  State<TrolleyHistoryView> createState() => _TrolleyHistoryViewState();
}

class _TrolleyHistoryViewState extends State<TrolleyHistoryView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TrolleyProvider>(
        context,
        listen: false,
      ).fetchTrolleyHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final trolley = Provider.of<TrolleyProvider>(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.darkBg,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Past Trolley Runs',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: trolley.historyLists.isEmpty
          ? const Center(
              child: Text(
                "No checkout logs found in account database.",
                style: TextStyle(color: AppTheme.textMuted),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: trolley.historyLists.length,
              itemBuilder: (context, index) {
                final list = trolley.historyLists[index];
                final dateStr = list['createdAt'] != null
                    ? DateTime.parse(
                        list['createdAt'],
                      ).toLocal().toString().substring(0, 16)
                    : 'Unknown Date';
                final storeColor = AppTheme.getStoreColor(
                  list['selectedSupermarket'] ?? 'GENERAL',
                );

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceCard,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  key: ValueKey(list['listId']),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: storeColor.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.shopping_bag_rounded,
                        color: storeColor,
                      ),
                    ),
                    title: Text(
                      list['selectedSupermarket'] ?? 'GENERAL',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Date: $dateStr',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textMuted,
                            ),
                          ),
                          Text(
                            'Items Sorted: ${list['itemCount'] ?? 0} rows',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: AppTheme.textMuted,
                    ),
                  ),
                );
              },
            ),
    );
  }
}

// =========================================================================
// PRESENTATION VIEW WIDGETS: ACCOUNT / PROFILE PROFILE TAB
// =========================================================================
class ProfileDetailsView extends StatelessWidget {
  const ProfileDetailsView({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.darkBg,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Account Hub',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: AppTheme.accentNeonGreen,
                  child: Text(
                    auth.userName != null
                        ? auth.userName!.substring(0, 1).toUpperCase()
                        : 'S',
                    style: const TextStyle(
                      color: AppTheme.darkBg,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      auth.userName ?? 'Shopper Profile',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      auth.userEmail ?? 'shopper@example.com',
                      style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 40),
            const Text(
              'Security Parameters',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppTheme.textMuted,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.surfaceCard,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                children: [
                  ListTile(
                    leading: Icon(
                      Icons.lock_reset_rounded,
                      color: AppTheme.accentNeonGreen,
                    ),
                    title: Text(
                      'Reset Access Token Pass',
                      style: TextStyle(fontSize: 14),
                    ),
                    trailing: Icon(Icons.arrow_forward_ios_rounded, size: 14),
                  ),
                  Divider(height: 1, color: AppTheme.darkBg),
                  ListTile(
                    leading: Icon(
                      Icons.fingerprint_rounded,
                      color: AppTheme.accentNeonGreen,
                    ),
                    title: Text(
                      'Biometric Authentication Guard',
                      style: TextStyle(fontSize: 14),
                    ),
                    trailing: Icon(Icons.arrow_forward_ios_rounded, size: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => auth.executeLogout(),
                icon: const Icon(Icons.power_settings_new_rounded),
                label: const Text(
                  'Log Out Session',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD32F2F),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =========================================================================
// PRESENTATION VIEW WIDGETS: AUTHENTICATION (LOGIN & REGISTRATION)
// =========================================================================
class AuthView extends StatefulWidget {
  const AuthView({super.key});

  @override
  State<AuthView> createState() => _AuthViewState();
}

class _AuthViewState extends State<AuthView> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoginMode = true;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    bool success;

    if (_isLoginMode) {
      success = await auth.executeLogin(
        _emailController.text,
        _passwordController.text,
      );
    } else {
      success = await auth.executeRegister(
        _nameController.text,
        _emailController.text,
        _passwordController.text,
      );
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration successful! Please log in.'),
          ),
        );
        setState(() => _isLoginMode = true);
      }
    }

    if (!success && mounted && auth.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage!),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Trolley Engine',
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.textLight,
                      letterSpacing: -1,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  if (!_isLoginMode) ...[
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(hintText: 'Full Name'),
                      validator: (val) => val == null || val.isEmpty
                          ? 'Please enter your name'
                          : null,
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      hintText: 'Email Address',
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (val) => val == null || !val.contains('@')
                        ? 'Please enter a valid email address'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(hintText: 'Password'),
                    obscureText: true,
                    validator: (val) => val == null || val.length < 6
                        ? 'Password must exceed 5 characters'
                        : null,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentNeonGreen,
                      foregroundColor: AppTheme.darkBg,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Text(
                      _isLoginMode ? 'Continue' : 'Create Account',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () =>
                        setState(() => _isLoginMode = !_isLoginMode),
                    child: Text(
                      _isLoginMode
                          ? "New to Trolley? Sign up"
                          : 'Already have an account? Log in',
                      style: const TextStyle(
                        color: AppTheme.accentNeonGreen,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
