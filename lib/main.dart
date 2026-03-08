import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:screenshot/screenshot.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io' as io; // Use prefix to avoid conflicts and signify non-web use
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Source;
import 'tafser_model.dart';
import 'export_service.dart';
// import 'firebase_options.dart';

import 'initial_data.dart';
// Removed: initial_data_muyassar.dart and initial_data_ghareeb.dart imports

bool isFirebaseAvailable = false;

String normalizeArabic(String text) {
  return text
      .replaceAll('\u064B', '') // Fathatan
      .replaceAll('\u064C', '') // Dammatan
      .replaceAll('\u064D', '') // Kasratan
      .replaceAll('\u064E', '') // Fatha
      .replaceAll('\u064F', '') // Damma
      .replaceAll('\u0650', '') // Kasra
      .replaceAll('\u0651', '') // Shadda
      .replaceAll('\u0652', '') // Sukun
      .replaceAll('أ', 'ا')
      .replaceAll('إ', 'ا')
      .replaceAll('آ', 'ا')
      .replaceAll('ة', 'ه')
      .replaceAll('سورة ', '')
      .replaceAll('سُورَةُ ', '')
      .trim();
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase (Try-catch to avoid crash if firebase_options is missing on first run)
  try {
    await Firebase.initializeApp(
      // options: DefaultFirebaseOptions.currentPlatform, // Uncomment when file exists
    );
    isFirebaseAvailable = true;
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
    isFirebaseAvailable = false;
  }

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  runApp(const TafserApp());
}

class TafserApp extends StatelessWidget {
  const TafserApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'برنامج عمل التفسير',
      locale: const Locale('ar', 'SA'),
      supportedLocales: const [Locale('ar', 'SA')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFD4AF37)),
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _isLocallyAuthenticated = false;
  bool _isAuthChecked = false;

  @override
  void initState() {
    super.initState();
    _checkLocalAuth();
  }

  Future<void> _checkLocalAuth() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _isLocallyAuthenticated = prefs.getBool('isLoggedIn') ?? false;
        _isAuthChecked = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAuthChecked) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!_isLocallyAuthenticated) {
      return LoginScreen(
        onLoginSuccess: () {
          setState(() {
            _isLocallyAuthenticated = true;
          });
        },
      );
    }
    return const TafserEditorScreen();
  }
}

class LoginScreen extends StatefulWidget {
  final VoidCallback onLoginSuccess;
  const LoginScreen({super.key, required this.onLoginSuccess});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _securityKeyController = TextEditingController();
  bool _isLoading = false;

  Future<void> _submit() async {
    const String correctKey = "NHHA669266";

    if (_securityKeyController.text.trim() != correctKey) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('رمز الأمان غير صحيح!'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);

      // Auto-login to Firebase with a generic account if needed,
      // or just proceed if local use is sufficient.
      // For now, we favor local security as requested.

      widget.onLoginSuccess();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('خطأ: ${e.toString()}')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFCF0),
      body: Center(
        child: Container(
          width: 350,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFD4AF37).withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
            border: Border.all(
              color: const Color(0xFFD4AF37).withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.lock_person_rounded,
                size: 64,
                color: Color(0xFFD4AF37),
              ),
              const SizedBox(height: 16),
              Text(
                'برنامج عمل التفسير',
                style: GoogleFonts.amiri(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF8B0000),
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _securityKeyController,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20, letterSpacing: 4),
                decoration: InputDecoration(
                  labelText: 'أدخل رمز الأمان',
                  labelStyle: GoogleFonts.amiri(),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFFD4AF37),
                      width: 2,
                    ),
                  ),
                  prefixIcon: const Icon(
                    Icons.vpn_key_rounded,
                    color: Color(0xFFD4AF37),
                  ),
                ),
                obscureText: true,
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 32),
              if (_isLoading)
                const CircularProgressIndicator(color: Color(0xFFD4AF37))
              else
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD4AF37),
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _submit,
                    child: Text(
                      'دخول آمن',
                      style: GoogleFonts.amiri(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProjectManager {
  static FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  static FirebaseAuth get _auth => FirebaseAuth.instance;

  static CollectionReference get _projectsRef =>
      _firestore.collection('projects');

  static Future<void> saveProject(Project project) async {
    // 1. ALWAYS SAVE LOCALLY FIRST - ONLY EDITED ITEMS TO SAVE SPACE
    try {
      final prefs = await SharedPreferences.getInstance();

      // Create a lightweight project version for storage
      final lightweightProject = Project(
        id: project.id,
        name: project.name,
        userId: project.userId,
        theme: project.theme,
        sources: project.sources,
        verses: project.verses.where((v) => v.isEdited).toList(),
        tafsirs: project.tafsirs.where((t) => t.isEdited).toList(),
      );

      final jsonStr = jsonEncode(lightweightProject.toMap());
      await prefs.setString('last_project_data', jsonStr);
      debugPrint(
        'Project saved locally (diff only). Size: ${jsonStr.length} chars. Edited: ${lightweightProject.verses.length} verses, ${lightweightProject.tafsirs.length} tafsirs',
      );
    } catch (e) {
      debugPrint('Error saving project locally: $e');
    }

    // 2. SAVE TO CLOUD IF AVAILABLE (Keep full if needed, or diff depends on backend)
    if (!isFirebaseAvailable) return;
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      project.userId = user.uid;
      // SAVE TO CLOUD FIRESTORE
      await _projectsRef.doc(project.id).set(project.toMap());
      debugPrint('Project saved to cloud.');
    } catch (e) {
      debugPrint('Error saving project to cloud: $e');
    }
  }

  static Future<List<Project>> loadProjects() async {
    List<Project> projects = [];

    // 1. TRY LOADING FROM LOCAL STORAGE FIRST (Most up-to-date for offline work)
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString('last_project_data');
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final Map<String, dynamic> map = jsonDecode(jsonStr);
        projects.add(Project.fromMap(map));
        debugPrint('Loaded project from local storage.');
      }
    } catch (e) {
      debugPrint('Error loading project locally: $e');
    }

    // 2. TRY LOADING FROM CLOUD IF AVAILABLE
    if (isFirebaseAvailable) {
      final user = _auth.currentUser;
      if (user != null) {
        try {
          final snapshot = await _projectsRef
              .where('userId', isEqualTo: user.uid)
              .get();

          for (var doc in snapshot.docs) {
            final cloudProj = Project.fromMap(
              doc.data() as Map<String, dynamic>,
            );
            // If local version exists, maybe merge or prioritize?
            // For now, if same ID, local wins. If different, add both.
            if (!projects.any((p) => p.id == cloudProj.id)) {
              projects.add(cloudProj);
            }
          }
          debugPrint('Loaded projects from cloud.');
        } catch (e) {
          debugPrint('Error loading projects from cloud: $e');
        }
      }
    }

    return projects;
  }

  static Future<void> deleteProject(String id) async {
    try {
      await _projectsRef.doc(id).delete();
    } catch (e) {
      debugPrint('Error deleting project from cloud: $e');
    }
  }
}

class RichTextController extends TextEditingController {
  List<StyledChunk> chunks;

  RichTextController({required this.chunks})
    : super(text: chunks.map((c) => c.text).join());

  @override
  set value(TextEditingValue newValue) {
    if (newValue.text != text) {
      updateFromText(newValue.text);
    }
    super.value = newValue;
  }

  List<StyledChunk> getSelectedChunks() {
    final sel = selection;
    if (!sel.isValid || sel.isCollapsed) return [];
    final start = sel.start;
    final end = sel.end;
    List<StyledChunk> result = [];
    int currentPos = 0;
    for (var chunk in chunks) {
      int chunkEnd = currentPos + chunk.text.length;
      if (chunkEnd > start && currentPos < end) {
        int takeStart = start > currentPos ? start - currentPos : 0;
        int takeEnd = end < chunkEnd ? end - currentPos : chunk.text.length;
        result.add(
          StyledChunk(
            text: chunk.text.substring(takeStart, takeEnd),
            color: chunk.color,
            backgroundColor: chunk.backgroundColor,
            isBold: chunk.isBold,
            isItalic: chunk.isItalic,
            isUnderline: chunk.isUnderline,
            underlineColor: chunk.underlineColor,
          ),
        );
      }
      currentPos = chunkEnd;
    }
    return result;
  }

  void updateAll(List<StyledChunk> newChunks) {
    chunks = newChunks;
    final newText = newChunks.map((c) => c.text).join();
    super.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }

  void updateFromText(String newText) {
    if (newText == text) return;

    // Handle the case where the user clarifies the entire text
    if (newText.isEmpty) {
      chunks = [StyledChunk(text: '')];
      return;
    }

    // Basic heuristic: if one chunk, just update it
    if (chunks.length <= 1) {
      if (chunks.isEmpty) {
        chunks.add(StyledChunk(text: newText));
      } else {
        chunks[0].text = newText;
      }
      return;
    }

    // Advanced sync: if text changed, we try to see where the change happened
    // This is still a bit simple but handles basic Typing/Deleting
    int commonPrefix = 0;
    while (commonPrefix < text.length &&
        commonPrefix < newText.length &&
        text[commonPrefix] == newText[commonPrefix]) {
      commonPrefix++;
    }

    int commonSuffix = 0;
    while (commonSuffix < text.length - commonPrefix &&
        commonSuffix < newText.length - commonPrefix &&
        text[text.length - 1 - commonSuffix] ==
            newText[newText.length - 1 - commonSuffix]) {
      commonSuffix++;
    }

    // If prefix + suffix covers the whole change
    // This is a typical single-point edit
    int removedLength = text.length - commonPrefix - commonSuffix;
    int addedLength = newText.length - commonPrefix - commonSuffix;

    // We need to apply this to chunks
    List<StyledChunk> updatedChunks = [];
    int offset = 0;

    for (var chunk in chunks) {
      int chunkStart = offset;
      int chunkEnd = offset + chunk.text.length;

      // 1. Chunk is entirely before the change
      if (chunkEnd <= commonPrefix) {
        updatedChunks.add(chunk);
      }
      // 2. Chunk contains the start of the change or is within it
      else if (chunkStart < commonPrefix + removedLength ||
          (chunkStart == commonPrefix && chunkEnd == commonPrefix)) {
        // Prefix of this chunk before change
        if (chunkStart < commonPrefix) {
          updatedChunks.add(
            StyledChunk(
              text: chunk.text.substring(0, commonPrefix - chunkStart),
              color: chunk.color,
              backgroundColor: chunk.backgroundColor,
              isBold: chunk.isBold,
              isItalic: chunk.isItalic,
              isUnderline: chunk.isUnderline,
              underlineColor: chunk.underlineColor,
            ),
          );
        }

        // If this is the point where text was added, insert a placeholder or merge
        if (chunkStart <= commonPrefix && chunkEnd >= commonPrefix) {
          // We'll merge added text into the chunk at commonPrefix
          updatedChunks.add(
            StyledChunk(
              text: newText.substring(commonPrefix, commonPrefix + addedLength),
              color: chunk.color,
              backgroundColor: chunk.backgroundColor,
              isBold: chunk.isBold,
              isItalic: chunk.isItalic,
              isUnderline: chunk.isUnderline,
              underlineColor: chunk.underlineColor,
            ),
          );
        }

        // Suffix of this chunk after change
        if (chunkEnd > commonPrefix + removedLength) {
          updatedChunks.add(
            StyledChunk(
              text: chunk.text.substring(
                commonPrefix + removedLength - chunkStart,
              ),
              color: chunk.color,
              backgroundColor: chunk.backgroundColor,
              isBold: chunk.isBold,
              isItalic: chunk.isItalic,
              isUnderline: chunk.isUnderline,
              underlineColor: chunk.underlineColor,
            ),
          );
        }
      }
      // 3. Chunk is entirely after the change
      else {
        updatedChunks.add(chunk);
      }
      offset = chunkEnd;
    }

    // Cleanup: remove empty chunks and merge adjacent identicals
    List<StyledChunk> cleaned = [];
    for (var c in updatedChunks) {
      if (c.text.isNotEmpty) {
        if (cleaned.isNotEmpty &&
            cleaned.last.color == c.color &&
            cleaned.last.backgroundColor == c.backgroundColor &&
            cleaned.last.isBold == c.isBold &&
            cleaned.last.isItalic == c.isItalic &&
            cleaned.last.isUnderline == c.isUnderline &&
            cleaned.last.underlineColor == c.underlineColor) {
          cleaned.last.text += c.text;
        } else {
          cleaned.add(c);
        }
      }
    }
    if (cleaned.isEmpty) cleaned.add(StyledChunk(text: ''));

    chunks = cleaned;
  }

  void applyStyle({
    int? color,
    int? backgroundColor,
    bool? isBold,
    bool? isItalic,
    bool? isUnderline,
    bool toggleBold = false,
    bool toggleItalic = false,
    bool toggleUnderline = false,
    int? underlineColor,
    bool clearHighlight = false,
  }) {
    if (selection.isCollapsed) return;

    int start = selection.start;
    int end = selection.end;

    List<StyledChunk> newChunks = [];
    int currentOffset = 0;

    for (var chunk in chunks) {
      int chunkStart = currentOffset;
      int chunkEnd = currentOffset + chunk.text.length;

      // Check if this chunk overlaps with selection
      if (chunkEnd <= start || chunkStart >= end) {
        // No overlap
        newChunks.add(chunk);
      } else {
        // Overlap - split if necessary
        // 1. Prefix (before selection)
        if (chunkStart < start) {
          newChunks.add(
            StyledChunk(
              text: chunk.text.substring(0, start - chunkStart),
              color: chunk.color,
              backgroundColor: chunk.backgroundColor,
              isBold: chunk.isBold,
              isItalic: chunk.isItalic,
              isUnderline: chunk.isUnderline,
              underlineColor: chunk.underlineColor,
            ),
          );
        }

        // 2. Overlapping part
        int overlapStart = start > chunkStart ? start - chunkStart : 0;
        int overlapEnd = end < chunkEnd ? end - chunkStart : chunk.text.length;

        var middlePart = StyledChunk(
          text: chunk.text.substring(overlapStart, overlapEnd),
          color: color ?? chunk.color,
          backgroundColor: clearHighlight
              ? null
              : (backgroundColor ?? chunk.backgroundColor),
          isBold: toggleBold ? !chunk.isBold : (isBold ?? chunk.isBold),
          isItalic: toggleItalic
              ? !chunk.isItalic
              : (isItalic ?? chunk.isItalic),
          isUnderline: toggleUnderline
              ? !chunk.isUnderline
              : (isUnderline ?? chunk.isUnderline),
          underlineColor: underlineColor ?? chunk.underlineColor,
        );
        newChunks.add(middlePart);

        // 3. Suffix (after selection)
        if (chunkEnd > end) {
          newChunks.add(
            StyledChunk(
              text: chunk.text.substring(end - chunkStart),
              color: chunk.color,
              backgroundColor: chunk.backgroundColor,
              isBold: chunk.isBold,
              isItalic: chunk.isItalic,
              isUnderline: chunk.isUnderline,
              underlineColor: chunk.underlineColor,
            ),
          );
        }
      }
      currentOffset = chunkEnd;
    }

    // Merge adjacent identical chunks
    List<StyledChunk> merged = [];
    if (newChunks.isNotEmpty) {
      merged.add(newChunks[0]);
      for (int i = 1; i < newChunks.length; i++) {
        var prev = merged.last;
        var curr = newChunks[i];
        if (prev.color == curr.color &&
            prev.backgroundColor == curr.backgroundColor &&
            prev.isBold == curr.isBold &&
            prev.isItalic == curr.isItalic &&
            prev.isUnderline == curr.isUnderline &&
            prev.underlineColor == curr.underlineColor) {
          prev.text += curr.text;
        } else {
          merged.add(curr);
        }
      }
    }

    chunks = merged;
    notifyListeners();
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    List<TextSpan> children = [];
    for (var chunk in chunks) {
      children.add(
        TextSpan(
          text: chunk.text,
          style: style?.copyWith(
            color: Color(chunk.color),
            backgroundColor: chunk.backgroundColor != null
                ? Color(chunk.backgroundColor!)
                : null,
            fontWeight: chunk.isBold ? FontWeight.bold : FontWeight.normal,
            fontStyle: chunk.isItalic ? FontStyle.italic : FontStyle.normal,
            decoration: chunk.isUnderline
                ? TextDecoration.underline
                : TextDecoration.none,
            decorationColor: chunk.underlineColor != null
                ? Color(chunk.underlineColor!)
                : null,
            decorationThickness: 2.0,
          ),
        ),
      );
    }
    return TextSpan(style: style, children: children);
  }
}

class TafserEditorScreen extends StatefulWidget {
  const TafserEditorScreen({super.key});

  @override
  State<TafserEditorScreen> createState() => _TafserEditorScreenState();
}

class _TafserEditorScreenState extends State<TafserEditorScreen> {
  Project? currentProject;
  bool isEditMode = true;
  bool isLoading = true;
  final ScreenshotController _screenshotController = ScreenshotController();

  int itemsPerPage = 1;
  int currentPage = 0;
  late PageController _pageController;
  int? _bookmarkedPage;
  String _selectedSourceId = '1';
  final Map<String, Tafsir> _tafsirLookupMap = {};
  List<Verse> _activeVerses = [];

  // Search state
  bool _showSearchBar = false;
  final TextEditingController _searchSurahController = TextEditingController();
  final TextEditingController _searchAyahController = TextEditingController();
  final TextEditingController _searchJuzController = TextEditingController();

  @override
  void dispose() {
    _pageController.dispose();
    _searchSurahController.dispose();
    _searchAyahController.dispose();
    _searchJuzController.dispose();
    super.dispose();
  }

  Future<void> _takeScreenshot() async {
    try {
      final image = await _screenshotController.capture();
      if (image != null) {
        final verse = _activeVerses[currentPage];
        final shareText =
            'آية من سورة ${verse.surahName}:\n${verse.text}\n\nتمت المشاركة من تطبيق التفسير المختار';

        if (kIsWeb) {
          // Web-specific sharing/downloading
          await Share.shareXFiles(
            [
              XFile.fromData(
                image,
                name: 'screenshot.png',
                mimeType: 'image/png',
              ),
            ],
            text: shareText,
            subject: 'مشاركة آية وتفسير',
          );
        } else {
          // Mobile/Desktop with dart:io
          final directory = await getTemporaryDirectory();
          final imagePath = await io.File(
            '${directory.path}/screenshot.png',
          ).create();
          await imagePath.writeAsBytes(image);

          await Share.shareXFiles(
            [XFile(imagePath.path)],
            text: shareText,
            subject: 'مشاركة آية وتفسير',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء تصوير الشاشة: $e')),
        );
      }
    }
  }

  void _pairAndSyncUI() {
    if (currentProject == null) return;

    // Safety check: ensure lookup map is populated correctly
    if (_tafsirLookupMap.isEmpty) {
      for (var t in currentProject!.tafsirs) {
        final parts = t.id.split('_');
        if (parts.length >= 3) {
          final suffix = parts.skip(2).join('_');
          _tafsirLookupMap['${t.sourceId}_$suffix'] = t;
        }
      }
    }

    setState(() {
      _activeVerses = List.from(currentProject!.verses);
    });
  }

  Tafsir _getTafsirForVerse(Verse verse, [String? sourceId]) {
    final targetSourceId = sourceId ?? _selectedSourceId;
    // Suffix extraction logic: match how we populate the map
    final parts = verse.id.split('_');
    final idSuffix = parts.length >= 1 ? parts.skip(1).join('_') : verse.id;

    Tafsir? match;

    if (targetSourceId == '0') {
      // Chosen Interpretation logic
      if (verse.selectedTafsirId != null) {
        try {
          match = currentProject!.tafsirs.firstWhere(
            (t) => t.id == verse.selectedTafsirId,
          );
        } catch (_) {
          match = _tafsirLookupMap['1_$idSuffix'];
        }
      } else {
        // Default to Jalalayn if none chosen
        match = _tafsirLookupMap['1_$idSuffix'];
      }
    } else {
      // Standard sources
      match =
          _tafsirLookupMap['${targetSourceId}_$idSuffix'] ??
          _tafsirLookupMap['1_$idSuffix'];
    }

    return match ??
        Tafsir(
          id: 't_${targetSourceId}_$idSuffix',
          text: '...',
          sourceId: targetSourceId,
          styling: TextStyling(fontSize: 28),
        );
  }

  @override
  void initState() {
    super.initState();
    debugPrint('TafserEditorScreen initState');
    _pageController = PageController(initialPage: currentPage);
    _loadInitialData();
    _loadBookmark();
  }

  Widget _buildSourceToggle(String label, String sourceId) {
    bool isSelected = _selectedSourceId == sourceId;
    return GestureDetector(
      onTap: () {
        if (!isSelected) {
          setState(() {
            _selectedSourceId = sourceId;
            // No need to reload all data, just re-pair current verses with new source
            _pairAndSyncUI();
          });
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.brown.shade700
              : Colors.white.withOpacity(0.8),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.brown.shade700 : Colors.brown.shade300,
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          style: GoogleFonts.notoKufiArabic(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : Colors.brown.shade800,
          ),
        ),
      ),
    );
  }

  Future<void> _loadBookmark() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _bookmarkedPage = prefs.getInt('bookmark_page');
    });
  }

  Future<void> _saveBookmark() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('bookmark_page', currentPage);
    if (!mounted) return;
    setState(() {
      _bookmarkedPage = currentPage;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'تم حفظ الختم (الإشارة المرجعية) بنجاح',
          textAlign: TextAlign.right,
        ),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _jumpToBookmark() {
    if (_bookmarkedPage != null) {
      _pageController.animateToPage(
        _bookmarkedPage!,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('لا يوجد ختم محفوظ')));
    }
  }

  Future<void> _loadInitialData() async {
    // Optimization: Ensure lookup map is populated
    if (currentProject != null && currentProject!.verses.isNotEmpty) {
      if (_tafsirLookupMap.isEmpty) {
        _tafsirLookupMap.clear();
        for (var t in currentProject!.tafsirs) {
          _tafsirLookupMap['${t.sourceId}_${t.id.split('_').last}'] = t;
        }
      }
      _pairAndSyncUI();
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    int lastPage = prefs.getInt('last_viewed_page') ?? 0;

    final projects = await ProjectManager.loadProjects();

    Project project;
    if (projects.isEmpty ||
        (projects.isNotEmpty &&
            projects.first.verses.isEmpty &&
            projects.first.tafsirs.isEmpty)) {
      project = _seedAlFatiha();
    } else {
      project = projects.firstWhere(
        (p) => p.name == 'التفسير المختار' || p.name == 'التفسير الميسر',
        orElse: () => projects.first,
      );
    }

    // The Quran has 6236 verses. If we have verses and tafsirs for both sources, it's complete.
    if (project.verses.length >= 6200 && project.tafsirs.length >= 12400) {
      // Data already loaded
    } else {
      // === FULL PROCESSING: First run or incomplete data ===
      bool updated = false;

      // 1. Surah names
      final List<String> surahNames = [
        'الفاتحة',
        'البقرة',
        'آل عمران',
        'النساء',
        'المائدة',
        'الأنعام',
        'الأعراف',
        'الأنفال',
        'التوبة',
        'يونس',
        'هود',
        'يوسف',
        'الرعد',
        'إبراهيم',
        'الحجر',
        'النحل',
        'الإسراء',
        'الكهف',
        'مريم',
        'طه',
        'الأنبياء',
        'الحج',
        'المؤمنون',
        'النور',
        'الفرقان',
        'الشعراء',
        'النمل',
        'القصص',
        'العنكبوت',
        'الروم',
        'لقمان',
        'السجدة',
        'الأحزاب',
        'سبأ',
        'فاطر',
        'يس',
        'الصافات',
        'ص',
        'الزمر',
        'غافر',
        'فصلت',
        'الشورى',
        'الزخرف',
        'الدخان',
        'الجاثية',
        'الأحقاف',
        'محمد',
        'الفتح',
        'الحجرات',
        'ق',
        'الذاريات',
        'الطور',
        'النجم',
        'القمر',
        'الرحمن',
        'الواقعة',
        'الحديد',
        'المجادلة',
        'الحشر',
        'الممتحنة',
        'الصف',
        'الجمعة',
        'المنافقون',
        'التغابن',
        'الطلاق',
        'التحريم',
        'الملك',
        'القلم',
        'الحاقة',
        'المعارج',
        'نوح',
        'الجن',
        'المزمل',
        'المدثر',
        'القيامة',
        'الإنسان',
        'المرسلات',
        'النبأ',
        'النازعات',
        'عبس',
        'التكوير',
        'الانفطار',
        'المطففين',
        'الانشقاق',
        'البروج',
        'الطارق',
        'الأعلى',
        'الغاشية',
        'الفجر',
        'البلد',
        'الشمس',
        'الليل',
        'الضحى',
        'الشرح',
        'التين',
        'العلق',
        'القدر',
        'البينة',
        'الزلزلة',
        'العاديات',
        'القارعة',
        'التكاثر',
        'العصر',
        'الهمزة',
        'الفيل',
        'قريش',
        'الماعون',
        'الكوثر',
        'الكافرون',
        'النصر',
        'المسد',
        'الإخلاص',
        'الفلق',
        'الناس',
      ];

      // 2. Juz boundaries
      final List<Map<String, dynamic>> juzBoundaries = [
        {'juz': 1, 'surah': 'الفاتحة', 'verse': 1},
        {'juz': 2, 'surah': 'البقرة', 'verse': 142},
        {'juz': 3, 'surah': 'البقرة', 'verse': 253},
        {'juz': 4, 'surah': 'آل عمران', 'verse': 93},
        {'juz': 5, 'surah': 'النساء', 'verse': 24},
        {'juz': 6, 'surah': 'النساء', 'verse': 148},
        {'juz': 7, 'surah': 'المائدة', 'verse': 82},
        {'juz': 8, 'surah': 'الأنعام', 'verse': 111},
        {'juz': 9, 'surah': 'الأعراف', 'verse': 88},
        {'juz': 10, 'surah': 'الأنفال', 'verse': 41},
        {'juz': 11, 'surah': 'التوبة', 'verse': 93},
        {'juz': 12, 'surah': 'هود', 'verse': 1},
        {'juz': 13, 'surah': 'يوسف', 'verse': 53},
        {'juz': 14, 'surah': 'الحجر', 'verse': 1},
        {'juz': 15, 'surah': 'الإسراء', 'verse': 1},
        {'juz': 16, 'surah': 'الكهف', 'verse': 75},
        {'juz': 17, 'surah': 'الأنبياء', 'verse': 1},
        {'juz': 18, 'surah': 'المؤمنون', 'verse': 1},
        {'juz': 19, 'surah': 'الفرقان', 'verse': 21},
        {'juz': 20, 'surah': 'النمل', 'verse': 56},
        {'juz': 21, 'surah': 'العنكبوت', 'verse': 46},
        {'juz': 22, 'surah': 'الأحزاب', 'verse': 31},
        {'juz': 23, 'surah': 'يس', 'verse': 28},
        {'juz': 24, 'surah': 'الزمر', 'verse': 32},
        {'juz': 25, 'surah': 'فصلت', 'verse': 47},
        {'juz': 26, 'surah': 'الأحقاف', 'verse': 1},
        {'juz': 27, 'surah': 'الذاريات', 'verse': 31},
        {'juz': 28, 'surah': 'المجادلة', 'verse': 1},
        {'juz': 29, 'surah': 'الملك', 'verse': 1},
        {'juz': 30, 'surah': 'النبأ', 'verse': 1},
      ];

      // 3. Helper function
      int getJuzForVerse(String surahName, int verseNumber) {
        for (int i = juzBoundaries.length - 1; i >= 0; i--) {
          final b = juzBoundaries[i];
          final bSurahIndex = surahNames.indexOf(b['surah']);
          final targetSurahIndex = surahNames.indexOf(surahName);

          if (targetSurahIndex > bSurahIndex) return b['juz'];
          if (targetSurahIndex == bSurahIndex && verseNumber >= b['verse']) {
            return b['juz'];
          }
        }
        return 1;
      }

      // 4. Processing logic
      void processSurahData(
        List<Map<String, String>> data,
        String surahName,
        String shortId,
        String sourceId,
      ) {
        for (var entry in data) {
          String vNum = entry['n'] ?? '';
          String targetVerseText = entry['v'] ?? '';
          String targetTafsir = entry['t'] ?? '';

          if (vNum.isNotEmpty) {
            final verseIdx = project.verses.indexWhere(
              (v) => v.surahName == surahName && v.verseNumber == vNum,
            );

            String vIdSuffix;
            if (verseIdx == -1) {
              vIdSuffix =
                  '${DateTime.now().millisecondsSinceEpoch}_$shortId$vNum';
              final verse = Verse(
                id: 'v_$vIdSuffix',
                surahName: surahName,
                verseNumber: vNum,
                text: targetVerseText,
                styling: TextStyling(
                  fontFamily: 'AlQalamQuranMajeed2',
                  fontSize: 30,
                  isBold: true,
                ),
              );
              verse.juz = getJuzForVerse(surahName, int.tryParse(vNum) ?? 1);
              project.verses.add(verse);
              updated = true;
              project.tafsirs.add(
                Tafsir(
                  id: 't_${sourceId}_$vIdSuffix',
                  text: targetTafsir,
                  sourceId: sourceId,
                  styling: TextStyling(fontSize: 28),
                ),
              );
            } else {
              vIdSuffix = project.verses[verseIdx].id.substring(2);
              if (sourceId == '1') {
                project.verses[verseIdx].text = targetVerseText;
              }
              int tIdx = project.tafsirs.indexWhere(
                (t) => t.sourceId == sourceId && t.id.endsWith(vIdSuffix),
              );
              if (tIdx == -1) {
                project.tafsirs.add(
                  Tafsir(
                    id: 't_${sourceId}_$vIdSuffix',
                    text: targetTafsir,
                    sourceId: sourceId,
                    styling: TextStyling(fontSize: 28),
                  ),
                );
                updated = true;
              } else if (project.tafsirs[tIdx].text.isEmpty ||
                  project.tafsirs[tIdx].text == '...') {
                project.tafsirs[tIdx].text = targetTafsir;
                updated = true;
              }
            }
          }
        }
      }

      for (int i = 0; i < allSurahsData.length; i++) {
        String sName = surahNames[i];
        String shortId = "S${i + 1}";
        processSurahData(allSurahsData[i], sName, shortId, '1'); // Jalalayn
      }

      // Removed Muyassar and Ghareeb data processing blocks

      if (updated) {
        await ProjectManager.saveProject(project);
      }
    } // End of full processing block

    // --- Data Sanitization ---
    // Remove any verses that have garbled names (remnants of encoding issues)
    final allowedSurahs = [
      'الفاتحة',
      'البقرة',
      'آل عمران',
      'النساء',
      'المائدة',
      'الأنعام',
      'الأعراف',
      'الأنفال',
      'التوبة',
      'يونس',
      'هود',
      'يوسف',
      'الرعد',
      'إبراهيم',
      'الحجر',
      'النحل',
      'الإسراء',
      'الكهف',
      'مريم',
      'طه',
      'الأنبياء',
      'الحج',
      'المؤمنون',
      'النور',
      'الفرقان',
      'الشعراء',
      'النمل',
      'القصص',
      'العنكبوت',
      'الروم',
      'لقمان',
      'السجدة',
      'الأحزاب',
      'سبأ',
      'فاطر',
      'يس',
      'الصافات',
      'ص',
      'الزمر',
      'غافر',
      'فصلت',
      'الشورى',
      'الزخرف',
      'الدخان',
      'الجاثية',
      'الأحقاف',
      'محمد',
      'الفتح',
      'الحجرات',
      'ق',
      'الذاريات',
      'الطور',
      'النجم',
      'القمر',
      'الرحمن',
      'الواقعة',
      'الحديد',
      'المجادلة',
      'الحشر',
      'الممتحنة',
      'الصف',
      'الجمعة',
      'المنافقون',
      'التغابن',
      'الطلاق',
      'التحريم',
      'الملك',
      'القلم',
      'الحاقة',
      'المعارج',
      'نوح',
      'الجن',
      'المزمل',
      'المدثر',
      'القيامة',
      'الإنسان',
      'المرسلات',
      'النبأ',
      'النازعات',
      'عبس',
      'التكوير',
      'الانفطار',
      'المطففين',
      'الانشقاق',
      'البروج',
      'الطارق',
      'الأعلى',
      'الغاشية',
      'الفجر',
      'البلد',
      'الشمس',
      'الليل',
      'الضحى',
      'الشرح',
      'التين',
      'العلق',
      'القدر',
      'البينة',
      'الزلزلة',
      'العاديات',
      'القارعة',
      'التكاثر',
      'العصر',
      'الهمزة',
      'الفيل',
      'قريش',
      'الماعون',
      'الكوثر',
      'الكافرون',
      'النصر',
      'المسد',
      'الإخلاص',
      'الفلق',
      'الناس',
    ];
    final allowedSurahNorm = allowedSurahs
        .map((s) => normalizeArabic(s))
        .toList();
    int originalCount = project.verses.length;
    project.verses.removeWhere(
      (v) => !allowedSurahNorm.contains(normalizeArabic(v.surahName)),
    );
    if (project.verses.length != originalCount) {
      // Clean up orphaned tafsirs too
      final validVerseIds = project.verses
          .map((v) => v.id.substring(2))
          .toSet();
      project.tafsirs.removeWhere(
        (t) => !validVerseIds.contains(
          t.id.substring(2).split('_').last,
        ), // Adjusted to match vIdSuffix
      );
      await ProjectManager.saveProject(project);
    }

    // Fix old Basmalah verse number
    for (var v in project.verses) {
      if (v.surahName == 'الفاتحة' && v.verseNumber == '0') {
        v.verseNumber = '1';
        await ProjectManager.saveProject(project);
      }
    }

    // --- Faster Pairing & Filtering ---
    _tafsirLookupMap.clear();
    for (var t in project.tafsirs) {
      final parts = t.id.split('_');
      if (parts.length >= 3) {
        final suffix = parts.skip(2).join('_');
        _tafsirLookupMap['${t.sourceId}_$suffix'] = t;
      }
    }

    setState(() {
      currentProject = project;

      final surahOrder = [
        'الفاتحة',
        'البقرة',
        'آل عمران',
        'النساء',
        'المائدة',
        'الأنعام',
        'الأعراف',
        'الأنفال',
        'التوبة',
        'يونس',
        'هود',
        'يوسف',
        'الرعد',
        'إبراهيم',
        'الحجر',
        'النحل',
        'الإسراء',
        'الكهف',
        'مريم',
        'طه',
        'الأنبياء',
        'الحج',
        'المؤمنون',
        'النور',
        'الفرقان',
        'الشعراء',
        'النمل',
        'القصص',
        'العنكبوت',
        'الروم',
        'لقمان',
        'السجدة',
        'الأحزاب',
        'سبأ',
        'فاطر',
        'يس',
        'الصافات',
        'ص',
        'الزمر',
        'غافر',
        'فصلت',
        'الشورى',
        'الزخرف',
        'الدخان',
        'الجاثية',
        'الأحقاف',
        'محمد',
        'الفتح',
        'الحجرات',
        'ق',
        'الذاريات',
        'الطور',
        'النجم',
        'القمر',
        'الرحمن',
        'الواقعة',
        'الحديد',
        'المجادلة',
        'الحشر',
        'الممتحنة',
        'الصف',
        'الجمعة',
        'المنافقون',
        'التغابن',
        'الطلاق',
        'التحريم',
        'الملك',
        'القلم',
        'الحاقة',
        'المعارج',
        'نوح',
        'الجن',
        'المزمل',
        'المدثر',
        'القيامة',
        'الإنسان',
        'المرسلات',
        'النبأ',
        'النازعات',
        'عبس',
        'التكوير',
        'الانفطار',
        'المطففين',
        'الانشقاق',
        'البروج',
        'الطارق',
        'الأعلى',
        'الغاشية',
        'الفجر',
        'البلد',
        'الشمس',
        'الليل',
        'الضحى',
        'الشرح',
        'التين',
        'العلق',
        'القدر',
        'البينة',
        'الزلزلة',
        'العاديات',
        'القارعة',
        'التكاثر',
        'العصر',
        'الهمزة',
        'الفيل',
        'قريش',
        'الماعون',
        'الكوثر',
        'الكافرون',
        'النصر',
        'المسد',
        'الإخلاص',
        'الفلق',
        'الناس',
      ];
      final normOrder = surahOrder.map((s) => normalizeArabic(s)).toList();

      List<Verse> pairedVerses = [];
      List<Tafsir> pairedTafsirs = [];

      for (var verse in currentProject!.verses) {
        String idSuffix = verse.id.substring(2); // Remove "v_"

        // Exact match for selected source
        Tafsir? matchingTafsir =
            _tafsirLookupMap['${_selectedSourceId}_$idSuffix'];

        // Fallback: if no tafsir for selected source, try source '1' then 'any'
        matchingTafsir ??= _tafsirLookupMap['1_$idSuffix'];

        if (matchingTafsir == null) {
          matchingTafsir = Tafsir(
            id: 't_${_selectedSourceId}_$idSuffix',
            text: '...',
            sourceId: _selectedSourceId,
            styling: TextStyling(fontSize: 28),
          );
        }

        // Safety: ensure chunks are never empty
        if (verse.chunks.isEmpty) {
          verse.chunks = [
            StyledChunk(text: verse.text, isBold: true, color: 0xFF000000),
          ];
        }
        if (matchingTafsir.chunks.isEmpty) {
          matchingTafsir.chunks = [
            StyledChunk(text: matchingTafsir.text, color: 0xFF000000),
          ];
        }

        // Ensure alignment is centered
        verse.styling.alignment = 'center';
        matchingTafsir.styling.alignment = 'center';

        pairedVerses.add(verse);
        pairedTafsirs.add(matchingTafsir);
      }

      _activeVerses = pairedVerses;

      // Pre-calculate surah indices for faster sorting
      final Map<String, int> surahOrderMap = {};
      for (int i = 0; i < normOrder.length; i++) {
        surahOrderMap[normOrder[i]] = i;
      }

      // Sort by surah order then ayah number
      List<int> indices = List.generate(_activeVerses.length, (i) => i);
      indices.sort((i, j) {
        final vA = _activeVerses[i];
        final vB = _activeVerses[j];

        int sA = surahOrderMap[normalizeArabic(vA.surahName)] ?? 999;
        int sB = surahOrderMap[normalizeArabic(vB.surahName)] ?? 999;

        if (sA != sB) return sA.compareTo(sB);
        return (int.tryParse(vA.verseNumber) ?? 0).compareTo(
          int.tryParse(vB.verseNumber) ?? 0,
        );
      });

      _activeVerses = indices.map((i) => _activeVerses[i]).toList();
      isLoading = false;

      // Sync page controller if needed
      int maxPages = (_activeVerses.length / itemsPerPage).ceil();
      if (lastPage < maxPages) {
        currentPage = lastPage;
      } else if (currentPage >= maxPages && maxPages > 0) {
        currentPage = maxPages - 1;
      }

      if (_pageController.hasClients) {
        _pageController.jumpToPage(currentPage);
      }
    });
  }

  Project _seedAlFatiha() {
    final newId = DateTime.now().millisecondsSinceEpoch.toString();

    final project = Project(
      id: newId,
      name: 'برنامج عمل التفسير',
      sources: [
        Source(id: '0', name: 'برنامج عمل التفسير'),
        Source(id: '1', name: 'الجلالين'),
        Source(id: '2', name: 'الميسر'),
        Source(id: '3', name: 'غريب القرآن'),
        Source(id: '4', name: 'جامع البيان'),
        Source(id: '5', name: 'الوجيز'),
      ],
      verses: [],
      tafsirs: [],
      theme: {
        'backgroundColor': 0xFFFDFCF0,
        'borderColor': 0xFF8FCB5B,
        'sideColor': 0xFF8FCB5B,
        'type': 'manuscript',
      },
    );

    final List<Map<String, String>> initialDataFatiha = [
      {
        's': 'الفاتحة',
        'n': '1',
        'v': 'بِسۡمِ ٱللَّهِ ٱلرَّحۡمَـٰنِ ٱلرَّحِیمِ',
        't':
            'بِسۡمِ ٱللَّهِ ٱلرَّحۡمَـٰنِ ٱلرَّحِیمِ', // Use Arabic for Tafsir too if it's Basmalah
      },
      {
        's': 'الفاتحة',
        'n': '2',
        'v': 'ٱلۡحَمۡدُ لِلَّهِ رَبِّ ٱلۡعَـٰلَمِینَ',
        't':
            'الثناء على الله بصفاته التي كلُّها أوصاف كمال، وبنعمه الظاهرة والباطنة، الدينية والدنيوية، وفي ضمنه أَمْرٌ لعباده أن يحمدوه، فهو المستحق له وحده، وهو سبحانه المنشئ للخلق، القائم بأمورهم، المربي لجميع خلقه بنعمه، ولأوليائه بالإيمان والعمل الصالح.',
      },
      {
        's': 'الفاتحة',
        'n': '3',
        'v': 'ٱلرَّحۡمَـٰنِ ٱلرَّحِیمِ',
        't':
            '﴿ٱلرَّحۡمَٰنِ﴾ ذي الرحمة العامة الذي وسعت رحمته جميع الخلق، ﴿ٱلرَّحِيمِ﴾ بالمؤمنين، وهما اسمان من أسماء الله تعالى.',
      },
      {
        's': 'الفاتحة',
        'n': '4',
        'v': 'مَـٰلِكِ یَوۡمِ ٱلدِّینِ',
        't':
            'وهو سبحانه وحده مالك يوم القيامة، وهو يوم الجزاء على الأعمال، وفي قراءة المسلم لهذه الآية في كل ركعة من صلواته تذكير له باليوم الآخر، وحثٌّ له على الاستعداد بالعمل الصالح، والكف عن المعاصي والسيئات.',
      },
      {
        's': 'الفاتحة',
        'n': '5',
        'v': 'إِیَّاكَ نَعۡبُدُ وَإِیَّاكَ نَسۡتَعِینُ',
        't':
            'إنا نخصك وحدك بالعبادة، ونستعين بك وحدك في جميع أمورنا، فالأمر كله بيدك، لا يملك منه أحد مثقال ذرة، وفي هذه الآية دليل على أن العبد لا يجوز له أن يصرف شيئًا من أنواع العبادة كالدعاء، والاستغاثة، والذبح، والطواف إلا لله وحده، وفيها شفاء القلوب من داء التعلق بغير الله، ومن أمراض الرياء، والعجب، والكبرياء.',
      },
      {
        's': 'الفاتحة',
        'n': '6',
        'v': 'ٱهۡدِنَا ٱلصِّرَ ٰطَ ٱلۡمُسۡتَقِیمَ',
        't':
            'دُلَّنا وأرشدنا، ووفقنا إلى الطريق المستقيم، وثبتنا عليه حتى نلقاك، وهو الإسلام الذي هو الطريق الواضح الموصل إلى رضوان الله وإلى جنته، الذي دلَّ عليه خاتم رسله وأنبيائه محمد ﷺ، فلا سبيل إلى سعادة العبد إلا بالاستقامة عليه.',
      },
      {
        's': 'الفاتحة',
        'n': '7',
        'v':
            'صِرَ ٰطَ ٱلَّذِینَ أَنۡعَمۡتَ عَلَیۡهِمۡ غَیۡرِ ٱلۡمَغۡضُوبِ عَلَیۡهِمۡ وَلَا ٱلضَّاۤلِّینَ',
        't':
            'طريق الذين أنعمت عليهم، من النبيين والصدِّيقين والشهداء والصالحين، فهم أهل الهداية والاستقامة، ولا تجعلنا ممن سلك طريق المغضوب عليهم، الذين عرفوا الحق ولم يعملوا به، وهم اليهود، ومن كان على شاكلتهم، ولا تجعلنا من الضالين، وهم الذين لم يهتدوا عن جهل منهم، فضلوا الطريق، وهم النصارى، ومن اتبع سنتهم، وفي هذا الدعاء شفاء لقلب المسلم من مرض الجحود والجهل والضلال، ودلالة على أن أعظم نعمة على الإطلاق هي نعمة الإسلام، فمن كان أعرف للحق وأتبع له، كان أولى بالصراط المستقيم، ولا ريب أن أصحاب رسول الله ﷺ هم أولى الناس بذلك بعد الأنبياء عليهم السلام، فدلت الآية على فضلهم، وعظيم منزلتهم، رضي الله عنهم، ويستحب للقارئ أن يقول في الصلاة بعد قراءة الفاتحة: (آمين)، ومعناها: اللهم استجب، وليست آية من سورة الفاتحة باتفاق العلماء؛ ولهذا أجمعوا على عدم كتابتها في المصاحف.',
      },
    ];

    for (var entry in initialDataFatiha) {
      final vIdSuffix = '${newId}_${project.verses.length + 1}';
      final vId = 'v_$vIdSuffix';
      project.verses.add(
        Verse(
          id: vId,
          surahName: entry['s']!,
          verseNumber: entry['n']!,
          text: entry['v']!,
          juz: 1,
          styling: TextStyling(
            fontFamily: 'AlqalamQuranMajeed2',
            fontSize: 30,
            isBold: true,
          ),
        ),
      );

      // Add Tafsir for Jalalayn (Source ID: '1')
      String jalalaynTafsirText = entry['t']!;
      try {
        final jalalMatch = surah1Data.firstWhere((j) => j['n'] == entry['n']);
        jalalaynTafsirText = jalalMatch['t']!;
      } catch (_) {
        // Fallback to default if not found in surah1Data
      }
      project.tafsirs.add(
        Tafsir(
          id: 't_1_$vIdSuffix',
          text: jalalaynTafsirText,
          sourceId: '1',
          styling: TextStyling(fontSize: 28),
        ),
      );
    }

    return project;
  }

  Future<void> _saveCurrentProject() async {
    if (currentProject != null) {
      await ProjectManager.saveProject(currentProject!);
      if (mounted) {
        String message = 'تم حفظ المشروع محلياً';
        if (isFirebaseAvailable && FirebaseAuth.instance.currentUser != null) {
          message = 'تم حفظ المشروع محلياً وسحابياً';
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    }
  }

  // — Edit Dialog with per-word formatting —
  void _showEditDialog(Verse verse, Tafsir tafsir) {
    _showSingleEditDialog(verse, 'تعديل الآية', isVerse: true);
  }

  void _showTafsirEditDialog(Verse verse, Tafsir tafsir) {
    _showSingleEditDialog(tafsir, 'تعديل التفسير', isVerse: false);
  }

  void _showSingleEditDialog(
    dynamic item, // Can be Verse or Tafsir
    String title, {
    required bool isVerse,
  }) {
    final richController = RichTextController(
      chunks: (item.chunks as List<dynamic>)
          .map(
            (c) => StyledChunk(
              text: c.text,
              color: c.color,
              backgroundColor: c.backgroundColor,
              isBold: c.isBold,
              isItalic: c.isItalic,
              isUnderline: c.isUnderline,
              underlineColor: c.underlineColor,
            ),
          )
          .toList(),
    );

    double fontSize = item.styling.fontSize;
    bool isBold = item.styling.isBold;
    String fontFamily =
        item.styling.fontFamily ??
        (isVerse ? 'AlqalamQuranMajeed2' : 'AmiriCustom');

    final focusNode = FocusNode();

    final mushafFonts = <String, String>{
      'AlqalamQuranMajeed2': 'القلم قرآن مجيد ٢',
      'AlqalamQuranMajeed': 'القلم قرآن مجيد',
      'AlQuranAlKareem': 'القرآن الكريم',
      'UthmanicHafs': 'عثماني حفص',
      'AlMushaf': 'المصحف',
      'AmiriQuran': 'أميري قرآن',
      'QuranTaha': 'قرآن طه',
      'AmiriBold': 'أميري عريض',
      'AmiriCustom': 'أميري',
    };

    final tafsirFonts = <String, String>{
      'AmiriCustom': 'أميري',
      'AmiriBold': 'أميري عريض',
      'AmiriQuran': 'أميري قرآن',
      'AlqalamQuranMajeed2': 'القلم قرآن مجيد ٢',
      'AlqalamQuranMajeed': 'القلم قرآن مجيد',
      'UthmanicHafs': 'عثماني حفص',
    };

    final textColors = <Color>[
      Colors.black,
      const Color(0xFF1B1B1B),
      const Color(0xFF5D4037),
      Colors.red,
      Colors.red.shade900,
      Colors.blue,
      Colors.blue.shade900,
      Colors.green,
      Colors.green.shade900,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      const Color(0xFFD4AF37),
    ];

    final hlColors = <Color>[
      Colors.yellow.shade200,
      Colors.yellow.shade400,
      Colors.lightGreen.shade200,
      Colors.lightGreen.shade400,
      Colors.cyan.shade100,
      Colors.cyan.shade300,
      Colors.pink.shade100,
      Colors.pink.shade300,
      Colors.orange.shade100,
      Colors.purple.shade100,
    ];

    // Add listener for state update
    richController.addListener(() {
      item.text = richController.text;
      item.chunks = richController.chunks;
      if (item is Verse || item is Tafsir) {
        item.isEdited = true;
      }
      setState(() {}); // Update main UI in real-time
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlg) {
          final fonts = isVerse ? mushafFonts : tafsirFonts;

          return Directionality(
            textDirection: TextDirection.rtl,
            child: Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              backgroundColor: const Color(0xFFFDFCF0),
              child: Container(
                width: 700,
                padding: const EdgeInsets.all(24),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header with Save/Cancel
                      Row(
                        children: [
                          Icon(
                            isVerse ? Icons.menu_book : Icons.description,
                            color: const Color(0xFF5D4037),
                            size: 28,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            title,
                            style: const TextStyle(
                              fontFamily: 'AmiriBold',
                              fontSize: 22,
                              color: Color(0xFF5D4037),
                            ),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text(
                              'إلغاء',
                              style: TextStyle(
                                color: Color(0xFF5D4037),
                                fontSize: 16,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            icon: const Icon(
                              Icons.save,
                              color: Colors.white,
                              size: 18,
                            ),
                            label: const Text(
                              'حفظ',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4CAF50),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () {
                              setState(() {
                                item.styling.fontSize = fontSize;
                                item.styling.isBold = isBold;
                                item.styling.fontFamily = fontFamily;
                                if (item is Verse || item is Tafsir) {
                                  item.isEdited = true;
                                }
                              });
                              _saveCurrentProject(); // Manual save on button press
                              Navigator.pop(ctx);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Toolbar
                      Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isVerse
                                ? const Color(0xFF4CAF50)
                                : const Color(0xFF2196F3),
                          ),
                        ),
                        child: Column(
                          children: [
                            Wrap(
                              spacing: 4,
                              runSpacing: 4,
                              alignment: WrapAlignment.center,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                _toolBtn(Icons.text_increase, 'تكبير', () {
                                  setDlg(() {
                                    fontSize += 2;
                                    item.styling.fontSize = fontSize;
                                  });
                                  setState(() {});
                                }),
                                _toolBtn(Icons.text_decrease, 'تصغير', () {
                                  setDlg(() {
                                    fontSize -= 2;
                                    item.styling.fontSize = fontSize;
                                  });
                                  setState(() {});
                                }),
                                _toolBtn(Icons.format_bold, 'عريض شامل', () {
                                  setDlg(() {
                                    isBold = !isBold;
                                    item.styling.isBold = isBold;
                                  });
                                  setState(() {});
                                }, isActive: isBold),
                                _toolBtn(Icons.format_bold, 'عريض محدد', () {
                                  richController.applyStyle(toggleBold: true);
                                  focusNode.requestFocus();
                                  setDlg(() {});
                                  setState(() {});
                                }),
                                _toolBtn(
                                  Icons.format_underlined,
                                  'تسطير محدد',
                                  () {
                                    richController.applyStyle(
                                      toggleUnderline: true,
                                    );
                                    focusNode.requestFocus();
                                    setDlg(() {});
                                    setState(() {});
                                  },
                                ),
                                // Underline Color selection dots
                                ...[
                                  const Color(0xFFFF5252),
                                  const Color(0xFF448AFF),
                                  const Color(0xFF69F0AE),
                                  const Color(0xFFFFAB40),
                                  const Color(0xFFE040FB),
                                ].map(
                                  (c) => InkWell(
                                    onTap: () {
                                      richController.applyStyle(
                                        underlineColor: c.toARGB32(),
                                        isUnderline: true,
                                      );
                                      focusNode.requestFocus();
                                      setDlg(() {});
                                      setState(() {});
                                    },
                                    child: Container(
                                      width: 14,
                                      height: 14,
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 1.5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: c,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 0.5,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: DropdownButton<String>(
                                    value: fontFamily,
                                    isDense: true,
                                    underline: const SizedBox(),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF5D4037),
                                    ),
                                    items: fonts.entries
                                        .map(
                                          (e) => DropdownMenuItem(
                                            value: e.key,
                                            child: Text(
                                              e.value,
                                              style: TextStyle(
                                                fontFamily: e.key,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (val) {
                                      if (val != null) {
                                        setDlg(() {
                                          fontFamily = val;
                                          item.styling.fontFamily = val;
                                        });
                                        setState(() {});
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 12),
                            // Text Colors per word
                            Wrap(
                              spacing: 3,
                              runSpacing: 4,
                              alignment: WrapAlignment.center,
                              children: [
                                const Text(
                                  'لون الكلمة:',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey,
                                  ),
                                ),
                                ...textColors.map(
                                  (c) => InkWell(
                                    onTap: () {
                                      richController.applyStyle(
                                        color: c.toARGB32(),
                                      );
                                      focusNode.requestFocus();
                                      setDlg(() {});
                                      setState(() {});
                                    },
                                    child: Container(
                                      width: 26,
                                      height: 26,
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 1,
                                      ),
                                      decoration: BoxDecoration(
                                        color: c,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.grey.shade300,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            // Highlight per word
                            Wrap(
                              spacing: 3,
                              runSpacing: 4,
                              alignment: WrapAlignment.center,
                              children: [
                                const Text(
                                  'تظليل:',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey,
                                  ),
                                ),
                                Tooltip(
                                  message: 'إزالة التظليل',
                                  child: InkWell(
                                    onTap: () {
                                      richController.applyStyle(
                                        clearHighlight: true,
                                      );
                                      focusNode.requestFocus();
                                      setDlg(() {});
                                      setState(() {});
                                    },
                                    child: Container(
                                      width: 26,
                                      height: 26,
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 1,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                          color: Colors.grey.shade400,
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.format_color_reset,
                                        size: 14,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                ),
                                ...hlColors.map(
                                  (c) => InkWell(
                                    onTap: () {
                                      richController.applyStyle(
                                        backgroundColor: c.toARGB32(),
                                      );
                                      focusNode.requestFocus();
                                      setDlg(() {});
                                      setState(() {});
                                    },
                                    child: Container(
                                      width: 26,
                                      height: 26,
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 1,
                                      ),
                                      decoration: BoxDecoration(
                                        color: c,
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                          color: Colors.grey.shade400,
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.format_color_fill,
                                        size: 14,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 12),
                            Wrap(
                              spacing: 8,
                              alignment: WrapAlignment.center,
                              children: [
                                _toolBtn(Icons.content_cut, 'قص', () {
                                  final sel = richController.selection;
                                  if (sel.isValid && !sel.isCollapsed) {
                                    Clipboard.setData(
                                      ClipboardData(
                                        text: richController.text.substring(
                                          sel.start,
                                          sel.end,
                                        ),
                                      ),
                                    );
                                    setDlg(() {
                                      richController.text = richController.text
                                          .replaceRange(sel.start, sel.end, '');
                                    });
                                    setState(() {});
                                  }
                                }),
                                _toolBtn(Icons.content_copy, 'نسخ', () {
                                  final sel = richController.selection;
                                  if (sel.isValid && !sel.isCollapsed) {
                                    Clipboard.setData(
                                      ClipboardData(
                                        text: richController.text.substring(
                                          sel.start,
                                          sel.end,
                                        ),
                                      ),
                                    );
                                  }
                                }),
                                _toolBtn(Icons.content_paste, 'لصق', () async {
                                  final data = await Clipboard.getData(
                                    Clipboard.kTextPlain,
                                  );
                                  if (data?.text != null) {
                                    final sel = richController.selection;
                                    final pos = sel.isValid
                                        ? sel.start
                                        : richController.text.length;
                                    final end = sel.isValid && !sel.isCollapsed
                                        ? sel.end
                                        : pos;
                                    setDlg(() {
                                      richController.text = richController.text
                                          .replaceRange(pos, end, data!.text!);
                                    });
                                    setState(() {});
                                  }
                                }),
                                _toolBtn(Icons.delete_sweep, 'حذف', () {
                                  final sel = richController.selection;
                                  if (sel.isValid && !sel.isCollapsed) {
                                    setDlg(() {
                                      richController.text = richController.text
                                          .replaceRange(sel.start, sel.end, '');
                                    });
                                    setState(() {});
                                  }
                                }),
                                _toolBtn(Icons.select_all, 'تحديد الكل', () {
                                  setDlg(() {
                                    richController.selection = TextSelection(
                                      baseOffset: 0,
                                      extentOffset: richController.text.length,
                                    );
                                  });
                                  setState(() {});
                                  focusNode.requestFocus();
                                }),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Text editing area
                      TextField(
                        controller: richController,
                        focusNode: focusNode,
                        maxLines: null,
                        minLines: 6,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: fontFamily,
                          fontSize: fontSize,
                          fontWeight: isBold
                              ? FontWeight.bold
                              : FontWeight.normal,
                          height: 1.5,
                          color: isVerse ? Color(item.styling.color) : null,
                        ),
                        cursorColor: isVerse
                            ? const Color(0xFFD4AF37)
                            : const Color(0xFF2196F3),
                        enableInteractiveSelection: true,
                        selectionControls: MaterialTextSelectionControls(),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: isVerse
                                  ? const Color(0xFFD4AF37)
                                  : const Color(0xFF2196F3),
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          hintText: isVerse
                              ? 'اكتب نص الآية هنا...'
                              : 'اكتب نص التفسير هنا...',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showFormatExportDialog(String format) {
    String selectedSource = _selectedSourceId;
    String fromSurah = _activeVerses.first.surahName;
    String toSurah = _activeVerses.last.surahName;

    final surahNames = _activeVerses.map((v) => v.surahName).toSet().toList();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: AlertDialog(
                title: Text('تصدير إلى $format'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Source Selection
                      DropdownButtonFormField<String>(
                        value: selectedSource == '0' ? '0' : selectedSource,
                        decoration: const InputDecoration(
                          labelText: 'تفسير المصدر',
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: '0',
                            child: Text('التفسير المختار'),
                          ),
                          DropdownMenuItem(
                            value: '1',
                            child: Text('تفسير الجلالين'),
                          ),
                          DropdownMenuItem(
                            value: '2',
                            child: Text('التفسير الميسر'),
                          ),
                          DropdownMenuItem(
                            value: '3',
                            child: Text('الميسر في غريب القرآن'),
                          ),
                        ],
                        onChanged: (val) =>
                            setDialogState(() => selectedSource = val!),
                      ),
                      const SizedBox(height: 16),
                      // Range Selection
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: fromSurah,
                              decoration: const InputDecoration(
                                labelText: 'من سورة',
                              ),
                              items: surahNames
                                  .map(
                                    (s) => DropdownMenuItem(
                                      value: s,
                                      child: Text(s),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (val) =>
                                  setDialogState(() => fromSurah = val!),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: toSurah,
                              decoration: const InputDecoration(
                                labelText: 'إلى سورة',
                              ),
                              items: surahNames
                                  .map(
                                    (s) => DropdownMenuItem(
                                      value: s,
                                      child: Text(s),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (val) =>
                                  setDialogState(() => toSurah = val!),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('إلغاء'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      _executeExport(
                        selectedSource,
                        fromSurah,
                        toSurah,
                        format,
                      );
                    },
                    child: const Text('بدء التصدير'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _executeExport(
    String source,
    String fromS,
    String toS,
    String format,
  ) async {
    if (!mounted) return;

    final ValueNotifier<String> progressStage = ValueNotifier('جاري البدء...');
    final ValueNotifier<double> progressValue = ValueNotifier(0.0);
    final ValueNotifier<String> progressDetail = ValueNotifier('');

    // 1. إظهار مؤشر التقدم الحي فوراً
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.file_download, color: Colors.green),
                const SizedBox(width: 8),
                Text('تصدير $format', style: const TextStyle(fontSize: 18)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ValueListenableBuilder<double>(
                  valueListenable: progressValue,
                  builder: (_, value, __) {
                    return Column(
                      children: [
                        LinearProgressIndicator(
                          value: value > 0 ? value : null,
                          minHeight: 10,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.green.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          value > 0
                              ? '${(value * 100).toStringAsFixed(0)}%'
                              : '...',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 12),
                ValueListenableBuilder<String>(
                  valueListenable: progressStage,
                  builder: (_, stage, __) => Text(
                    stage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                const SizedBox(height: 4),
                ValueListenableBuilder<String>(
                  valueListenable: progressDetail,
                  builder: (_, detail, __) => Text(
                    detail,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    try {
      debugPrint('Export process started for format: $format');
      progressStage.value = 'جاري تحضير البيانات...';
      await Future.delayed(const Duration(milliseconds: 50));

      final startIndex = _activeVerses.indexWhere((v) => v.surahName == fromS);
      var endIndex = _activeVerses.lastIndexWhere((v) => v.surahName == toS);

      if (startIndex == -1 || endIndex == -1 || startIndex > endIndex) {
        throw Exception('مدى السور غير صحيح');
      }

      final exportVerses = _activeVerses.sublist(startIndex, endIndex + 1);
      final List<Tafsir> exportTafsirs = [];

      progressStage.value =
          'جاري تجهيز التفاسير (${exportVerses.length} آية)...';
      progressDetail.value = 'من سورة $fromS إلى سورة $toS';
      await Future.delayed(const Duration(milliseconds: 50));

      for (var v in exportVerses) {
        Tafsir t;
        if (source == '0') {
          t = currentProject!.tafsirs.firstWhere(
            (t) => t.id == v.selectedTafsirId,
            orElse: () => currentProject!.tafsirs.firstWhere(
              (t) => t.sourceId == '1' && t.id.endsWith(v.id.substring(2)),
              orElse: () => Tafsir(id: '', text: '...', sourceId: '1'),
            ),
          );
        } else {
          t = currentProject!.tafsirs.firstWhere(
            (t) => t.sourceId == source && t.id.endsWith(v.id.substring(2)),
            orElse: () => Tafsir(id: '', text: '...', sourceId: source),
          );
        }
        exportTafsirs.add(t);
      }

      void onProgress(int current, int total, String stage) {
        if (total > 0) {
          progressValue.value = current / total;
        }
        progressStage.value = stage;
        progressDetail.value = '$current من $total آية';
      }

      if (format == 'PDF') {
        await ExportService.exportToPdf(
          exportVerses,
          exportTafsirs,
          savePath: null,
          onProgress: onProgress,
        );
      } else if (format == 'Word') {
        await ExportService.exportToWord(
          exportVerses,
          exportTafsirs,
          savePath: null,
          onProgress: onProgress,
        );
      } else if (format == 'Code') {
        await ExportService.exportToCode(
          exportVerses,
          exportTafsirs,
          savePath: null,
          onProgress: onProgress,
        );
      } else if (format == 'JSON') {
        // Full project export
        await ExportService.exportToFullJson(
          currentProject!,
          savePath: null,
          onProgress: onProgress,
        );
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('حدث خطأ أثناء التصدير: $e')));
      }
    }
  }

  void _showAddToMukhtarDialog(Verse verse, Tafsir sourceTafsir) {
    // Determine initial source to show. If we are starting while viewing Mukhtar (0),
    // default to showing Ghareeb (3) content so the user can add from it.
    String initialSourceId = sourceTafsir.sourceId;
    if (initialSourceId == '0') {
      initialSourceId = '3';
    }

    final initialTafsirVal = (initialSourceId == sourceTafsir.sourceId)
        ? sourceTafsir
        : _getTafsirForVerse(verse, initialSourceId);

    final richController = RichTextController(
      chunks: initialTafsirVal.chunks
          .map(
            (c) => StyledChunk(
              text: c.text,
              color: c.color,
              backgroundColor: c.backgroundColor,
              isBold: c.isBold,
              isItalic: c.isItalic,
              isUnderline: c.isUnderline,
              underlineColor: c.underlineColor,
            ),
          )
          .toList(),
    );

    final focusNode = FocusNode();
    String currentSourceLabel;
    if (sourceTafsir.sourceId == '1') {
      currentSourceLabel = 'تفسير الجلالين';
    } else if (sourceTafsir.sourceId == '2') {
      currentSourceLabel = 'التفسير الميسر';
    } else if (sourceTafsir.sourceId == '3') {
      currentSourceLabel = 'الميسر في غريب القرآن';
    } else if (sourceTafsir.sourceId == '0') {
      // If adding from Mukhtar itself, default to its last source marker if possible, else Ghareeb
      currentSourceLabel = 'الميسر في غريب القرآن';
    } else {
      currentSourceLabel = 'أخرى';
    }

    final customSourceController = TextEditingController();

    final textColors = <Color>[
      Colors.black,
      const Color(0xFF1B1B1B),
      const Color(0xFF5D4037),
      Colors.red,
      Colors.red.shade900,
      Colors.blue,
      Colors.blue.shade900,
      Colors.green,
      Colors.green.shade900,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      const Color(0xFFD4AF37),
    ];

    final hlColors = <Color>[
      Colors.yellow.shade200,
      Colors.yellow.shade400,
      Colors.lightGreen.shade200,
      Colors.lightGreen.shade400,
      Colors.cyan.shade100,
      Colors.cyan.shade300,
      Colors.pink.shade100,
      Colors.pink.shade300,
      Colors.orange.shade100,
      Colors.purple.shade100,
    ];

    bool isProcessing = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlg) {
          // Local function to perform the add action
          void performAdd(bool selectedOnly) {
            if (isProcessing) return;
            isProcessing = true;

            // Close dialog instantly for maximum perceived speed
            Navigator.pop(ctx);

            // Move heavy processing to a delayed future to avoid blocking the pop animation
            Future.delayed(const Duration(milliseconds: 50), () async {
              List<StyledChunk> chosenChunks;
              if (selectedOnly) {
                final sel = richController.selection;
                if (sel.isValid && !sel.isCollapsed) {
                  chosenChunks = richController.getSelectedChunks();
                } else {
                  return;
                }
              } else {
                // Copy all chunks as new StyledChunk objects to avoid reference issues
                chosenChunks = richController.chunks
                    .map(
                      (c) => StyledChunk(
                        text: c.text,
                        color: c.color,
                        backgroundColor: c.backgroundColor,
                        isBold: c.isBold,
                        isItalic: c.isItalic,
                        isUnderline: c.isUnderline,
                        underlineColor: c.underlineColor,
                      ),
                    )
                    .toList();
              }

              if (chosenChunks.isEmpty) return;

              final finalLabel = currentSourceLabel == 'أخرى'
                  ? customSourceController.text.trim()
                  : currentSourceLabel;

              setState(() {
                final idSuffix = verse.id.substring(2);
                final chosenTafsirId = 't_0_$idSuffix';

                Tafsir? chosenTafsir;
                try {
                  chosenTafsir = currentProject!.tafsirs.firstWhere(
                    (t) => t.id == chosenTafsirId,
                  );
                } catch (_) {
                  chosenTafsir = Tafsir(
                    id: chosenTafsirId,
                    text: '',
                    sourceId: '0',
                    styling: TextStyling(fontSize: 28),
                  );
                  currentProject!.tafsirs.add(chosenTafsir);
                }

                final prefixText = chosenTafsir.text.isEmpty ? "" : " . ";

                // Add selection with dot prefix if needed
                if (chosenChunks.isNotEmpty) {
                  chosenChunks[0].text =
                      prefixText + chosenChunks[0].text.trim();
                }

                // Add all chosen chunks with their styling
                chosenTafsir.chunks.addAll(chosenChunks);

                // Add source label at the end with red-box marker format [Label]
                chosenTafsir.chunks.add(
                  StyledChunk(
                    text: " [$finalLabel]",
                    color: Colors.red.shade900.value,
                    isBold: true,
                  ),
                );

                chosenTafsir.text = chosenTafsir.chunks
                    .map((c) => c.text)
                    .join();
                chosenTafsir.isEdited = true; // Mark as edited for persistence
                verse.selectedTafsirId = chosenTafsirId;
                verse.isEdited =
                    true; // Mark verse as edited to save its selectedTafsirId

                // Auto-switch to Al-Mukhtar tab (Source ID '0')
                _selectedSourceId = '0';
              });

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    selectedOnly
                        ? 'تمت إضافة المحدّد للمختار'
                        : 'تمت إضافة النص كاملاً للمختار',
                    textAlign: TextAlign.right,
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );

              // Background save
              await ProjectManager.saveProject(currentProject!);
            });
          }

          return Directionality(
            textDirection: TextDirection.rtl,
            child: Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              backgroundColor: const Color(0xFFFDFCF0),
              child: Container(
                width: 700,
                padding: const EdgeInsets.all(24),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('إلغاء'),
                          ),
                          const Expanded(
                            child: Center(
                              child: Text(
                                'إضافة للمختار',
                                style: TextStyle(
                                  fontFamily: 'AmiriBold',
                                  fontSize: 18,
                                  color: Color(0xFF5D4037),
                                ),
                              ),
                            ),
                          ),
                          // Button for adding only selection
                          // Unified Save Button
                          ElevatedButton.icon(
                            icon: const Icon(
                              Icons.save,
                              color: Colors.white,
                              size: 18,
                            ),
                            label: const Text(
                              'حفظ',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.brown.shade700,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: isProcessing
                                ? null
                                : () {
                                    final sel = richController.selection;
                                    // If text is selected, add only the selection. Otherwise, add all.
                                    if (sel.isValid && !sel.isCollapsed) {
                                      performAdd(true);
                                    } else {
                                      performAdd(false);
                                    }
                                  },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerRight,
                        child: SizedBox(
                          width: 280,
                          child: DropdownButtonFormField<String>(
                            value: currentSourceLabel,
                            decoration: const InputDecoration(
                              labelText: 'اختر المصدر',
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'تفسير المختصر',
                                child: Text('تفسير المختصر'),
                              ),
                              DropdownMenuItem(
                                value: 'تفسير الجلالين',
                                child: Text('تفسير الجلالين'),
                              ),
                              DropdownMenuItem(
                                value: 'تفسير الإيجي',
                                child: Text('تفسير الإيجي'),
                              ),
                              DropdownMenuItem(
                                value: 'تفسير الوجيز للواحدي',
                                child: Text('تفسير الوجيز للواحدي'),
                              ),
                              DropdownMenuItem(
                                value: 'الميسر في غريب القرآن',
                                child: Text('الميسر في غريب القرآن'),
                              ),
                              DropdownMenuItem(
                                value: 'التفسير الميسر',
                                child: Text('التفسير الميسر'),
                              ),
                              DropdownMenuItem(
                                value: 'السراج في غريب القرآن',
                                child: Text('السراج في غريب القرآن'),
                              ),
                              DropdownMenuItem(
                                value: 'أخرى',
                                child: Text('مصدر آخر...'),
                              ),
                            ],
                            onChanged: (val) {
                              setDlg(() {
                                currentSourceLabel = val!;

                                // Auto-fetch logic only for Jalalayn
                                String? targetSourceId;
                                if (currentSourceLabel == 'تفسير الجلالين') {
                                  targetSourceId = '1';
                                }
                                // Muyassar and Ghareeb names are kept for reference, but no auto-fetch

                                if (targetSourceId != null) {
                                  final fetched = _getTafsirForVerse(
                                    verse,
                                    targetSourceId,
                                  );
                                  richController.updateAll(
                                    fetched.chunks
                                        .map(
                                          (c) => StyledChunk(
                                            text: c.text,
                                            color: c.color,
                                            backgroundColor: c.backgroundColor,
                                            isBold: c.isBold,
                                            isItalic: c.isItalic,
                                            isUnderline: c.isUnderline,
                                            underlineColor: c.underlineColor,
                                          ),
                                        )
                                        .toList(),
                                  );
                                }
                              });
                            },
                          ),
                        ),
                      ),
                      if (currentSourceLabel == 'أخرى') ...[
                        const SizedBox(height: 12),
                        TextField(
                          controller: customSourceController,
                          decoration: const InputDecoration(
                            labelText: 'اسم المصدر',
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.touch_app, color: Colors.blue, size: 20),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'قم بتظليل الجزء الذي تريد إضافته فقط، أو اضغط إضافة مباشرة لنقل النص كاملاً.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.blueAccent,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          children: [
                            Wrap(
                              spacing: 8,
                              children: [
                                _toolBtn(Icons.format_bold, 'تغميق', () {
                                  richController.applyStyle(toggleBold: true);
                                  focusNode.requestFocus();
                                  setDlg(() {});
                                }),
                                _toolBtn(Icons.content_cut, 'قص', () {
                                  final sel = richController.selection;
                                  if (sel.isValid && !sel.isCollapsed) {
                                    Clipboard.setData(
                                      ClipboardData(
                                        text: richController.text.substring(
                                          sel.start,
                                          sel.end,
                                        ),
                                      ),
                                    );
                                    setDlg(() {
                                      richController.text = richController.text
                                          .replaceRange(sel.start, sel.end, '');
                                    });
                                  }
                                }),
                                _toolBtn(Icons.content_copy, 'نسخ', () {
                                  final sel = richController.selection;
                                  if (sel.isValid && !sel.isCollapsed) {
                                    Clipboard.setData(
                                      ClipboardData(
                                        text: richController.text.substring(
                                          sel.start,
                                          sel.end,
                                        ),
                                      ),
                                    );
                                  }
                                }),
                                _toolBtn(Icons.content_paste, 'لصق', () async {
                                  final data = await Clipboard.getData(
                                    Clipboard.kTextPlain,
                                  );
                                  if (data?.text != null) {
                                    final sel = richController.selection;
                                    final pos = sel.isValid
                                        ? sel.start
                                        : richController.text.length;
                                    final end = sel.isValid && !sel.isCollapsed
                                        ? sel.end
                                        : pos;
                                    setDlg(() {
                                      richController.text = richController.text
                                          .replaceRange(pos, end, data!.text!);
                                    });
                                  }
                                }),
                                _toolBtn(Icons.delete_sweep, 'حذف', () {
                                  final sel = richController.selection;
                                  if (sel.isValid && !sel.isCollapsed) {
                                    setDlg(() {
                                      richController.text = richController.text
                                          .replaceRange(sel.start, sel.end, '');
                                    });
                                  }
                                }),
                                _toolBtn(Icons.select_all, 'تحديد الكل', () {
                                  setDlg(() {
                                    richController.selection = TextSelection(
                                      baseOffset: 0,
                                      extentOffset: richController.text.length,
                                    );
                                  });
                                  focusNode.requestFocus();
                                }),
                              ],
                            ),
                            const Divider(),
                            Wrap(
                              spacing: 4,
                              children: textColors
                                  .map(
                                    (c) => Tooltip(
                                      message: 'تلوين',
                                      child: InkWell(
                                        onTap: () {
                                          richController.applyStyle(
                                            color: c.toARGB32(),
                                          );
                                          focusNode.requestFocus();
                                          setDlg(() {});
                                        },
                                        child: Container(
                                          width: 24,
                                          height: 24,
                                          decoration: BoxDecoration(
                                            color: c,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 4,
                              children: hlColors
                                  .map(
                                    (c) => Tooltip(
                                      message: 'تظليل',
                                      child: InkWell(
                                        onTap: () {
                                          richController.applyStyle(
                                            backgroundColor: c.toARGB32(),
                                          );
                                          focusNode.requestFocus();
                                          setDlg(() {});
                                        },
                                        child: Container(
                                          width: 24,
                                          height: 24,
                                          decoration: BoxDecoration(
                                            color: c,
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: richController,
                        focusNode: focusNode,
                        maxLines: 8,
                        textAlign: TextAlign.right,
                        textDirection: TextDirection.rtl,
                        style: GoogleFonts.amiri(fontSize: 18),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Colors.brown.shade200,
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _toolBtn(
    IconData icon,
    String label,
    VoidCallback onTap, {
    bool isActive = false,
    String? tooltip,
  }) {
    return Focus(
      canRequestFocus: false,
      child: Tooltip(
        message: tooltip ?? label,
        child: InkWell(
          onTap: onTap,
          canRequestFocus: false,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFFE3F2FD) : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: isActive ? Border.all(color: Colors.blue.shade300) : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: isActive ? Colors.blue : Colors.grey.shade700,
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    color: isActive ? Colors.blue : Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _executeSearch() {
    final surahQuery = _searchSurahController.text;
    final ayahQuery = _searchAyahController.text;
    final juzQuery = _searchJuzController.text;

    // 1. Jump by Juz if provided
    if (juzQuery.isNotEmpty) {
      final targetJuz = int.tryParse(juzQuery);
      if (targetJuz != null) {
        for (int i = 0; i < _activeVerses.length; i++) {
          if (_activeVerses[i].juz == targetJuz) {
            _jumpToPage(i);
            return;
          }
        }
      }
    }

    // 2. Jump by Surah and/or Ayah
    if (surahQuery.isNotEmpty) {
      for (int i = 0; i < _activeVerses.length; i++) {
        final v = _activeVerses[i];
        bool match = v.surahName == surahQuery;
        if (match && ayahQuery.isNotEmpty) {
          if (v.verseNumber != ayahQuery) match = false;
        }
        if (match) {
          _jumpToPage(i);
          return;
        }
      }
    } else if (ayahQuery.isNotEmpty) {
      // Search in current surah
      final currentSurah = _activeVerses[currentPage].surahName;
      for (int i = 0; i < _activeVerses.length; i++) {
        final v = _activeVerses[i];
        if (v.surahName == currentSurah && v.verseNumber == ayahQuery) {
          _jumpToPage(i);
          return;
        }
      }
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('لم يتم العثور على نتائج')));
  }

  void _jumpToPage(int index) {
    setState(() => currentPage = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  Widget _buildSearchBar() {
    if (!_showSearchBar) return const SizedBox.shrink();

    final List<String> surahNames = _activeVerses
        .map((v) => v.surahName)
        .toSet()
        .toList();
    final currentSurahName = _searchSurahController.text;

    int maxAyahs = 286;
    if (currentSurahName.isNotEmpty) {
      maxAyahs = _activeVerses
          .where((v) => v.surahName == currentSurahName)
          .length;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFDFCF0).withOpacity(0.98),
        border: const Border(
          bottom: BorderSide(color: Color(0xFFD4AF37), width: 1.5),
        ),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Row(
          children: [
            // Juz Selector
            Expanded(
              flex: 1,
              child: DropdownButtonFormField<String>(
                value: _searchJuzController.text.isNotEmpty
                    ? _searchJuzController.text
                    : null,
                hint: const Text('الجزء', style: TextStyle(fontSize: 14)),
                isDense: true,
                decoration: _navInputDecoration(),
                items: List.generate(30, (i) => '${i + 1}')
                    .map((n) => DropdownMenuItem(value: n, child: Text('ج $n')))
                    .toList(),
                onChanged: (val) {
                  setState(() {
                    _searchJuzController.text = val ?? '';
                    _searchSurahController.text = '';
                    _searchAyahController.text = '';
                  });
                  _executeSearch();
                },
              ),
            ),
            const SizedBox(width: 8),
            // Surah Selector
            Expanded(
              flex: 2,
              child: DropdownButtonFormField<String>(
                value: _searchSurahController.text.isNotEmpty
                    ? _searchSurahController.text
                    : null,
                hint: const Text('السورة', style: TextStyle(fontSize: 14)),
                isDense: true,
                decoration: _navInputDecoration(),
                items: surahNames
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (val) {
                  setState(() {
                    _searchSurahController.text = val ?? '';
                    _searchAyahController.text = '';
                    _searchJuzController.text = '';
                  });
                  _executeSearch();
                },
              ),
            ),
            const SizedBox(width: 8),
            // Ayah Selector
            Expanded(
              flex: 1,
              child: DropdownButtonFormField<String>(
                value: _searchAyahController.text.isNotEmpty
                    ? _searchAyahController.text
                    : null,
                hint: const Text('الآية', style: TextStyle(fontSize: 14)),
                isDense: true,
                decoration: _navInputDecoration(),
                items: List.generate(maxAyahs, (i) => '${i + 1}')
                    .map((n) => DropdownMenuItem(value: n, child: Text(n)))
                    .toList(),
                onChanged: (val) {
                  setState(() {
                    _searchAyahController.text = val ?? '';
                    _searchJuzController.text = '';
                  });
                  _executeSearch();
                },
              ),
            ),
            const SizedBox(width: 12),
            IconButton(
              onPressed: () {
                setState(() {
                  _searchJuzController.clear();
                  _searchSurahController.clear();
                  _searchAyahController.clear();
                });
              },
              icon: const Icon(Icons.clear_all, color: Colors.grey),
              tooltip: 'مسح الكل',
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _navInputDecoration() {
    return InputDecoration(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFD4AF37)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFD4AF37), width: 0.8),
      ),
      filled: true,
      fillColor: Colors.white,
    );
  }

  void _showQuickSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFFDFCF0),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'إعدادات الخط',
                    style: TextStyle(
                      fontFamily: 'AmiriBold',
                      fontSize: 22,
                      color: Color(0xFF5D4037),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('حجم خط الآيات'),
                  if (_activeVerses.isNotEmpty)
                    Slider(
                      value: _activeVerses[0].styling.fontSize,
                      min: 20,
                      max: 60,
                      activeColor: const Color(0xFFD4AF37),
                      onChanged: (val) {
                        setState(() {
                          for (var v in _activeVerses) {
                            v.styling.fontSize = val;
                          }
                        });
                        setModalState(() {});
                      },
                    ),
                  const SizedBox(height: 10),
                  const Text('حجم خط التفسير'),
                  if (currentProject != null &&
                      currentProject!.tafsirs.isNotEmpty)
                    Slider(
                      value: currentProject!.tafsirs[0].styling.fontSize,
                      min: 16,
                      max: 45,
                      activeColor: Colors.brown,
                      onChanged: (val) {
                        setState(() {
                          for (var t in currentProject!.tafsirs) {
                            t.styling.fontSize = val;
                          }
                        });
                        setModalState(() {});
                      },
                    ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD4AF37),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('إغلاق'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildControlBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        border: const Border(
          bottom: BorderSide(color: Color(0xFFD4AF37), width: 1.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Global Controls (Left Side)
          Row(
            children: [
              _toolBtn(
                _showSearchBar ? Icons.search_off : Icons.search,
                'بحث',
                () => setState(() => _showSearchBar = !_showSearchBar),
                isActive: _showSearchBar,
                tooltip: 'فتح/إغلاق شريط البحث',
              ),
              _toolBtn(
                Icons.bookmark_add,
                'حفظ ختم',
                _saveBookmark,
                tooltip: 'حفظ موضع القراءة الحالي',
              ),
              _toolBtn(
                Icons.bookmark,
                'الختم',
                _bookmarkedPage != null ? _jumpToBookmark : () {},
                isActive: _bookmarkedPage != null,
                tooltip: _bookmarkedPage != null
                    ? 'الانتقال إلى الختم المحفوظ'
                    : 'لا يوجد ختم محفوظ',
              ),
              _toolBtn(
                Icons.settings,
                'حجم الخط',
                _showQuickSettings,
                tooltip: 'إعدادات حجم خط الآيات والتفسير',
              ),
              _toolBtn(
                Icons.camera_alt,
                'تصوير',
                _takeScreenshot,
                tooltip: 'تصوير الصفحة ومشاركتها',
              ),
              _toolBtn(
                Icons.picture_as_pdf,
                'PDF',
                () => _showFormatExportDialog('PDF'),
                tooltip: 'تصدير كمطالب PDF',
              ),
              _toolBtn(
                Icons.description,
                'Word',
                () => _showFormatExportDialog('Word'),
                tooltip: 'تصدير كملف Word',
              ),
              _toolBtn(
                Icons.code,
                'JSON',
                () => _showFormatExportDialog('JSON'),
                tooltip: 'تصدير المشروع كاملاً كملف JSON',
              ),
            ],
          ),
          // Title (Center)
          Expanded(
            child: Center(
              child: Text(
                _activeVerses.isNotEmpty
                    ? '﴿ ${_activeVerses[currentPage].surahName} - الجزء (${_activeVerses[currentPage].juz ?? "?"}) ﴾'
                    : 'التفسير المختار',
                textAlign: TextAlign.center,
                style: GoogleFonts.notoKufiArabic(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF5D4037),
                  shadows: [
                    const Shadow(
                      color: Colors.black12,
                      offset: Offset(1, 1),
                      blurRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Edit Controls (Right Side)
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.text_increase, color: Colors.brown),
                tooltip: 'تكبير الخط',
                onPressed: () {
                  setState(() {
                    final verse = _activeVerses[currentPage];
                    verse.styling.fontSize += 2;
                    final tafsir = _getTafsirForVerse(verse);
                    tafsir.styling.fontSize += 2;
                  });
                },
              ),
              IconButton(
                icon: const Icon(Icons.text_decrease, color: Colors.brown),
                tooltip: 'تصغير الخط',
                onPressed: () {
                  setState(() {
                    final verse = currentProject!.verses[currentPage];
                    verse.styling.fontSize -= 2;
                    final tafsir = currentProject!.tafsirs[currentPage];
                    tafsir.styling.fontSize -= 2;
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading || currentProject == null) {
      debugPrint('App is loading... Project: ${currentProject != null}');
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFDFCF0), Color(0xFFF2E8B6), Color(0xFFE8D4A2)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildControlBar(),
              _buildSearchBar(),
              Expanded(
                child: Screenshot(
                  controller: _screenshotController,
                  child: Stack(
                    children: [
                      Directionality(
                        textDirection: TextDirection.rtl,
                        child: PageView.builder(
                          controller: _pageController,
                          itemCount: (_activeVerses.length / itemsPerPage)
                              .ceil(),
                          onPageChanged: (page) async {
                            setState(() {
                              currentPage = page;
                            });
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.setInt('last_viewed_page', page);
                          },
                          itemBuilder: (context, index) {
                            final verse = _activeVerses[index];
                            final tafsir = _getTafsirForVerse(verse);

                            return Directionality(
                              textDirection: TextDirection.rtl,
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.all(20),
                                child: Center(
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      maxWidth: 850,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        // === BASMALAH for first verse of each surah (except Fatiha) ===
                                        if (verse.verseNumber == '1' &&
                                            verse.surahName != 'الفاتحة')
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              bottom: 16,
                                            ),
                                            child: Text(
                                              'بِسۡمِ ٱللَّهِ ٱلرَّحۡمَـٰنِ ٱلرَّحِیمِ',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontFamily:
                                                    verse.styling.fontFamily ??
                                                    'AlQalamQuranMajeed2',
                                                fontSize:
                                                    verse.styling.fontSize + 2,
                                                color: const Color(0xFF000000),
                                                fontWeight: FontWeight.bold,
                                                height: 1.8,
                                              ),
                                            ),
                                          ),
                                        // === VERSE SECTION with ornate Islamic frame ===
                                        OrnateVerseFrame(
                                          child: Padding(
                                            padding: const EdgeInsets.all(20),
                                            child: Column(
                                              children: [
                                                // Verse text with inline number
                                                Text.rich(
                                                  TextSpan(
                                                    children: [
                                                      ...verse.chunks.map(
                                                        (c) => TextSpan(
                                                          text: c.text,
                                                          style: TextStyle(
                                                            fontFamily:
                                                                verse
                                                                    .styling
                                                                    .fontFamily ??
                                                                'AlQalamQuranMajeed2',
                                                            fontSize: verse
                                                                .styling
                                                                .fontSize,
                                                            color: Color(
                                                              c.color,
                                                            ),
                                                            backgroundColor:
                                                                c.backgroundColor !=
                                                                    null
                                                                ? Color(
                                                                    c.backgroundColor!,
                                                                  )
                                                                : null,
                                                            fontWeight:
                                                                (c.isBold ||
                                                                    verse
                                                                        .styling
                                                                        .isBold)
                                                                ? FontWeight
                                                                      .bold
                                                                : FontWeight
                                                                      .normal,
                                                            height: 1.8,
                                                            decoration:
                                                                c.isUnderline
                                                                ? TextDecoration
                                                                      .underline
                                                                : TextDecoration
                                                                      .none,
                                                            decorationColor:
                                                                c.underlineColor !=
                                                                    null
                                                                ? Color(
                                                                    c.underlineColor!,
                                                                  )
                                                                : null,
                                                            decorationThickness:
                                                                2.0,
                                                          ),
                                                        ),
                                                      ),
                                                      WidgetSpan(
                                                        alignment:
                                                            PlaceholderAlignment
                                                                .middle,
                                                        child: Padding(
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                horizontal: 4,
                                                              ),
                                                          child:
                                                              VerseNumberFrame(
                                                                number: verse
                                                                    .verseNumber,
                                                                fontSize: verse
                                                                    .styling
                                                                    .fontSize,
                                                              ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                                Align(
                                                  alignment:
                                                      Alignment.centerLeft,
                                                  child: InkWell(
                                                    onTap: () =>
                                                        _showEditDialog(
                                                          verse,
                                                          tafsir,
                                                        ),
                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                            top: 8,
                                                          ),
                                                      child: Column(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          Icon(
                                                            Icons.edit_note,
                                                            size: 26,
                                                            color: Colors
                                                                .orange
                                                                .shade800,
                                                          ),
                                                          const Text(
                                                            'تعديل الآية',
                                                            style: TextStyle(
                                                              fontSize: 10,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              color: Color(
                                                                0xFF5D4037,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 24),
                                        // === TAFSIR SECTION (outside the ornate frame) ===
                                        // Tafsir header with source toggle
                                        Row(
                                          children: [
                                            const Text(
                                              'التفسير:',
                                              style: TextStyle(
                                                fontFamily: 'AmiriBold',
                                                fontSize: 20,
                                                color: Color(0xFF5D4037),
                                                decoration:
                                                    TextDecoration.underline,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            // Append Icon (Compiles interpretations)
                                            _toolBtn(
                                              Icons.add_circle_outline,
                                              'إضافة للمختار',
                                              () => _showAddToMukhtarDialog(
                                                verse,
                                                tafsir,
                                              ),
                                              tooltip:
                                                  'تحديد وتنسيق أجزاء لإضافتها للمختار',
                                            ),
                                            const SizedBox(width: 8),
                                            _buildSourceToggle('الجلالين', '1'),
                                            const SizedBox(width: 4),
                                            _buildSourceToggle('المختار', '0'),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        // Tafsir text with professional source labels
                                        _buildTafsirRichText(tafsir),
                                        Align(
                                          alignment: Alignment.centerLeft,
                                          child: InkWell(
                                            onTap: () => _showTafsirEditDialog(
                                              verse,
                                              tafsir,
                                            ),
                                            child: Padding(
                                              padding: const EdgeInsets.only(
                                                top: 8,
                                              ),
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.edit_note,
                                                    size: 26,
                                                    color: Colors.blue.shade800,
                                                  ),
                                                  Text(
                                                    'تعديل التفسير',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Color(0xFF5D4037),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      Positioned(
                        left: 20,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.5),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.arrow_forward_ios,
                                size: 35,
                                color: Color(0xFFD4AF37),
                              ),
                              tooltip: 'التالية',
                              onPressed:
                                  currentPage <
                                      currentProject!.verses.length - 1
                                  ? () {
                                      _pageController.animateToPage(
                                        currentPage + 1,
                                        duration: const Duration(
                                          milliseconds: 500,
                                        ),
                                        curve: Curves.easeInOut,
                                      );
                                    }
                                  : null,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 20,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.5),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.arrow_back_ios_new,
                                size: 35,
                                color: Color(0xFFD4AF37),
                              ),
                              tooltip: 'السابقة',
                              onPressed: currentPage > 0
                                  ? () {
                                      _pageController.animateToPage(
                                        currentPage - 1,
                                        duration: const Duration(
                                          milliseconds: 500,
                                        ),
                                        curve: Curves.easeInOut,
                                      );
                                    }
                                  : null,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTafsirRichText(Tafsir tafsir) {
    List<InlineSpan> spans = [];
    final markerRegex = RegExp(r'\[(.*?)\]');

    for (var chunk in tafsir.chunks) {
      // Clean newlines and extra spaces from the chunk text for ultra-compressed layout
      final text = chunk.text
          .replaceAll('\n', ' ')
          .replaceAll(RegExp(r' +'), ' ');
      int lastMatchEnd = 0;

      for (var match in markerRegex.allMatches(text)) {
        // Text before marker
        if (match.start > lastMatchEnd) {
          spans.add(
            TextSpan(
              text: text.substring(lastMatchEnd, match.start),
              style: _getChunkStyle(tafsir, chunk),
            ),
          );
        }

        // The marker (Red Box)
        final sourceName = match.group(1)!;
        spans.add(_buildSourceLabel(sourceName));

        lastMatchEnd = match.end;
      }

      // Remaining text
      if (lastMatchEnd < text.length) {
        spans.add(
          TextSpan(
            text: text.substring(lastMatchEnd),
            style: _getChunkStyle(tafsir, chunk),
          ),
        );
      }
    }

    // Append default source label if in Al-Mukhtar view and it's a specific source
    if (_selectedSourceId == '0' && tafsir.sourceId != '0') {
      final name = tafsir.sourceId == '1'
          ? 'تفسير الجلالين'
          : tafsir.sourceId == '2'
          ? 'التفسير الميسر'
          : tafsir.sourceId == '3'
          ? 'الميسر في غريب القرآن'
          : tafsir.sourceId == '4'
          ? 'جامع البيان'
          : tafsir.sourceId == '5'
          ? 'تفسير الوجيز للواحدي'
          : tafsir.sourceId;
      spans.add(const TextSpan(text: ' '));
      spans.add(_buildSourceLabel(name));
    }

    return Text.rich(TextSpan(children: spans), textAlign: TextAlign.justify);
  }

  TextStyle _getChunkStyle(Tafsir tafsir, StyledChunk c) {
    return TextStyle(
      fontFamily: tafsir.styling.fontFamily ?? 'AmiriCustom',
      fontSize: tafsir.styling.fontSize,
      color: Color(c.color),
      backgroundColor: c.backgroundColor != null
          ? Color(c.backgroundColor!)
          : null,
      fontWeight: (c.isBold || tafsir.styling.isBold)
          ? FontWeight.bold
          : FontWeight.normal,
      decoration: c.isUnderline
          ? TextDecoration.underline
          : TextDecoration.none,
      decorationColor: c.underlineColor != null
          ? Color(c.underlineColor!)
          : null,
      decorationThickness: 2.0,
      height: 1.6,
    );
  }

  WidgetSpan _buildSourceLabel(String name) {
    return WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: SourceLabelBox(sourceName: name),
    );
  }
}

class OrnateVerseFrame extends StatelessWidget {
  final Widget child;

  const OrnateVerseFrame({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFDFCF0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF5D4037), width: 2.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 20,
            spreadRadius: 3,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: const Color(0xFFD4AF37).withOpacity(0.15),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      padding: const EdgeInsets.all(4),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFD4AF37), width: 5),
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.all(3),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF8B6914), width: 1.5),
            borderRadius: BorderRadius.circular(4),
          ),
          padding: const EdgeInsets.all(2),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFD4AF37), width: 1),
              borderRadius: BorderRadius.circular(2),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFFFFDF5),
                  Color(0xFFFDFCF0),
                  Color(0xFFFFFDF5),
                ],
              ),
            ),
            child: Stack(
              children: [
                // Corner ornaments
                const Positioned(
                  top: 6,
                  left: 6,
                  child: Text(
                    '❖',
                    style: TextStyle(color: Color(0xFFD4AF37), fontSize: 18),
                  ),
                ),
                const Positioned(
                  top: 6,
                  right: 6,
                  child: Text(
                    '❖',
                    style: TextStyle(color: Color(0xFFD4AF37), fontSize: 18),
                  ),
                ),
                const Positioned(
                  bottom: 6,
                  left: 6,
                  child: Text(
                    '❖',
                    style: TextStyle(color: Color(0xFFD4AF37), fontSize: 18),
                  ),
                ),
                const Positioned(
                  bottom: 6,
                  right: 6,
                  child: Text(
                    '❖',
                    style: TextStyle(color: Color(0xFFD4AF37), fontSize: 18),
                  ),
                ),
                // Top center ornament
                const Positioned(
                  top: 4,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Text(
                      '﴾ ۞ ﴿',
                      style: TextStyle(color: Color(0xFFD4AF37), fontSize: 14),
                    ),
                  ),
                ),
                // Bottom center ornament
                const Positioned(
                  bottom: 4,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Text(
                      '﴾ ۞ ﴿',
                      style: TextStyle(color: Color(0xFFD4AF37), fontSize: 14),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 24,
                    horizontal: 16,
                  ),
                  child: child,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class VerseNumberFrame extends StatelessWidget {
  final String number;
  final double fontSize;

  const VerseNumberFrame({
    super.key,
    required this.number,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    // Dynamically calculate size based on font size
    final double baseSize = fontSize * 1.0;
    final double frameSize = baseSize * 0.8;

    return SizedBox(
      width: baseSize,
      height: baseSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Octagonal frame (3D look with two rotated squares)
          Transform.rotate(
            angle: 0.785398, // 45 degrees
            child: Container(
              width: frameSize,
              height: frameSize,
              decoration: BoxDecoration(
                color: const Color(0xFF004D40), // Emerald Green
                border: Border.all(
                  color: const Color(0xFFD4AF37), // Gold
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 2,
                    offset: const Offset(1, 1),
                  ),
                ],
              ),
            ),
          ),
          Container(
            width: frameSize,
            height: frameSize,
            decoration: BoxDecoration(
              color: const Color(0xFF004D40), // Emerald Green
              border: Border.all(
                color: const Color(0xFFD4AF37), // Gold
                width: 1.5,
              ),
            ),
          ),
          // Inner decoration (Gold circle)
          Container(
            width: frameSize * 0.75,
            height: frameSize * 0.75,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFD4AF37).withOpacity(0.6),
                width: 1.0,
              ),
            ),
          ),
          // Verse Number
          Padding(
            padding: const EdgeInsets.only(top: 2), // Visual adjustment
            child: Text(
              number,
              style: TextStyle(
                fontFamily: 'AmiriBold',
                fontSize: baseSize * 0.55,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(0.5),
                    offset: const Offset(0.5, 0.5),
                    blurRadius: 1,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SourceLabelBox extends StatelessWidget {
  final String sourceName;

  const SourceLabelBox({super.key, required this.sourceName});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        border: Border.all(color: Colors.red.shade200, width: 0.5),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        sourceName,
        style: TextStyle(
          fontSize: 8.5,
          fontFamily: 'AmiriBold',
          color: Colors.red.shade900,
          height: 1.0,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
