# Chatify — development repository

This is the **authoritative source** for the Chatify build that runs in the game.
The copy inside the WoW `AddOns` folder is a *deployment target* only: the game
client and CurseForge updates replace that whole folder (including any `.git`),
so it must never be treated as the place where work lives.

```
D:\Chatify-Dev\                 ← this repo: edit, commit, push here
   ├── .git\                    ← history (never touched by game updates)
   ├── deploy.ps1               ← copies this tree into the game folder
   └── (addon sources)

C:\Program Files (x86)\World of Warcraft\_retail_\Interface\AddOns\Chatify\
                                ← deployment copy, no .git, safe to be overwritten
```

## Daily workflow

```powershell
# 1. edit sources here in D:\Chatify-Dev
# 2. test in game:
powershell -ExecutionPolicy Bypass -File .\deploy.ps1
#    then type /reload in game
# 3. save your work
git add -A
git commit -m "describe the change"
git push
```

Preview what a deploy would change without touching anything:

```powershell
powershell -ExecutionPolicy Bypass -File .\deploy.ps1 -DryRun
```

The script mirrors the tree (files deleted here are deleted in the game folder
too) while never copying `.git`, `.gitattributes`, `deploy.ps1` or `README.md`.

## Branch layout

| Branch / commit | Meaning |
| --- | --- |
| `main` | current build (official release + local customisations) |
| `8c15517` | pristine upstream **2.9** release, no local changes |
| `1d4dc18` | the zhCN locale + CJK font work, as a self-contained commit |
| `a131d7b` | adds `deploy.ps1` |
| `legacy-2.8-zhcn` (remote) | previous build, kept as a fallback |

## After a WoW / CurseForge addon update

An update overwrites the game folder — that is now harmless, your work is here.

```powershell
# the game folder is stale, just redeploy the current build:
powershell -ExecutionPolicy Bypass -File .\deploy.ps1
```

## When upstream ships a new version (e.g. 3.0)

```powershell
# 1. commit the new upstream files as their own baseline
git add -A
git commit -m "upstream: Chatify 3.0"

# 2. replay the localisation work on top of it
git cherry-pick 1d4dc18        # zhCN locale + CJK fonts
#    resolve any conflicts, then:
git cherry-pick --continue
git push

# 3. deploy
powershell -ExecutionPolicy Bypass -File .\deploy.ps1
```

If the cherry-pick conflicts, the conflict markers show exactly where upstream
changed the same lines the localisation touches.

## Local customisations in this repo

1. **zhCN (Simplified Chinese) locale** — `locale/zhCN.lua` plus registration in
   `Locales.lua` and all six `.toc` files.
2. **CJK-safe chat fonts** — in `Config.lua`:
   - `Chatify: 中文黑体 (AR Hei)` / `Chatify: 中文楷体 (AR Kai)` font entries,
     added on `zhCN`/`zhTW` clients only.
   - `IsCJKClient()`, `IsLatinOnlyFontPath()`, `GetCJKFontPath()`,
     `GetDefaultChatFontPath()` helpers.
   - `ns.ResolveFontPath()` swaps a Latin-only face (Friz Quadrata, Exo 2, Inter)
     for the client's own CJK font, so Chinese text in chat frames and edit boxes
     no longer renders as tofu boxes. Third-party LSM fonts are left alone.
   - Chinese clients default to AR Hei instead of the Latin Friz Quadrata.
