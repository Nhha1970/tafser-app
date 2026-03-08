class TextStyling {
  double fontSize;
  String? fontFamily;
  int color;
  int? backgroundColor;
  bool isBold;
  bool isItalic;
  bool isUnderline;
  int? underlineColor;
  String alignment; // 'right', 'center', 'left'

  TextStyling({
    this.fontSize = 18.0,
    this.fontFamily,
    this.color = 0xFF000000,
    this.backgroundColor,
    this.isBold = false,
    this.isItalic = false,
    this.isUnderline = false,
    this.underlineColor,
    this.alignment = 'center',
  });

  Map<String, dynamic> toMap() {
    return {
      'fontSize': fontSize,
      'fontFamily': fontFamily,
      'color': color,
      'backgroundColor': backgroundColor,
      'isBold': isBold,
      'isItalic': isItalic,
      'isUnderline': isUnderline,
      'underlineColor': underlineColor,
      'alignment': alignment,
    };
  }

  factory TextStyling.fromMap(Map<String, dynamic> map) {
    return TextStyling(
      fontSize: (map['fontSize'] ?? 18.0).toDouble(),
      fontFamily: map['fontFamily'],
      color: map['color'] ?? 0xFF000000,
      backgroundColor: map['backgroundColor'],
      isBold: map['isBold'] ?? false,
      isItalic: map['isItalic'] ?? false,
      isUnderline: map['isUnderline'] ?? false,
      underlineColor: map['underlineColor'],
      alignment: map['alignment'] ?? 'right',
    );
  }

  TextStyling copyWith({
    double? fontSize,
    String? fontFamily,
    int? color,
    int? backgroundColor,
    bool? isBold,
    bool? isItalic,
    bool? isUnderline,
    int? underlineColor,
    String? alignment,
  }) {
    return TextStyling(
      fontSize: fontSize ?? this.fontSize,
      fontFamily: fontFamily ?? this.fontFamily,
      color: color ?? this.color,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      isBold: isBold ?? this.isBold,
      isItalic: isItalic ?? this.isItalic,
      isUnderline: isUnderline ?? this.isUnderline,
      underlineColor: underlineColor ?? this.underlineColor,
      alignment: alignment ?? this.alignment,
    );
  }
}

class StyledChunk {
  String text;
  int color;
  int? backgroundColor;
  bool isBold;
  bool isItalic;
  bool isUnderline;
  int? underlineColor;

  StyledChunk({
    required this.text,
    this.color = 0xFF000000,
    this.backgroundColor,
    this.isBold = false,
    this.isItalic = false,
    this.isUnderline = false,
    this.underlineColor,
  });

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'color': color,
      'backgroundColor': backgroundColor,
      'isBold': isBold,
      'isItalic': isItalic,
      'isUnderline': isUnderline,
      'underlineColor': underlineColor,
    };
  }

  factory StyledChunk.fromMap(Map<String, dynamic> map) {
    return StyledChunk(
      text: map['text'] ?? '',
      color: map['color'] ?? 0xFF000000,
      backgroundColor: map['backgroundColor'],
      isBold: map['isBold'] ?? false,
      isItalic: map['isItalic'] ?? false,
      isUnderline: map['isUnderline'] ?? false,
      underlineColor: map['underlineColor'],
    );
  }
}

class Source {
  String id;
  String name;
  String description;

  Source({required this.id, required this.name, this.description = ''});

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'description': description};
  }

  factory Source.fromMap(Map<String, dynamic> map) {
    return Source(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
    );
  }
}

class Verse {
  String id;
  String surahName;
  String verseNumber;
  String text;
  TextStyling styling;
  List<StyledChunk> chunks;
  String? selectedTafsirId;
  int? juz;
  bool isEdited;

  Verse({
    required this.id,
    required this.surahName,
    required this.verseNumber,
    required this.text,
    this.selectedTafsirId,
    this.juz,
    this.isEdited = false,
    TextStyling? styling,
    List<StyledChunk>? chunks,
  }) : styling = styling ?? TextStyling(fontSize: 22.0, isBold: true),
       chunks =
           chunks ??
           [
             StyledChunk(
               text: text,
               isBold: true,
               color:
                   (styling ?? TextStyling(fontSize: 22.0, isBold: true)).color,
             ),
           ];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'surahName': surahName,
      'verseNumber': verseNumber,
      'text': text,
      'styling': styling.toMap(),
      'chunks': chunks.map((c) => c.toMap()).toList(),
      'selectedTafsirId': selectedTafsirId,
      'juz': juz,
      'isEdited': isEdited,
    };
  }

  factory Verse.fromMap(Map<String, dynamic> map) {
    final v = Verse(
      id: map['id'] ?? '',
      surahName: map['surahName'] ?? '',
      verseNumber: map['verseNumber'] ?? '',
      text: map['text'] ?? '',
      styling: TextStyling.fromMap(map['styling'] ?? {}),
      selectedTafsirId: map['selectedTafsirId'],
      juz: map['juz'],
      chunks: (map['chunks'] as List?)
          ?.map((c) => StyledChunk.fromMap(c))
          .toList(),
      isEdited: map['isEdited'] ?? false,
    );
    return v;
  }
}

class Tafsir {
  String id;
  String text;
  String sourceId;
  TextStyling styling;
  List<StyledChunk> chunks;
  bool isEdited;

  Tafsir({
    required this.id,
    required this.text,
    required this.sourceId,
    this.isEdited = false,
    TextStyling? styling,
    List<StyledChunk>? chunks,
  }) : styling = styling ?? TextStyling(),
       chunks =
           chunks ??
           [StyledChunk(text: text, color: (styling ?? TextStyling()).color)];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'sourceId': sourceId,
      'styling': styling.toMap(),
      'chunks': chunks.map((c) => c.toMap()).toList(),
      'isEdited': isEdited,
    };
  }

  factory Tafsir.fromMap(Map<String, dynamic> map) {
    return Tafsir(
      id: map['id'] ?? '',
      text: map['text'] ?? '',
      sourceId: map['sourceId'] ?? '',
      styling: TextStyling.fromMap(map['styling'] ?? {}),
      chunks: (map['chunks'] as List?)
          ?.map((c) => StyledChunk.fromMap(c))
          .toList(),
      isEdited: map['isEdited'] ?? false,
    );
  }
}

class Project {
  String id;
  String? userId; // For cloud sync isolation
  String name;
  List<Verse> verses;
  List<Tafsir> tafsirs;
  List<Source> sources;
  Map<String, dynamic> theme;

  Project({
    required this.id,
    this.userId,
    required this.name,
    this.verses = const [],
    this.tafsirs = const [],
    this.sources = const [],
    this.theme = const {
      'backgroundColor': 0xFFFDFCF0,
      'borderColor': 0xFFD4AF37,
      'type': 'manuscript',
    },
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'verses': verses.map((v) => v.toMap()).toList(),
      'tafsirs': tafsirs.map((t) => t.toMap()).toList(),
      'sources': sources.map((s) => s.toMap()).toList(),
      'theme': theme,
    };
  }

  factory Project.fromMap(Map<String, dynamic> map) {
    return Project(
      id: map['id'] ?? '',
      userId: map['userId'],
      name: map['name'] ?? '',
      verses: (map['verses'] as List? ?? [])
          .map((v) => Verse.fromMap(v))
          .toList(),
      tafsirs: (map['tafsirs'] as List? ?? [])
          .map((t) => Tafsir.fromMap(t))
          .toList(),
      sources: (map['sources'] as List? ?? [])
          .map((s) => Source.fromMap(s))
          .toList(),
      theme: Map<String, dynamic>.from(map['theme'] ?? {}),
    );
  }
}
