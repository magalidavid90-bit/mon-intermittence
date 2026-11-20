// Mon Intermittence : fonctionnement hors ligne
const VERSION="mi-v6";
const FICHIERS=["./","index.html","manifest.webmanifest","vendor/pdf.min.js","vendor/pdf.worker.min.js","icons/icon-192.png","icons/icon-512.png","mentions-legales.html","cgv.html","confidentialite.html"];
self.addEventListener("install",e=>{e.waitUntil(caches.open(VERSION).then(c=>c.addAll(FICHIERS)).then(()=>self.skipWaiting()))});
self.addEventListener("activate",e=>{e.waitUntil(caches.keys().then(k=>Promise.all(k.filter(x=>x!==VERSION).map(x=>caches.delete(x)))).then(()=>self.clients.claim()))});
self.addEventListener("fetch",e=>{const r=e.request;if(r.method!=="GET")return;const u=new URL(r.url);
  if(u.origin!==location.origin){e.respondWith(caches.match(r).then(c=>c||fetch(r).then(res=>{const cp=res.clone();caches.open(VERSION).then(ca=>ca.put(r,cp));return res}).catch(()=>c)));return}
  // réseau d'abord pour avoir la dernière version, cache si hors ligne
  e.respondWith(fetch(r).then(res=>{const cp=res.clone();caches.open(VERSION).then(c=>c.put(r,cp));return res}).catch(()=>caches.match(r).then(c=>c||caches.match("index.html"))))});
