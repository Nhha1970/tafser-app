'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {".git/COMMIT_EDITMSG": "47c276b69f8478ee156c6ac7f03c3b46",
".git/config": "0a6db1f45fbcb6882007b069c5af22eb",
".git/description": "a0a7c3fff21f2aea3cfa1d0316dd816c",
".git/HEAD": "5ab7a4355e4c959b0c5c008f202f51ec",
".git/hooks/applypatch-msg.sample": "ce562e08d8098926a3862fc6e7905199",
".git/hooks/commit-msg.sample": "579a3c1e12a1e74a98169175fb913012",
".git/hooks/fsmonitor-watchman.sample": "a0b2633a2c8e97501610bd3f73da66fc",
".git/hooks/post-update.sample": "2b7ea5cee3c49ff53d41e00785eb974c",
".git/hooks/pre-applypatch.sample": "054f9ffb8bfe04a599751cc757226dda",
".git/hooks/pre-commit.sample": "5029bfab85b1c39281aa9697379ea444",
".git/hooks/pre-merge-commit.sample": "39cb268e2a85d436b9eb6f47614c3cbc",
".git/hooks/pre-push.sample": "2c642152299a94e05ea26eae11993b13",
".git/hooks/pre-rebase.sample": "56e45f2bcbc8226d2b4200f7c46371bf",
".git/hooks/pre-receive.sample": "2ad18ec82c20af7b5926ed9cea6aeedd",
".git/hooks/prepare-commit-msg.sample": "2b5c047bdb474555e1787db32b2d2fc5",
".git/hooks/push-to-checkout.sample": "c7ab00c7784efeadad3ae9b228d4b4db",
".git/hooks/sendemail-validate.sample": "4d67df3a8d5c98cb8565c07e42be0b04",
".git/hooks/update.sample": "647ae13c682f7827c22f5fc08a03674e",
".git/index": "7b184da889938a33f86e30364b1e318b",
".git/info/exclude": "036208b4a1ab4a235d75c181e685e5a3",
".git/logs/HEAD": "fdb8e0ebf762d0cf06434a292e5a6cea",
".git/logs/refs/heads/gh-pages": "6202d74e6f08fdc3a4e21e8642aee58e",
".git/logs/refs/remotes/origin/gh-pages": "83afc1bca3928cf03517592bfb6f4244",
".git/objects/08/27c17254fd3959af211aaf91a82d3b9a804c2f": "360dc8df65dabbf4e7f858711c46cc09",
".git/objects/08/5ca8b218644da27770a1504faecd681a1d06ea": "946cb1b22c681b271a6bfd8f3e121de3",
".git/objects/27/3627ac5c16de771c5357895b9289b69c3f120a": "e34540e60587f1193d6ca2f8fd58577e",
".git/objects/28/d875f43de9fab85bae01133132c0ac8a0cf3a3": "e294acfc1ecf27341ecb9eff36f3fbf1",
".git/objects/32/dfd544dd367032d9750e95c0ba1ca7d16685f4": "a0e10e3dc55dca06f019439e5569ac1b",
".git/objects/35/05a3a1ca134f2cdf50c340c18a8a7f15952394": "50e6e18f33f0f2adac0c1e8bb7ef0d6a",
".git/objects/35/1dd5d594837da553060479694294d7a6c3cf11": "cdb5944cd36300fe11fc1d632ace5dff",
".git/objects/3a/8cda5335b4b2a108123194b84df133bac91b23": "1636ee51263ed072c69e4e3b8d14f339",
".git/objects/3b/63d12cde60a755febf4bbc9f664d6f69219d91": "3960f90ac32deaadb1b3ef2526544ab4",
".git/objects/3c/4219a72fdbbc96ba6f66104400fbdbd0e1ba39": "b24c1bb08bee5ec5672a623c2f729efa",
".git/objects/3e/38d7ad56aaddd8ed7dee0fd872b223eadadf44": "e0a2369b3c915b31a3d0170b2715bb17",
".git/objects/44/425aa8c282df9841932657dd04db4e6effcc3f": "572839b93e37435dc70bb54adc6d4f4b",
".git/objects/51/03e757c71f2abfd2269054a790f775ec61ffa4": "d437b77e41df8fcc0c0e99f143adc093",
".git/objects/58/56fc7c24dc3599d3fbb74b4d8610b53bfdaead": "879a702e352cf3ea3940fd9587546bd8",
".git/objects/5c/74dc42dc0a465ccbe894e2c59402fe20944895": "c93933c6384c4a21ae6ec27c8342752a",
".git/objects/60/2948bc77542a45534526bdf899db0fadf16465": "8123d8b9fdbdd42d775a1e819c3c2f2c",
".git/objects/62/a98a4250ab7ee6ede195f599218abd8105f69a": "c7cf729972271c935dfbc587cb70670e",
".git/objects/68/43fddc6aef172d5576ecce56160b1c73bc0f85": "2a91c358adf65703ab820ee54e7aff37",
".git/objects/6b/9862a1351012dc0f337c9ee5067ed3dbfbb439": "85896cd5fba127825eb58df13dfac82b",
".git/objects/6f/7661bc79baa113f478e9a717e0c4959a3f3d27": "985be3a6935e9d31febd5205a9e04c4e",
".git/objects/72/85c4a378c63c4f1e8ee81e1a5e84854a683f7c": "0a030376c34ce47de0270319c8bf1a03",
".git/objects/74/783d0e2b22c092aeba6bdfceb8773479bd00a5": "6b979cc575c5f60e052bcfbf8503a6bc",
".git/objects/7a/f5f8bcefd46d153649b06aad897614aad81fe7": "0c518911b80bb63dbe7c4cc1a1d2953e",
".git/objects/7b/122541b8e1ac89d9217014b6a96cbb044f030d": "3b41cd462dff3299e0299296ee710b15",
".git/objects/7c/3463b788d022128d17b29072564326f1fd8819": "37fee507a59e935fc85169a822943ba2",
".git/objects/80/72b4ddf0e599584fbe90a2fda8c04ae86e2f10": "765521d81f0ac92dfd6207fce8b89580",
".git/objects/85/63aed2175379d2e75ec05ec0373a302730b6ad": "997f96db42b2dde7c208b10d023a5a8e",
".git/objects/88/cfd48dff1169879ba46840804b412fe02fefd6": "e42aaae6a4cbfbc9f6326f1fa9e3380c",
".git/objects/8a/aa46ac1ae21512746f852a42ba87e4165dfdd1": "1d8820d345e38b30de033aa4b5a23e7b",
".git/objects/8e/21753cdb204192a414b235db41da6a8446c8b4": "1e467e19cabb5d3d38b8fe200c37479e",
".git/objects/91/097991f44683e3b9a7fdf48d5d6c8afd086580": "ab3a859daed4b4c009bed0f37b0b29e4",
".git/objects/93/b363f37b4951e6c5b9e1932ed169c9928b1e90": "c8d74fb3083c0dc39be8cff78a1d4dd5",
".git/objects/a7/3f4b23dde68ce5a05ce4c658ccd690c7f707ec": "ee275830276a88bac752feff80ed6470",
".git/objects/ad/1939bcf6d552295bce1b17d1090f27a2e8e7bd": "b797c5955da2502edeb6878454e259fe",
".git/objects/ad/ced61befd6b9d30829511317b07b72e66918a1": "37e7fcca73f0b6930673b256fac467ae",
".git/objects/b1/493029d9bd70f49078b24b5db512c904622297": "b961498d1a446016119f4f75cc80c1ad",
".git/objects/b1/b7de7c6e86588a71afe5b3d69bddfcc5f85ba7": "0d95c1f762c336814203a150ef89f94b",
".git/objects/b3/53920c6e7bb8920fc45466a86a364ee426d99c": "7dc375285f76792c5e88ce2eb7fe2a07",
".git/objects/b5/e66bd1a391c399b3a4c0c36d5825b4dde7297a": "51703ddd595e4f0aaa9cf7f811c86f1c",
".git/objects/b7/49bfef07473333cf1dd31e9eed89862a5d52aa": "36b4020dca303986cad10924774fb5dc",
".git/objects/b8/3e5237566191bde54bda55e61a6f6a6302736b": "85bf22ec6f8fc1a59973129bc175743e",
".git/objects/b9/2a0d854da9a8f73216c4a0ef07a0f0a44e4373": "f62d1eb7f51165e2a6d2ef1921f976f3",
".git/objects/b9/3e39bd49dfaf9e225bb598cd9644f833badd9a": "666b0d595ebbcc37f0c7b61220c18864",
".git/objects/bb/650a24edd6aded9dc9b6c6fc7191f5d7875f67": "b050c7c4cc287916e563921ea1644a43",
".git/objects/bb/d3e16a4c84dd3975c02d58e0d4515b4c13ed55": "29157ef052aa8707faeeb2d18c3f658f",
".git/objects/c4/0fd0fcd3c00956ef9e5249d595f592af3c2584": "d8b844e4b8651b991fa478173b84ff81",
".git/objects/c8/3af99da428c63c1f82efdcd11c8d5297bddb04": "144ef6d9a8ff9a753d6e3b9573d5242f",
".git/objects/d4/3532a2348cc9c26053ddb5802f0e5d4b8abc05": "3dad9b209346b1723bb2cc68e7e42a44",
".git/objects/d6/9c56691fbdb0b7efa65097c7cc1edac12a6d3e": "868ce37a3a78b0606713733248a2f579",
".git/objects/d7/7cfefdbe249b8bf90ce8244ed8fc1732fe8f73": "9c0876641083076714600718b0dab097",
".git/objects/d9/5b1d3499b3b3d3989fa2a461151ba2abd92a07": "a072a09ac2efe43c8d49b7356317e52e",
".git/objects/e9/94225c71c957162e2dcc06abe8295e482f93a2": "2eed33506ed70a5848a0b06f5b754f2c",
".git/objects/eb/9b4d76e525556d5d89141648c724331630325d": "37c0954235cbe27c4d93e74fe9a578ef",
".git/objects/f3/3e0726c3581f96c51f862cf61120af36599a32": "afcaefd94c5f13d3da610e0defa27e50",
".git/objects/f5/72b90ef57ee79b82dd846c6871359a7cb10404": "e68f5265f0bb82d792ff536dcb99d803",
".git/objects/f6/e6c75d6f1151eeb165a90f04b4d99effa41e83": "95ea83d65d44e4c524c6d51286406ac8",
".git/objects/f7/0123a89a5acd8b915e11adc9b92f7e26ec4379": "dd6a0533023d7db2454bbfaefe6213d7",
".git/objects/f8/ef39fb09be82c49b9808478666a452c3a2f1a4": "362cf7f579a8b4b30a22974c92bcffc7",
".git/objects/fd/05cfbc927a4fedcbe4d6d4b62e2c1ed8918f26": "5675c69555d005a1a244cc8ba90a402c",
".git/refs/heads/gh-pages": "1da8778606b236136b21e463e7825df0",
".git/refs/remotes/origin/gh-pages": "1da8778606b236136b21e463e7825df0",
"404.html": "26697b7bef1ede8dad5f87fe5c2934b6",
"assets/AssetManifest.bin": "432c59fbe8751d27cb637328abfefd45",
"assets/AssetManifest.bin.json": "f1456856171aab88074a936e8558c869",
"assets/assets/fonts/almushaf-1.ttf": "8eb530920ecc3095380fb10f976a5689",
"assets/assets/fonts/Alqalam_Quran_Majeed.ttf": "e20a6b391216020327bb989d37d61502",
"assets/assets/fonts/AlQuranAlKareem.ttf": "60b9f9d3674a0dd451e7a483edaafad3",
"assets/assets/fonts/Al_Qalam_Quran_Majeed2.ttf": "44e7b6985d2284ccba959b36fe639d13",
"assets/assets/fonts/amiri_quran.ttf": "145fd1b27addcc501a0750ed93477d0e",
"assets/assets/fonts/ArbFONTS-Amiri%2520Slanted.ttf": "c4087c23877b7d839a998a034faf2748",
"assets/assets/fonts/ArbFONTS-Amiri-Bold.ttf": "e4b743c97bdff5a67c5014fb19ee1bee",
"assets/assets/fonts/ArbFONTS-Amiri.ttf": "c966d010fa2d19bd874600c87188a429",
"assets/assets/fonts/ArbFONTS-Noon.ttf": "8adbf3f633dbc7faff1563f6e374a869",
"assets/assets/fonts/me_quran.ttf": "a79b204e9c3055c77f0d81921bd881c2",
"assets/assets/fonts/quran_taha.ttf": "54786d28c88b3627d0f3fc4fc9e5659b",
"assets/assets/fonts/UthmanicHafs1Ver08.otf": "7c0c99d532f135f63633578347912421",
"assets/FontManifest.json": "7dd79df0f6648a9e582731dbfcc42987",
"assets/fonts/MaterialIcons-Regular.otf": "1a614ff9f23a689f302ffffde5e2a268",
"assets/NOTICES": "c7a5c58799fe3ac489dd426349ae2509",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "33b7d9392238c04c131b6ce224e13711",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"assets/shaders/stretch_effect.frag": "40d68efbbf360632f614c731219e95f0",
"canvaskit/canvaskit.js": "8331fe38e66b3a898c4f37648aaf7ee2",
"canvaskit/canvaskit.js.symbols": "a3c9f77715b642d0437d9c275caba91e",
"canvaskit/canvaskit.wasm": "9b6a7830bf26959b200594729d73538e",
"canvaskit/chromium/canvaskit.js": "a80c765aaa8af8645c9fb1aae53f9abf",
"canvaskit/chromium/canvaskit.js.symbols": "e2d09f0e434bc118bf67dae526737d07",
"canvaskit/chromium/canvaskit.wasm": "a726e3f75a84fcdf495a15817c63a35d",
"canvaskit/skwasm.js": "8060d46e9a4901ca9991edd3a26be4f0",
"canvaskit/skwasm.js.symbols": "3a4aadf4e8141f284bd524976b1d6bdc",
"canvaskit/skwasm.wasm": "7e5f3afdd3b0747a1fd4517cea239898",
"canvaskit/skwasm_heavy.js": "740d43a6b8240ef9e23eed8c48840da4",
"canvaskit/skwasm_heavy.js.symbols": "0755b4fb399918388d71b59ad390b055",
"canvaskit/skwasm_heavy.wasm": "b0be7910760d205ea4e011458df6ee01",
"favicon.png": "5dcef449791fa27946b3d35ad8803796",
"flutter.js": "24bc71911b75b5f8135c949e27a2984e",
"flutter_bootstrap.js": "055249ae1df81f426aa4787c49f4de5c",
"icons/Icon-192.png": "ac9a721a12bbc803b44f645561ecb1e1",
"icons/Icon-512.png": "96e752610906ba2a93c65f8abe1645f1",
"icons/Icon-maskable-192.png": "c457ef57daa1d16f64b27b786ec2ea3c",
"icons/Icon-maskable-512.png": "301a7604d45b3e739efc881eb04896ea",
"index.html": "eadd94e4d9d73521c8d5ff9d74234032",
"/": "eadd94e4d9d73521c8d5ff9d74234032",
"main.dart.js": "9e67bd9dbe29dbae2d124d0fd6c9d4b2",
"manifest.json": "53b6b2a3ccb4661a66935307b0125b3f",
"version.json": "1187f201fbaa0f48e0b1e8faa19b3933"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
