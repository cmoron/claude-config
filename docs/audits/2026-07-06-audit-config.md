# Audit claude-config — suivi mensuel

**Date** : 2026-07-06
**Périmètre** : `~/src/claude-config` (config Claude Code personnelle de Cyril)
**Précédent** : [`2026-06-13-audit-config.md`](2026-06-13-audit-config.md)

---

## 1. TL;DR

Le socle reste sain : déploiement déclaratif (`install.sh` idempotent), hooks conformes
(gracieux via `command -v`), discipline d'audit maintenue (3e passage consécutif). Deux
dérives apparues depuis juin :

1. **~26 skills mattpocock** (`~/src/skills` + `~/.agents/skills`) déployés **hors modèle
   déclaratif** de ce repo — contournent les décisions du 13/06 (retrait de `grill-me`,
   arbitrages sur `handoff`/`improve-codebase-architecture`).
2. **`rtk` absent de la machine** — la tuyauterie (`RTK.md` importé, hook `PreToolUse`
   gracieux) était en place mais à vide (binaire non installé).

Et une récidive : la **doc a re-dérivé** (3e audit consécutif où `SKILL.md`/`README.md`
sont à resynchroniser). D'où la checklist anti-dérive ajoutée ce passage.

---

## 2. Constats

| Sévérité | Constat |
|---|---|
| 🔴 | **Skills mattpocock hors gouvernance** — `~/src/skills` (clone du repo mattpocock/skills, 25 skills hors `deprecated/`/`in-progress/`) et `~/.agents/skills` (3 skills : `find-skills`, `grilling`, `handoff`) chargés en dehors de `skills/` de ce repo, donc hors `install.sh`/allowlist. Contourne les décisions du 13/06 : `grill-me` (supprimé ce jour-là) est réintroduit via `~/src/skills/skills/productivity/grill-me` ; `handoff` et `improve-codebase-architecture` (écartés le 13/06) sont présents. Doublons fonctionnels observés : `grilling`/`grill-with-docs` (le repo garde `grill-with-docs`), `review` (skill mattpocock) vs `/review` (commande superpowers de ce repo), `tdd`/`diagnosing-bugs` (mattpocock) vs les skills équivalents de `superpowers`. |
| 🔴 | **`rtk` absent de la machine** — ni `command -v rtk` ni `brew list rtk` ne le trouvaient au début de cet audit (réinstallé par Cyril en cours de passage, cf. §4 Décisions). Tant qu'il est absent, `RTK.md` est importé pour rien et le hook `PreToolUse` Bash se dégrade silencieusement (aucune commande bloquée, mais aucun gain token non plus). |
| 🟠 | **Doc re-dérivée** — `skills/claude-config/SKILL.md` référençait `agents/` et `snippets/` (n'existent plus), listait une table MCP fausse (Gmail/Calendar comme MCP locaux au lieu de connecteurs claude.ai, `context7`/`playwright` comme MCP au lieu de plugins). `README.md` : skills `lotusim-developer`/`opensource-contributor` absents de la liste, plugins `jdtls-lsp` listé sans usage Java, `claude-code-setup`/`clangd-lsp` absents, ligne Statusline fausse (annoncée sur `UserPromptSubmit`, en réalité `PreToolUse` Skill + clé `statusLine`), hooks `reflect-nudge.sh` et `atuin` absents de la table. |
| 🟠 | **`ponytail` « à l'essai » sans éval depuis son ajout (28/06)** — plugin tiers installé, aucune mesure de gain/coût token faite depuis. |
| 🟡 | **Linear en double** — MCP `linear` dans `settings.json` (référence) **et** connecteur claude.ai Linear (non authentifié à ce jour) qui fait doublon. |
| 🟡 | **`blender` MCP hors repo** — déclaré dans `~/.claude.json`, pas dans `settings.json` : expérimentation non gouvernée par ce repo. |
| 🟡 | **Denylist incomplète** — `git push -f` (forme courte de `--force`) et `rm -rf ~`/`rm -rf /*`/`rm -rf .` n'étaient pas couverts par `permissions.deny`. |
| 🟡 | **Ménage dû** — `.codex` (fichier vide, vestige), `~/.claude/statusline.sh` + `~/.claude/statusline.log` (legacy pré-ccstatusline, février), `jdtls-lsp` activé sans aucun projet Java dans le périmètre. |
| ⚪ | **3 changements non commités** en début de passage — `settings.json` (Fable 5 + clangd-lsp), `skills/nvim-config/SKILL.md` (piège treesitter), `skills/lotusim-developer/` (référence debugging-physics) — committés en premier ce passage (§4). |

---

## 3. État de l'art (rappel)

Pas de nouveau tour de littérature ce passage (fait le 13/06, cf. audit précédent §2).
Le point saillant qui reste actionnable : la gouvernance des skills mattpocock (§2, adressée
en dehors du modèle allowlist qui avait pourtant tranché explicitement le 13/06 sur
`grill-me`/`handoff`/`improve-codebase-architecture`).

---

## 4. Décisions (2026-07-06, par Cyril)

- **`rtk`** : réinstallation traitée par Cyril pendant ce passage. État constaté en fin de
  passage : `command -v rtk` → `/opt/homebrew/bin/rtk` ; `brew list rtk` → `rtk 0.43.0`
  installé (Homebrew, Cellar). La tuyauterie (`RTK.md`, hook gracieux) redevient donc
  active. *(Note : `rtk init`/premier run a modifié `CLAUDE.md` (bloc rtk-instructions v2)
  et créé `.rtk/` à la racine — hors périmètre des instructions de ce passage, laissé
  inchangé, à traiter/committer séparément si Cyril le confirme.)*
- **Skills mattpocock** : **EN TEST** — pas de purge ni d'allowlist ce passage. Décision
  reportée au prochain audit (probable action : soit les rapatrier dans `skills/` sous
  gouvernance, soit les retirer si les doublons avec `superpowers`/skills du repo ne se
  justifient pas).
- **`ponytail`** : **KEEP** — jugé utile à l'usage malgré l'absence d'éval chiffrée.
- **Linear** : la référence reste `linear` dans `settings.json` ; déconnexion du connecteur
  claude.ai à faire manuellement côté claude.ai (hors périmètre de ce repo).
- **`blender`** : hors repo assumé — expérimentation, pas de gouvernance requise.
- **`jdtls-lsp`** : retiré (`enabledPlugins`) — aucun projet Java dans le périmètre actuel.

---

## 5. Actions exécutées ce passage

1. **Commits du travail en attente** (avant tout autre changement) :
   `settings.json` (Fable 5 + clangd-lsp) ; `skills/nvim-config/SKILL.md` (piège
   treesitter) ; `skills/lotusim-developer/` (référence `debugging-physics.md`).
2. **Denylist durcie** : ajout de `git push -f *`, `rm -rf ~*`, `rm -rf /*`, `rm -rf .`
   dans `permissions.deny`.
3. **`jdtls-lsp` retiré** de `enabledPlugins` (plugin reste installé, juste désactivé).
4. **Ménage** : `.codex` supprimé du repo (`git rm`) ; `~/.claude/statusline.sh` et
   `~/.claude/statusline.log` (legacy hors repo) supprimés.
5. **`skills/claude-config/SKILL.md` resynchronisé** : structure réelle (`agents/` et
   `snippets/` absents notés explicitement, `config/`/`docs/`/`assets/`/`RTK.md` ajoutés) ;
   table MCP refaite en distinguant MCP `settings.json` / plugin / connecteur claude.ai ;
   checklist anti-dérive ajoutée en fin de fichier.
6. **`README.md` resynchronisé** : skills `lotusim-developer`/`opensource-contributor`
   ajoutés ; table plugins officiels recomptée (12, `jdtls-lsp` retiré, `claude-code-setup`
   + `clangd-lsp` ajoutés) ; table tiers avec `ponytail` (2 plugins) ; table hooks refaite
   (ajout `reflect-nudge.sh` et `atuin`, ligne Statusline corrigée) ; § Structure aligné.
7. **`skills/linear/SKILL.md`** : la mention « MCP remote Linear actif » remplacée par la
   référence précise (`linear` dans `settings.json`, HTTP `mcp.linear.app/sse`) + note sur
   le doublon connecteur claude.ai.
8. **Cet audit** (`docs/audits/2026-07-06-audit-config.md`).
