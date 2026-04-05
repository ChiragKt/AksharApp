# अक्षर Akshar — Patch Notes

## All fixes applied in one pass

---

### 1. Unified Digit + Text into One List
- Removed the separate "Digit mode" and "Text mode" toggle entirely.  
- Recognition now runs **both** digit extraction and full-text recognition simultaneously on every input.  
- Results are merged, deduplicated, and sorted by confidence into a single unified list.  
- Each result tile has a small badge — `अंक · digit` or `अक्षर · text` — so you can still tell them apart at a glance.

---

### 2. Removed Mode Toggle
- The `SegmentedButton` / `ToggleButtons` widget for switching between Digit and Text modes is gone.  
- No state to manage, no confusion about which mode you're in.

---

### 3. Logo & Title — Subtle Decorations
- **Logo circle**: glows softly with a pulsing jade/teal aura (`AnimationController` with `repeat(reverse: true)`).  
- **`अ` glyph**: rendered with a matching shadow glow that breathes in sync with the circle.  
- **Title `अक्षर`**: gold-to-cream `ShaderMask` gradient shimmer.  
- **Subtitle**: `Akshar · Script Recognition` in jade teal, fine letterSpacing.  
- **Corner dot cluster**: a small decorative dot triangle in the top-right of the header, echoing the rangoli aesthetic.

---

### 4. iOS / Web / Android Compatibility

#### Flutter (`main.dart`)
- `kIsWeb` guard: on web, ML Kit (native binary) is unavailable. The app detects this and shows a friendly message instead of crashing.  
- `SafeArea` wraps all content for notched iPhones and punch-hole Android screens.  
- Responsive layout: **wide screens** (≥ 600 px, tablet/web) use a side-by-side `Row`; **narrow screens** stack vertically with a `Column + Expanded`.  
- No platform channels or FFI — pure Dart + approved packages.

#### `pubspec.yaml`
- `image_picker: ^1.1.2` — supports iOS, Android, and Web (camera/gallery).  
- `google_mlkit_text_recognition: ^0.13.1` — Devanagari model, runs on iOS & Android. (Web fallback in code.)

#### `web/index.html` (→ `web_index.html` in outputs)
- `apple-mobile-web-app-capable` + `apple-mobile-web-app-status-bar-style` for Add to Home Screen on iOS Safari.  
- `viewport-fit=cover` + `user-scalable=no` — fills the notch area correctly.  
- `theme-color: #1A0F08` — matches the mahogany background in the browser tab bar.  
- `overscroll-behavior: none` on `body` — prevents iOS rubber-band bounce.  
- Loading screen shows `अक्षर` in gold while Flutter initialises, then hides on `flutter-first-frame`.

---

### Files delivered
| File | What to do |
|------|-----------|
| `main.dart` | Replace `lib/main.dart` |
| `pubspec.yaml` | Replace root `pubspec.yaml` |
| `web_index.html` | Rename to `web/index.html`, replace existing |

After replacing, run:
```
flutter pub get
# iOS
cd ios && pod install && cd ..
flutter run
# Android / Web
flutter run -d chrome   # or android
```
