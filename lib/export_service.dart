import 'dart:io' as io;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'tafser_model.dart';

typedef ExportProgressCallback =
    void Function(int current, int total, String stage);

class ExportService {
  static Future<void> exportToPdf(
    List<Verse> verses,
    List<Tafsir> tafsirs, {
    String? savePath,
    ExportProgressCallback? onProgress,
  }) async {
    final pdf = pw.Document();

    onProgress?.call(0, verses.length, 'جاري تحميل الخطوط...');

    final amiriData = await rootBundle.load("assets/fonts/ArbFONTS-Amiri.ttf");
    final amiri = pw.Font.ttf(amiriData);

    final amiriBoldData = await rootBundle.load(
      "assets/fonts/ArbFONTS-Amiri-Bold.ttf",
    );
    final amiriBold = pw.Font.ttf(amiriBoldData);

    onProgress?.call(0, verses.length, 'جاري إنشاء صفحات PDF...');

    // Group data by verse for sequential display
    final groupedData = _groupData(verses, tafsirs);
    final totalVerses = groupedData.length;

    const int itemsPerPage = 5;
    for (int i = 0; i < totalVerses; i += itemsPerPage) {
      final chunk = groupedData.sublist(
        i,
        i + itemsPerPage > totalVerses ? totalVerses : i + itemsPerPage,
      );

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          textDirection: pw.TextDirection.rtl,
          theme: pw.ThemeData.withFont(
            base: amiri,
            bold: amiriBold,
            fontFallback: [amiri],
          ),
          build: (context) {
            return [
              pw.Header(
                level: 0,
                child: pw.Center(
                  child: pw.Text(
                    'مشروع التفسير المختار - تصدير PDF',
                    style: pw.TextStyle(font: amiriBold, fontSize: 24),
                  ),
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Table(
                border: pw.TableBorder.all(
                  color: PdfColors.grey700,
                  width: 0.5,
                ),
                columnWidths: {
                  0: const pw.FlexColumnWidth(5), // Tafsir + Source
                  1: const pw.FlexColumnWidth(4), // Verse
                  2: const pw.FixedColumnWidth(80), // Surah/Juz
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.amber100,
                    ),
                    children: [
                      _headerCell('التفسير والمصدر', amiriBold),
                      _headerCell('الآية', amiriBold),
                      _headerCell('السورة والجزء', amiriBold),
                    ],
                  ),
                  ...chunk.map((data) {
                    final v = data['v'] as Verse;
                    final tList = data['t'] as List<Tafsir>;
                    final int verseNum = int.tryParse(v.verseNumber) ?? 1;

                    return pw.TableRow(
                      children: [
                        // Combined Tafsir + Source Cell
                        pw.Container(
                          color: PdfColors.yellow50,
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.RichText(
                            textAlign: pw.TextAlign.justify,
                            textDirection: pw.TextDirection.rtl,
                            text: pw.TextSpan(
                              children: [
                                for (
                                  int idx = 0;
                                  idx < tList.length;
                                  idx++
                                ) ...[
                                  if (idx > 0)
                                    pw.TextSpan(
                                      text: ' . ',
                                      style: pw.TextStyle(
                                        font: amiri,
                                        fontSize: 14,
                                        color: PdfColors.black,
                                      ),
                                    ),
                                  ..._buildSpansFromChunksPdf(
                                    tList[idx].chunks,
                                    amiri,
                                    amiriBold,
                                    14,
                                    isVerse: false,
                                  ),
                                  if (tList[idx].sourceId != '0') ...[
                                    pw.TextSpan(
                                      text: ' ',
                                    ), // Space before source
                                    _buildSourceLabelPdf(
                                      _getSourceNameById(tList[idx].sourceId),
                                      amiriBold,
                                    ),
                                  ],
                                ],
                              ],
                            ),
                          ),
                        ),
                        // Verse Cell
                        pw.Container(
                          padding: const pw.EdgeInsets.all(10),
                          color: PdfColors.yellow50,
                          child: pw.RichText(
                            textAlign: pw.TextAlign.center,
                            textDirection: pw.TextDirection.rtl,
                            text: pw.TextSpan(
                              children: [
                                ..._buildSpansFromChunksPdf(
                                  v.chunks,
                                  amiri,
                                  amiriBold,
                                  22,
                                  isVerse: true,
                                ),
                                pw.WidgetSpan(
                                  child: pw.Padding(
                                    padding: const pw.EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    child: _verseNumberDecorator(
                                      verseNum,
                                      amiriBold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        _sideCell(
                          '${v.surahName}\n(ج${v.juz ?? _computeJuz(v.surahName, verseNum)})',
                          amiri,
                          PdfColors.green100,
                        ),
                      ],
                    );
                  }).toList(),
                ],
              ),
            ];
          },
        ),
      );
      onProgress?.call(i + chunk.length, totalVerses, 'جاري كتابة الصفحات...');
      await Future.delayed(const Duration(milliseconds: 10));
    }

    onProgress?.call(totalVerses, totalVerses, 'جاري حفظ ملف PDF...');

    if (savePath != null && !kIsWeb) {
      final file = io.File(savePath);
      await file.writeAsBytes(await pdf.save());
    } else {
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );
    }
  }

  static List<pw.InlineSpan> _buildSpansFromChunksPdf(
    List<StyledChunk> chunks,
    pw.Font baseFont,
    pw.Font boldFont,
    double defaultSize, {
    required bool isVerse,
  }) {
    if (chunks.isEmpty) return [];

    List<StyledChunk> mergedChunks = [];
    if (chunks.isNotEmpty) {
      StyledChunk current = StyledChunk(
        text: chunks[0].text,
        color: chunks[0].color,
        backgroundColor: chunks[0].backgroundColor,
        isBold: chunks[0].isBold,
        isItalic: chunks[0].isItalic,
        isUnderline: chunks[0].isUnderline,
        underlineColor: chunks[0].underlineColor,
      );

      for (int i = 1; i < chunks.length; i++) {
        final next = chunks[i];
        bool sameStyle =
            next.color == current.color &&
            next.backgroundColor == current.backgroundColor &&
            next.isBold == current.isBold &&
            next.isItalic == current.isItalic &&
            next.isUnderline == current.isUnderline &&
            next.underlineColor == current.underlineColor;

        if (sameStyle) {
          current.text += next.text;
        } else {
          mergedChunks.add(current);
          current = StyledChunk(
            text: next.text,
            color: next.color,
            backgroundColor: next.backgroundColor,
            isBold: next.isBold,
            isItalic: next.isItalic,
            isUnderline: next.isUnderline,
            underlineColor: next.underlineColor,
          );
        }
      }
      mergedChunks.add(current);
    }

    List<pw.InlineSpan> allSpans = [];
    final markerRegex = RegExp(r'\[(.*?)\]');

    for (var chunk in mergedChunks) {
      // Clean newlines and extra spaces for ultra-compressed layout
      final text = chunk.text
          .replaceAll('\n', ' ')
          .replaceAll(RegExp(r' +'), ' ');
      final style = pw.TextStyle(
        font: chunk.isBold ? boldFont : baseFont,
        fontSize: defaultSize,
        color: PdfColor.fromInt(chunk.color),
        lineSpacing: isVerse ? 4 : 1.5,
        decoration: chunk.isUnderline ? pw.TextDecoration.underline : null,
        decorationColor: chunk.underlineColor != null
            ? PdfColor.fromInt(chunk.underlineColor!)
            : null,
        background: chunk.backgroundColor != null
            ? pw.BoxDecoration(color: PdfColor.fromInt(chunk.backgroundColor!))
            : null,
        fontStyle: chunk.isItalic ? pw.FontStyle.italic : pw.FontStyle.normal,
      );

      if (!isVerse) {
        int lastMatchEnd = 0;
        for (var match in markerRegex.allMatches(text)) {
          if (match.start > lastMatchEnd) {
            allSpans.add(
              pw.TextSpan(
                text: text.substring(lastMatchEnd, match.start),
                style: style,
              ),
            );
          }
          final markerText = match.group(1)!;
          if (markerText != 'المختار') {
            allSpans.add(_buildSourceLabelPdf(markerText, boldFont));
          } else {
            allSpans.add(pw.TextSpan(text: '[$markerText]', style: style));
          }
          lastMatchEnd = match.end;
        }
        if (lastMatchEnd < text.length) {
          allSpans.add(
            pw.TextSpan(text: text.substring(lastMatchEnd), style: style),
          );
        }
      } else {
        allSpans.add(pw.TextSpan(text: text, style: style));
      }
    }
    return allSpans;
  }

  static pw.Widget _headerCell(String text, pw.Font font) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(
        text,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(font: font, fontSize: 12),
      ),
    );
  }

  static pw.Widget _sideCell(String text, pw.Font font, PdfColor color) {
    return pw.Container(
      color: color,
      padding: const pw.EdgeInsets.all(5),
      alignment: pw.Alignment.center,
      child: pw.Text(
        text,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(font: font, fontSize: 11),
      ),
    );
  }

  static pw.InlineSpan _buildSourceLabelPdf(String name, pw.Font boldFont) {
    return pw.WidgetSpan(
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 1),
        decoration: pw.BoxDecoration(
          color: PdfColors.red100,
          border: pw.Border.all(color: PdfColors.red300, width: 0.5),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2)),
        ),
        child: pw.Column(
          mainAxisSize: pw.MainAxisSize.min,
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 2),
              child: pw.Text(
                name,
                style: pw.TextStyle(
                  font: boldFont,
                  fontSize: 8.5,
                  color: PdfColors.black,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _verseNumberDecorator(int number, pw.Font font) {
    return pw.Container(
      width: 28,
      height: 28,
      child: pw.Stack(
        alignment: pw.Alignment.center,
        children: [
          pw.Transform.rotate(
            angle: 0.785398,
            child: pw.Container(
              width: 20,
              height: 20,
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('004D40'),
                border: pw.Border.all(
                  color: PdfColor.fromHex('D4AF37'),
                  width: 1.2,
                ),
              ),
            ),
          ),
          pw.Container(
            width: 20,
            height: 20,
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('004D40'),
              border: pw.Border.all(
                color: PdfColor.fromHex('D4AF37'),
                width: 1.2,
              ),
            ),
          ),
          pw.Text(
            number.toString(),
            style: pw.TextStyle(
              font: font,
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
          ),
        ],
      ),
    );
  }

  static String _getSourceNameById(String id) {
    switch (id) {
      case '0':
        return 'المختار';
      case '1':
        return 'الجلالين';
      case '2':
        return 'الميسر';
      case '3':
        return 'غريب القرآن';
      case '4':
        return 'جامع البيان';
      case '5':
        return 'الوجيز';
      default:
        return id.isEmpty ? '' : id;
    }
  }

  static const List<String> _surahNames = [
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

  static const List<Map<String, dynamic>> _juzBoundaries = [
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

  static String _normalize(String name) {
    return name
        .replaceAll(RegExp(r'[أإآ]'), 'ا')
        .replaceAll('ة', 'ه')
        .replaceAll('ى', 'ي')
        .replaceAll(RegExp(r'[\u064B-\u065F]'), '')
        .replaceAll('سورة ', '')
        .replaceAll('سُورَةُ ', '')
        .trim();
  }

  static int _computeJuz(String surahName, int verseNumber) {
    final cleanName = _normalize(surahName);
    int targetSurahIndex = -1;
    for (int i = 0; i < _surahNames.length; i++) {
      if (_normalize(_surahNames[i]) == cleanName) {
        targetSurahIndex = i;
        break;
      }
    }
    if (targetSurahIndex == -1) return 1;
    for (int i = _juzBoundaries.length - 1; i >= 0; i--) {
      final b = _juzBoundaries[i];
      int bSurahIndex = -1;
      for (int k = 0; k < _surahNames.length; k++) {
        if (_normalize(_surahNames[k]) == _normalize(b['surah'])) {
          bSurahIndex = k;
          break;
        }
      }
      if (targetSurahIndex > bSurahIndex) return b['juz'] as int;
      if (targetSurahIndex == bSurahIndex && verseNumber >= (b['verse'] as int))
        return b['juz'] as int;
    }
    return 1;
  }

  static Future<void> exportToWord(
    List<Verse> verses,
    List<Tafsir> tafsirs, {
    String? savePath,
    ExportProgressCallback? onProgress,
  }) async {
    final content = await exportToWordContent(
      verses,
      tafsirs,
      onProgress: onProgress,
    );
    if (savePath != null && !kIsWeb) {
      await io.File(savePath).writeAsString(content);
    } else {
      final bytes = Uint8List.fromList(utf8.encode(content));
      final xFile = XFile.fromData(
        bytes,
        name: 'tafser_export_${DateTime.now().millisecondsSinceEpoch}.doc',
        mimeType: 'application/msword',
      );
      await Share.shareXFiles([
        xFile,
      ], text: 'تصدير الوورد - مشروع التفسير المختار');
    }
  }

  static Future<String> exportToWordContent(
    List<Verse> verses,
    List<Tafsir> tafsirs, {
    ExportProgressCallback? onProgress,
  }) async {
    final buffer = StringBuffer();
    onProgress?.call(0, verses.length, 'جاري تجهيز ملف الوورد...');
    buffer.write(
      '<html xmlns:v="urn:schemas-microsoft-com:vml" xmlns:o="urn:schemas-microsoft-com:office:office" xmlns:w="urn:schemas-microsoft-com:office:word" xmlns="http://www.w3.org/TR/REC-html40">',
    );
    buffer.write(
      '<head><meta charset="utf-8"><!--[if gte mso 9]><xml><v:background id="_x0000_s1025" fillcolor="white"/><o:shapelayout v:ext="edit"><o:idmap v:ext="edit" data="1"/></o:shapelayout></xml><![endif]--><style>body { font-family: "Amiri", "Traditional Arabic", serif; } .verse-text { font-family: "Amiri", serif; font-size: 22pt; font-weight: bold; direction: rtl; line-height: 1.8; } table { direction: rtl; border-collapse: collapse; width: 100%; } th, td { border: 1px solid black; padding: 10px; }</style></head><body dir="rtl">',
    );

    final groupedData = _groupData(verses, tafsirs);
    final totalVerses = groupedData.length;

    buffer.write(
      '<h1 style="text-align: center;">مشروع التفسير المختار - تصدير وورد</h1><table><tr style="background-color: #f2f2f2;"><th>السورة والجزء</th><th>الآية</th><th>التفسير والمصدر</th></tr>',
    );

    for (int i = 0; i < totalVerses; i++) {
      final data = groupedData[i];
      final v = data['v'] as Verse;
      final tList = data['t'] as List<Tafsir>;

      buffer.write(
        '<tr><td style="min-width: 80px; text-align: center;">${v.surahName}<br>(ج${v.juz ?? _computeJuz(v.surahName, int.tryParse(v.verseNumber) ?? 1)})</td><td class="verse-text" style="text-align: center;">',
      );
      buffer.write(_buildHtmlFromMergedChunksWord(v.chunks, isVerse: true));

      buffer.write(
        ' <!--[if gte mso 9]><v:group style="width:28pt;height:28pt;vertical-align:middle" coordsize="100,100"><v:rect style="position:absolute;width:60;height:60;left:20;top:20;rotation:45" fillcolor="#004D40" strokecolor="#D4AF37" strokeweight="1.5pt" /><v:rect style="position:absolute;width:60;height:60;left:20;top:20" fillcolor="#004D40" strokecolor="#D4AF37" strokeweight="1.5pt"><v:textbox inset="0,0,0,0"><div style="text-align:center;color:white;font-weight:bold;font-size:11pt;font-family:Arial;padding-top:10px;">${v.verseNumber}</div></v:textbox></v:rect></v:group><![endif]--><![if !mso]><span style="display: inline-block; vertical-align: middle; background-color: #004D40; border: 3px double #D4AF37; padding: 2px 8px; color: white; font-weight: bold; border-radius: 4px; font-family: Arial, sans-serif; font-size: 13pt; text-align: center; min-width: 25px;">${v.verseNumber}</span><![endif]>',
      );

      buffer.write(
        '</td><td><div style="direction: rtl; text-align: justify; line-height: 1.6;">',
      );

      for (int idx = 0; idx < tList.length; idx++) {
        if (idx > 0) buffer.write(' . ');
        buffer.write(
          _buildHtmlFromMergedChunksWord(tList[idx].chunks, isVerse: false),
        );
        if (tList[idx].sourceId != '0') {
          buffer.write(' ');
          final sourceName = _getSourceNameById(tList[idx].sourceId);
          buffer.write(
            '<span style="display: inline-block; background-color: #ffcdd2; padding: 2px 6px; border: 1px solid #ef9a9a; border-radius: 4px; font-size: 10pt; color: black; font-weight: bold; white-space: nowrap;">$sourceName</span>',
          );
        }
      }

      buffer.write('</div></td></tr>');

      if (i % 50 == 0) {
        onProgress?.call(
          i,
          totalVerses,
          'جاري كتابة الآية ${i + 1} من $totalVerses...',
        );
        await Future.delayed(const Duration(milliseconds: 5));
      }
    }
    buffer.write('</table></body></html>');
    return buffer.toString();
  }

  static String _buildHtmlFromMergedChunksWord(
    List<StyledChunk> chunks, {
    required bool isVerse,
  }) {
    if (chunks.isEmpty) return '';
    List<StyledChunk> merged = [];
    StyledChunk current = StyledChunk(
      text: chunks[0].text,
      color: chunks[0].color,
      backgroundColor: chunks[0].backgroundColor,
      isBold: chunks[0].isBold,
      isItalic: chunks[0].isItalic,
      isUnderline: chunks[0].isUnderline,
      underlineColor: chunks[0].underlineColor,
    );

    for (int i = 1; i < chunks.length; i++) {
      final next = chunks[i];
      if (next.color == current.color &&
          next.backgroundColor == current.backgroundColor &&
          next.isBold == current.isBold &&
          next.isItalic == current.isItalic &&
          next.isUnderline == current.isUnderline &&
          next.underlineColor == current.underlineColor) {
        current.text += next.text;
      } else {
        merged.add(current);
        current = StyledChunk(
          text: next.text,
          color: next.color,
          backgroundColor: next.backgroundColor,
          isBold: next.isBold,
          isItalic: next.isItalic,
          isUnderline: next.isUnderline,
          underlineColor: next.underlineColor,
        );
      }
    }
    merged.add(current);

    final buffer = StringBuffer();
    final markerRegex = RegExp(r'\[(.*?)\]');

    for (var chunk in merged) {
      // Clean newlines and extra spaces for ultra-compressed layout
      final text = chunk.text
          .replaceAll('\n', ' ')
          .replaceAll(RegExp(r' +'), ' ');
      String hexColor =
          '#${(chunk.color & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
      String? bgHex = chunk.backgroundColor != null
          ? '#${(chunk.backgroundColor! & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}'
          : null;
      String style = 'color: $hexColor;';
      if (chunk.isBold) style += ' font-weight: bold;';
      if (chunk.isItalic) style += ' font-style: italic;';
      if (chunk.isUnderline) {
        style += ' text-decoration: underline;';
        if (chunk.underlineColor != null) {
          String uHex =
              '#${(chunk.underlineColor! & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
          style += ' text-decoration-color: $uHex;';
        }
      }
      if (bgHex != null) style += ' background-color: $bgHex;';

      if (!isVerse) {
        int lastMatchEnd = 0;
        for (var match in markerRegex.allMatches(text)) {
          if (match.start > lastMatchEnd) {
            buffer.write(
              '<span style="$style">${text.substring(lastMatchEnd, match.start)}</span>',
            );
          }
          final markerText = match.group(1)!;
          if (markerText != 'المختار') {
            buffer.write(
              '<span style="display: inline-block; vertical-align: middle; background-color: #ffcdd2; padding: 1px 4px; border: 1px solid #ef9a9a; border-radius: 2px; font-size: 8pt; color: black; font-weight: bold; text-align: center; line-height: 1;">تفسير<br>$markerText</span>',
            );
          } else {
            buffer.write('<span style="$style">[$markerText]</span>');
          }
          lastMatchEnd = match.end;
        }
        if (lastMatchEnd < text.length) {
          buffer.write(
            '<span style="$style">${text.substring(lastMatchEnd)}</span>',
          );
        }
      } else {
        buffer.write('<span style="$style">$text</span>');
      }
    }
    return buffer.toString();
  }

  static Future<void> exportToCode(
    List<Verse> verses,
    List<Tafsir> tafsirs, {
    String? savePath,
    ExportProgressCallback? onProgress,
  }) async {
    final buffer = StringBuffer();
    buffer.writeln(
      "// ملف بيانات التفسير المختار - كود Dart مولد مع التنسيقات",
    );
    buffer.writeln("const List<Map<String, dynamic>> exportedData = [");

    final groupedData = _groupData(verses, tafsirs);
    final totalVerses = groupedData.length;

    onProgress?.call(0, totalVerses, 'جاري إنشاء كود Dart...');
    for (int i = 0; i < totalVerses; i++) {
      final data = groupedData[i];
      final v = data['v'] as Verse;
      final tList = data['t'] as List<Tafsir>;

      final verseMap = {
        'id': v.id,
        'surah': v.surahName,
        'num': v.verseNumber,
        'text': v.text,
        'chunks': v.chunks.map((c) => c.toMap()).toList(),
        'tafsirs': tList
            .map(
              (t) => {
                'id': t.id,
                'source': t.sourceId,
                'text': t.text,
                'chunks': t.chunks.map((c) => c.toMap()).toList(),
              },
            )
            .toList(),
      };

      final jsonPart = jsonEncode(verseMap);
      buffer.writeln("  $jsonPart,");

      if (i % 100 == 0) {
        onProgress?.call(
          i,
          totalVerses,
          'جاري معالجة الآية ${i + 1} من $totalVerses...',
        );
      }
    }
    buffer.writeln("];");
    final code = buffer.toString();
    try {
      await Clipboard.setData(ClipboardData(text: code));
    } catch (_) {}
    if (savePath != null && !kIsWeb) {
      await io.File(savePath).writeAsString(code);
    } else {
      final xFile = XFile.fromData(
        Uint8List.fromList(utf8.encode(code)),
        name: 'tafser_export_${DateTime.now().millisecondsSinceEpoch}.dart',
        mimeType: 'application/dart',
      );
      await Share.shareXFiles([
        xFile,
      ], text: 'تصدير كود Dart - مشروع التفسير المختار');
    }
  }

  static Future<void> exportToFullJson(
    Project project, {
    String? savePath,
    ExportProgressCallback? onProgress,
  }) async {
    onProgress?.call(0, 1, 'جاري تحويل المشروع إلى JSON...');
    final jsonString = const JsonEncoder.withIndent(
      '  ',
    ).convert(project.toMap());
    if (savePath != null && !kIsWeb) {
      await io.File(savePath).writeAsString(jsonString);
    } else {
      final xFile = XFile.fromData(
        Uint8List.fromList(utf8.encode(jsonString)),
        name: 'tafser_project_${DateTime.now().millisecondsSinceEpoch}.json',
        mimeType: 'application/json',
      );
      await Share.shareXFiles([
        xFile,
      ], text: 'تصدير مشروع التفسير المختار - JSON');
    }
  }

  static List<Map<String, dynamic>> _groupData(
    List<Verse> verses,
    List<Tafsir> tafsirs,
  ) {
    final List<Map<String, dynamic>> grouped = [];
    for (int i = 0; i < verses.length; i++) {
      final v = verses[i];
      final t = tafsirs[i];
      int foundIdx = -1;
      for (int j = 0; j < grouped.length; j++) {
        final existingV = grouped[j]['v'] as Verse;
        if (existingV.surahName == v.surahName &&
            existingV.verseNumber == v.verseNumber) {
          foundIdx = j;
          break;
        }
      }
      if (foundIdx != -1) {
        (grouped[foundIdx]['t'] as List<Tafsir>).add(t);
      } else {
        grouped.add({
          'v': v,
          't': [t],
        });
      }
    }
    return grouped;
  }
}
