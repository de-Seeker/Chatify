## [2.9] - 2026-09-07

### ✨ Features

- Simplified Chinese (zhCN) locale support, including CJK-safe chat fonts on Chinese clients
- Chinese clients now default to the client's own CJK font (AR Hei / AR Kai) instead of the Latin Friz Quadrata, fixing tofu boxes for 中文 in chat frames, edit boxes and quick buttons

### 🐛 Bug Fixes

- Add taint-safe visual mention notification route

- Preserve unreadable messages in chat history

- Make filter isolation diagnostics reproducible

- Skip AddMessage wrapping for combat log frames

- Decouple AddMessage taint protection from chat filters


### 🚀 New Features

- Add isolated ChatProxy foundation for taint-safe rendering

