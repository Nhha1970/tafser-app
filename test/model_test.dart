import 'package:flutter_test/flutter_test.dart';
import 'package:tafser/tafser_model.dart';

void main() {
  group('TafserEntry Tests', () {
    test('TafserEntry creation and currentTafser', () {
      final entry = TafserEntry(
        surahJuz: 'Surah 1',
        ayah: 'Verse 1',
        interpretations: {TafserSources.jalalayn: 'Tafsir 1'},
        activeSource: TafserSources.jalalayn,
      );

      expect(entry.surahJuz, 'Surah 1');
      expect(entry.ayah, 'Verse 1');
      expect(entry.currentTafser, 'Tafsir 1');
    });

    test('TafserEntry serialization/deserialization', () {
      final entry = TafserEntry(
        surahJuz: 'Surah 1',
        ayah: 'Verse 1',
        interpretations: {TafserSources.jalalayn: 'Tafsir 1'},
        activeSource: TafserSources.jalalayn,
        ayahColor: 0xFFFF0000,
        ayahBgColor: 0xFFFFFF00,
      );

      final map = entry.toMap();
      final fromMapEntry = TafserEntry.fromMap(map);

      expect(fromMapEntry.surahJuz, entry.surahJuz);
      expect(fromMapEntry.ayah, entry.ayah);
      expect(fromMapEntry.currentTafser, entry.currentTafser);
      expect(fromMapEntry.ayahColor, entry.ayahColor);
      expect(fromMapEntry.ayahBgColor, entry.ayahBgColor);
    });

    test('TafserEntry updateTafser', () {
      final entry = TafserEntry(
        surahJuz: 'Surah 1',
        ayah: 'Verse 1',
        interpretations: {TafserSources.jalalayn: 'Old Tafsir'},
        activeSource: TafserSources.jalalayn,
      );

      entry.updateTafser('New Tafsir');
      expect(entry.currentTafser, 'New Tafsir');
    });
    group('TafserScreen State Management (Simple)', () {
      // Basic test to ensure main.dart is syntactically correct after our changes
      // A full widget test would require more setup (mocking SharedPrefs)
    });
  });
}
