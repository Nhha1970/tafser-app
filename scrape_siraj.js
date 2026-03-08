/**
 * سكربت لجلب بيانات "السراج في بيان غريب القرآن" من tafsir.app
 * 
 * طريقة الاستخدام:
 * 1. npm install puppeteer
 * 2. node scrape_siraj.js
 * 
 * سيُنتج ملف siraj_data.json يحتوي على بيانات التفسير لكل سورة
 */

const puppeteer = require('puppeteer');
const fs = require('fs');

// بيانات السور - الاسم وعدد الآيات
const SURAHS = [
    { num: 1, name: 'الفاتحة', ayahs: 7 },
    { num: 2, name: 'البقرة', ayahs: 286 },
    { num: 3, name: 'آل عمران', ayahs: 200 },
    { num: 4, name: 'النساء', ayahs: 176 },
    { num: 5, name: 'المائدة', ayahs: 120 },
    { num: 6, name: 'الأنعام', ayahs: 165 },
    { num: 7, name: 'الأعراف', ayahs: 206 },
    { num: 8, name: 'الأنفال', ayahs: 75 },
    { num: 9, name: 'التوبة', ayahs: 129 },
    { num: 10, name: 'يونس', ayahs: 109 },
    { num: 11, name: 'هود', ayahs: 123 },
    { num: 12, name: 'يوسف', ayahs: 111 },
    { num: 13, name: 'الرعد', ayahs: 43 },
    { num: 14, name: 'إبراهيم', ayahs: 52 },
    { num: 15, name: 'الحجر', ayahs: 99 },
    { num: 16, name: 'النحل', ayahs: 128 },
    { num: 17, name: 'الإسراء', ayahs: 111 },
    { num: 18, name: 'الكهف', ayahs: 110 },
    { num: 19, name: 'مريم', ayahs: 98 },
    { num: 20, name: 'طه', ayahs: 135 },
    { num: 21, name: 'الأنبياء', ayahs: 112 },
    { num: 22, name: 'الحج', ayahs: 78 },
    { num: 23, name: 'المؤمنون', ayahs: 118 },
    { num: 24, name: 'النور', ayahs: 64 },
    { num: 25, name: 'الفرقان', ayahs: 77 },
    { num: 26, name: 'الشعراء', ayahs: 227 },
    { num: 27, name: 'النمل', ayahs: 93 },
    { num: 28, name: 'القصص', ayahs: 88 },
    { num: 29, name: 'العنكبوت', ayahs: 69 },
    { num: 30, name: 'الروم', ayahs: 60 },
    { num: 31, name: 'لقمان', ayahs: 34 },
    { num: 32, name: 'السجدة', ayahs: 30 },
    { num: 33, name: 'الأحزاب', ayahs: 73 },
    { num: 34, name: 'سبأ', ayahs: 54 },
    { num: 35, name: 'فاطر', ayahs: 45 },
    { num: 36, name: 'يس', ayahs: 83 },
    { num: 37, name: 'الصافات', ayahs: 182 },
    { num: 38, name: 'ص', ayahs: 88 },
    { num: 39, name: 'الزمر', ayahs: 75 },
    { num: 40, name: 'غافر', ayahs: 85 },
    { num: 41, name: 'فصلت', ayahs: 54 },
    { num: 42, name: 'الشورى', ayahs: 53 },
    { num: 43, name: 'الزخرف', ayahs: 89 },
    { num: 44, name: 'الدخان', ayahs: 59 },
    { num: 45, name: 'الجاثية', ayahs: 37 },
    { num: 46, name: 'الأحقاف', ayahs: 35 },
    { num: 47, name: 'محمد', ayahs: 38 },
    { num: 48, name: 'الفتح', ayahs: 29 },
    { num: 49, name: 'الحجرات', ayahs: 18 },
    { num: 50, name: 'ق', ayahs: 45 },
    { num: 51, name: 'الذاريات', ayahs: 60 },
    { num: 52, name: 'الطور', ayahs: 49 },
    { num: 53, name: 'النجم', ayahs: 62 },
    { num: 54, name: 'القمر', ayahs: 55 },
    { num: 55, name: 'الرحمن', ayahs: 78 },
    { num: 56, name: 'الواقعة', ayahs: 96 },
    { num: 57, name: 'الحديد', ayahs: 29 },
    { num: 58, name: 'المجادلة', ayahs: 22 },
    { num: 59, name: 'الحشر', ayahs: 24 },
    { num: 60, name: 'الممتحنة', ayahs: 13 },
    { num: 61, name: 'الصف', ayahs: 14 },
    { num: 62, name: 'الجمعة', ayahs: 11 },
    { num: 63, name: 'المنافقون', ayahs: 11 },
    { num: 64, name: 'التغابن', ayahs: 18 },
    { num: 65, name: 'الطلاق', ayahs: 12 },
    { num: 66, name: 'التحريم', ayahs: 12 },
    { num: 67, name: 'الملك', ayahs: 30 },
    { num: 68, name: 'القلم', ayahs: 52 },
    { num: 69, name: 'الحاقة', ayahs: 52 },
    { num: 70, name: 'المعارج', ayahs: 44 },
    { num: 71, name: 'نوح', ayahs: 28 },
    { num: 72, name: 'الجن', ayahs: 28 },
    { num: 73, name: 'المزمل', ayahs: 20 },
    { num: 74, name: 'المدثر', ayahs: 56 },
    { num: 75, name: 'القيامة', ayahs: 40 },
    { num: 76, name: 'الإنسان', ayahs: 31 },
    { num: 77, name: 'المرسلات', ayahs: 50 },
    { num: 78, name: 'النبأ', ayahs: 40 },
    { num: 79, name: 'النازعات', ayahs: 46 },
    { num: 80, name: 'عبس', ayahs: 42 },
    { num: 81, name: 'التكوير', ayahs: 29 },
    { num: 82, name: 'الانفطار', ayahs: 19 },
    { num: 83, name: 'المطففين', ayahs: 36 },
    { num: 84, name: 'الانشقاق', ayahs: 25 },
    { num: 85, name: 'البروج', ayahs: 22 },
    { num: 86, name: 'الطارق', ayahs: 17 },
    { num: 87, name: 'الأعلى', ayahs: 19 },
    { num: 88, name: 'الغاشية', ayahs: 26 },
    { num: 89, name: 'الفجر', ayahs: 30 },
    { num: 90, name: 'البلد', ayahs: 20 },
    { num: 91, name: 'الشمس', ayahs: 15 },
    { num: 92, name: 'الليل', ayahs: 21 },
    { num: 93, name: 'الضحى', ayahs: 11 },
    { num: 94, name: 'الشرح', ayahs: 8 },
    { num: 95, name: 'التين', ayahs: 8 },
    { num: 96, name: 'العلق', ayahs: 19 },
    { num: 97, name: 'القدر', ayahs: 5 },
    { num: 98, name: 'البينة', ayahs: 8 },
    { num: 99, name: 'الزلزلة', ayahs: 8 },
    { num: 100, name: 'العاديات', ayahs: 11 },
    { num: 101, name: 'القارعة', ayahs: 11 },
    { num: 102, name: 'التكاثر', ayahs: 8 },
    { num: 103, name: 'العصر', ayahs: 3 },
    { num: 104, name: 'الهمزة', ayahs: 9 },
    { num: 105, name: 'الفيل', ayahs: 5 },
    { num: 106, name: 'قريش', ayahs: 4 },
    { num: 107, name: 'الماعون', ayahs: 7 },
    { num: 108, name: 'الكوثر', ayahs: 3 },
    { num: 109, name: 'الكافرون', ayahs: 6 },
    { num: 110, name: 'النصر', ayahs: 3 },
    { num: 111, name: 'المسد', ayahs: 5 },
    { num: 112, name: 'الإخلاص', ayahs: 4 },
    { num: 113, name: 'الفلق', ayahs: 5 },
    { num: 114, name: 'الناس', ayahs: 6 },
];

async function delay(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
}

async function scrapeSurah(page, surahNum) {
    const url = `https://tafsir.app/siraj/${surahNum}/1`;
    console.log(`  جاري فتح الصفحة: ${url}`);

    await page.goto(url, { waitUntil: 'networkidle2', timeout: 30000 });
    await delay(2000);

    // انقر على رابط السراج في غريب القرآن
    const clicked = await page.evaluate(() => {
        const link = document.querySelector('a[data-src="siraaj-ghareeb"]');
        if (link) {
            link.click();
            return true;
        }
        return false;
    });

    if (!clicked) {
        console.log(`  ⚠ لم يتم العثور على رابط السراج للسورة ${surahNum}`);
        return null;
    }

    await delay(3000); // انتظر تحميل المحتوى

    // استخرج نص التفسير من المودال
    const tafsirText = await page.evaluate(() => {
        const resultBody = document.querySelector('#modal .modal-body .result-body');
        const heading = document.querySelector('#modal .modal-body .result-hding');
        if (resultBody) {
            return {
                heading: heading ? heading.textContent.trim() : '',
                text: resultBody.innerHTML.trim(),
                plainText: resultBody.textContent.trim()
            };
        }
        return null;
    });

    return tafsirText;
}

async function scrapeAllAyahs(page, surahNum, totalAyahs) {
    const results = [];

    // افتح أول آية
    const url = `https://tafsir.app/siraj/${surahNum}/1`;
    await page.goto(url, { waitUntil: 'networkidle2', timeout: 30000 });
    await delay(2000);

    for (let ayah = 1; ayah <= totalAyahs; ayah++) {
        console.log(`    آية ${ayah}/${totalAyahs}`);

        // انتقل للآية المحددة
        const ayahUrl = `https://tafsir.app/siraaj-ghareeb/${surahNum}/${ayah}`;
        await page.goto(ayahUrl, { waitUntil: 'networkidle2', timeout: 30000 });
        await delay(2000);

        // استخرج البيانات
        const data = await page.evaluate(() => {
            const resultBody = document.querySelector('#modal .modal-body .result-body');
            const heading = document.querySelector('#modal .modal-body .result-hding');
            if (resultBody && resultBody.textContent.trim()) {
                return {
                    text: resultBody.textContent.trim()
                };
            }
            // ربما التفسير غير موجود لهذه الآية (الكلمات سهلة)
            return { text: '' };
        });

        results.push({
            ayah: ayah,
            text: data ? data.text : ''
        });

        // تأخير بسيط لتجنب الحظر
        await delay(500);
    }

    return results;
}

async function main() {
    console.log('🚀 بدء جلب بيانات السراج في بيان غريب القرآن...');
    console.log('');

    const browser = await puppeteer.launch({
        headless: 'new',
        args: ['--no-sandbox', '--disable-setuid-sandbox']
    });

    const page = await browser.newPage();
    await page.setViewport({ width: 1280, height: 800 });

    // اضبط اللغة العربية
    await page.setExtraHTTPHeaders({
        'Accept-Language': 'ar-SA,ar;q=0.9,en;q=0.8'
    });

    const allData = {};

    // ابدأ من أول سورة (أو أكمل من آخر نقطة توقف)
    let startFrom = 1;
    const outputFile = 'siraj_data.json';

    if (fs.existsSync(outputFile)) {
        try {
            const existing = JSON.parse(fs.readFileSync(outputFile, 'utf8'));
            Object.assign(allData, existing);
            const lastSurah = Math.max(...Object.keys(existing).map(Number));
            startFrom = lastSurah + 1;
            console.log(`📂 يوجد بيانات سابقة. البدء من سورة رقم ${startFrom}`);
        } catch (e) {
            console.log('⚠ خطأ في قراءة الملف السابق. البدء من البداية.');
        }
    }

    for (const surah of SURAHS) {
        if (surah.num < startFrom) continue;

        console.log(`\n📖 سورة ${surah.name} (${surah.num}/114) - ${surah.ayahs} آيات`);

        try {
            const ayahsData = await scrapeAllAyahs(page, surah.num, surah.ayahs);
            allData[surah.num] = {
                name: surah.name,
                ayahs: ayahsData
            };

            // احفظ بعد كل سورة (للأمان)
            fs.writeFileSync(outputFile, JSON.stringify(allData, null, 2), 'utf8');
            console.log(`  ✅ تم حفظ سورة ${surah.name}`);

        } catch (err) {
            console.error(`  ❌ خطأ في سورة ${surah.name}: ${err.message}`);
            // احفظ ما تم حتى الآن
            fs.writeFileSync(outputFile, JSON.stringify(allData, null, 2), 'utf8');
        }

        // تأخير بين السور
        await delay(1000);
    }

    await browser.close();
    console.log('\n🎉 اكتمل الجلب! البيانات محفوظة في siraj_data.json');
}

main().catch(console.error);
