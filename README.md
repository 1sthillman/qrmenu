# AdlistQR

AdlistQR, restoranlar için QR kod tabanlı **garson çağırma** ve **sipariş verme** çözümüdür. Müşteriler masadaki QR kodunu tarar, mobil tarayıcılarında menüyü görüntüler ve doğrudan sipariş verebilir.

## Özellikler

- 📲 **QR Kod ile Giriş**
- 🔔 **Garson Çağırma** butonu
- 🛒 **Sepet Yönetimi** ve **Sipariş Onayı**
- 🔄 **Supabase Realtime** ile anlık güncellemeler
- 💳 **Adlist POS** entegrasyonu (örnek API çağrıları)
- ⚡ **TailwindCSS** ile mobil uyumlu, modern arayüz

## Hızlı Başlangıç (Yerel)

```bash
# Bağımlılıkları kurun
npm install

# Geliştirme sunucusunu başlatın
yarn dev   # veya npm run dev

# Tarayıcıda açın
http://localhost:8080/qr.html?restaurant=ana_restoran&table=1
```

## Yapılandırma

`src/config.js` dosyasını kendi Supabase projenize uyacak şekilde düzenleyin:

```js
export default {
  SUPABASE_URL: 'https://<proje-ref>.supabase.co',
  SUPABASE_KEY: '<anon-key>',
  ADLIST_POS_API: 'https://adlist-pos-api.com/endpoint',
  RESTAURANT_ID: 'ana_restoran'
}
```

## Dağıtım (GitHub Pages)

1. Reponuzu GitHub'a pushlayın.
2. Repo Ayarları → **Pages** bölümünden **Deployment Branch** olarak `main` (root) seçin.
3. Yayına çıktıktan sonra URL yapısı:
   ```
   https://<kullanici-adi>.github.io/<repo-adi>/qr.html?restaurant=ANA&table=5
   ```

---
MIT Lisansı © 2024 AdlistQR 
