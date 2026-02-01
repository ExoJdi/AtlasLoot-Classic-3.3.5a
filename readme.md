# AtlasLoot Classic — Wrath of the Lich King (3.3.5a)
**Backport from MoP Classic v5.2.1**  
**Special build for [Warmane](https://www.warmane.com/)**
Fully functional version of **AtlasLoot Classic** for **World of Warcraft 3.3.5a (Wrath of the Lich King)**, with retail-style UI and logic carefully adapted to the legacy API.
---
## 📌 Project Goals
- Backport **AtlasLoot Classic v5.2.1 (MoP Classic)** to **WoW 3.3.5a**
- Preserve **retail behavior, layout, and logic** as closely as possible
- Ensure **stability and correctness** over experimental features
- Full compatibility with **Warmane realms**
---
## 🧩 Features
### 🏰 Raids & Dungeons
- Extended boss loot tables
- Achievement integration directly in loot views
📷 *Screenshot: Raid boss loot table with achievements*
<img width="1093" height="716" alt="Снимок экрана 2026-02-01 214137" src="https://github.com/user-attachments/assets/bea1658c-c5e7-426c-91f3-fc0daba6de47" />
---
### ⚒️ Crafting
- Crafting popup window with full reagent list
- Retail-style crafting interaction
📷 *Screenshot: Crafting popup with reagents*
<img width="1092" height="717" alt="Снимок экрана 2026-02-01 214203" src="https://github.com/user-attachments/assets/d87aff13-59de-45ad-86ca-d8959f05eb66" />
---
### 🎨 User Interface
- Retail-like layout and scaling
- Correct icon sizes (classes, currencies, phases)
- Improved tooltip consistency
- Favorites system restored and fixed
📷 *Screenshot: Main AtlasLoot UI*  
<img width="1092" height="711" alt="Снимок экрана 2026-02-01 214223" src="https://github.com/user-attachments/assets/a8291f18-16d7-46af-ba3b-fc7c8372c105" />
<img width="1096" height="718" alt="Снимок экрана 2026-02-01 214236" src="https://github.com/user-attachments/assets/9bd437e3-2e7d-4fe9-9535-0ba2a4722366" />
---
## 🔧 Fixed & Improved
- Phase filtering logic (Classic / TBC / Wrath)
- Tooltip duplication issues (item level / item ID)
- Currency and emblem icon scaling
- Favorites icon rendering
- Class item drop categories
- Data cleanup from Cataclysm / MoP leftovers
---
## 🚧 Work in Progress
The following modules are **not finished yet** and are actively being worked on:
- **Model Module**
  - Incorrect or missing display IDs
  - Green placeholder models in some cases
- **Vendor Prices**
  - PvP vendors
  - Faction-based pricing
- **Crafting Popup Integrations**
  - Shift / Alt click support
  - Auctionator integration
  - Aux integration
---
## 📦 Installation
1. Download the latest release archive
2. Extract `AtlasLootClassic` into:
3. Make sure no other AtlasLoot versions are installed
4. Launch the game (WoW 3.3.5a)
---
## ⚠️ Notes
- This project is **not an official AtlasLoot release**
- Designed specifically for **Wrath of the Lich King 3.3.5a**
- Tested primarily on **Warmane**
- Retail API behavior is partially emulated where required
---
## 🛠 Development Status
This repository is under **active development**.  
Bug reports should include:
- Lua error (BugGrabber)
- Screenshot (if UI-related)
- Clear reproduction steps
---
## 📜 License
Original AtlasLoot authors retain all rights to their work.  
This repository is a **community backport and adaptation** for legacy Wrath servers.
---
**Made with pain, persistence, and too many green squares.**
## ☕ Support the Project
If you find this project useful and want to support further development, you can buy me a coffee here:
👉 https://boosty.to/exojdi
Any support helps keep this project alive and actively maintained.




