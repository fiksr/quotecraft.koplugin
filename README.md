# 📜 QuoteCraft for KOReader

[![KOReader](https://img.shields.io/badge/KOReader-2024%2B-blue.svg)](https://github.com/koreader/koreader)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![E-Ink Optimized](https://img.shields.io/badge/E--Ink-Optimized-black.svg)]()
[![KOReader Plugin](https://img.shields.io/badge/Storefront-Compatible-purple.svg)](https://omer-faruq.github.io/koreader-plugin-index/)

**QuoteCraft** turns your book highlights into gorgeous, high-resolution typographic quote cards directly on your e-reader. Export cards to PNG, copy formatted citations, or set any quote directly as your **Kindle/Kobo Lockscreen Wallpaper** with a single tap.

---

## ✨ Features

- 🖋️ **Typographic Quote Cards**: Automatically renders selected text with curly quotation marks, book title, author, chapter, and page citation.
- 🎨 **4 E-Ink Optimized Themes**:
  - **Classic Literary**: Serif typography, decorative quotation marks, elegant rule dividers, and optional miniature book cover thumbnail.
  - **Modern Minimal**: Contemporary sans-serif, bold vertical quote accent bar, and sleek metadata footer.
  - **Vintage Bookplate**: Centered ornate styling with a decorative double-line frame border and diamond flourish (`— ◆ —`).
  - **Dark Mode**: High-contrast inverted styling (pure black background, crisp white typography).
- 🖼️ **1-Tap Lockscreen Wallpaper**: Set your favorite quote as your e-reader's sleep screen screensaver instantly.
- 💾 **High-Resolution PNG Export**: Saves clean, watermark-free images to `/mnt/us/quotes/` for easy sharing via USB, WebDAV, or SSH.
- 🔍 **Integrated with Highlight Menu**: Seamlessly adds **"Create Quote Card"** to KOReader's native text selection dialog.
- ⚡ **Zero Battery Impact**: Pure on-demand rendering with no background polling or CPU wakeups.

---

## 📸 How It Works

1. **Highlight Any Text**: While reading any EPUB, MOBI, or PDF in KOReader, select a passage.
2. **Tap "Create Quote Card"**: QuoteCraft generates a full-screen typographic card.
3. **Customize & Export**:
   - Tap **🎨 Theme** to cycle styles (*Classic*, *Modern*, *Bookplate*, *Dark*).
   - Tap **💾 Save PNG** to export the card to `/mnt/us/quotes/`.
   - Tap **🖼️ Set Lockscreen** to set the quote as your sleep wallpaper.
   - Tap **📋 Copy** to copy the formatted quote with book citation to your clipboard.

---

## 🚀 Installation

### Option 1: Via Storefront / AppStore (1-Click Install)
1. Open KOReader on your device.
2. Go to **Tools** ➔ **App Store** (or **Storefront**).
3. Search for **QuoteCraft** and tap **Install**.
4. Restart KOReader.

### Option 2: Manual Installation
1. Download the latest `quotecraft.koplugin.zip` from the [Releases](https://github.com/) page.
2. Extract the archive into your KOReader plugins directory:
   - **Kindle**: `/mnt/us/koreader/plugins/quotecraft.koplugin/`
   - **Kobo**: `.kobo/koreader/plugins/quotecraft.koplugin/`
   - **Android**: `/sdcard/koreader/plugins/quotecraft.koplugin/`
3. Restart KOReader.

---

## ⚙️ Configuration

Open **Tools** ➔ **QuoteCraft** from the top menu:
- **📁 Browse Saved Quotes**: Opens KOReader's file browser at your quotes folder (`/mnt/us/quotes/`).
- **🎨 Default Style**: Choose your preferred starting theme.
- **🖼️ Include Book Cover**: Toggle whether to render miniature cover art on cards.
- **📖 Include Chapter & Page**: Toggle chapter and page numbers in citation footers.

---

## 📄 License

MIT License. Designed with love for the KOReader community.
