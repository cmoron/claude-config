# Audit claude-config — état de l'art & analyse d'écart

**Date** : 2026-05-15
**Périmètre** : `~/src/claude-config` (config Claude Code personnelle de Cyril)
**Objectif** : rationaliser la config — réduire le coût (tokens + temps), corriger les
défauts, combler les angles morts, sans sur-couper (cible : *trim raisonné*).

---

## 1. TL;DR

La config est globalement saine et déjà réfléchie (échelle d'effort, toolchains
explicites, hooks utiles). Trois problèmes réels :

1. **Déploiement non synchronisé** — `install.sh` crée des symlinks mais n'en
   supprime jamais. Résultat : 11 agents + 3 commands morts dans `~/.claude/`.
2. **Hétérogénéité de qualité** — 3 agents sur 6 sont du copier-coller générique
   anglais (et invoquent un agent `context-manager` inexistant).
3. **Taxe tokens fixe par session** mal maîtrisée — ~18 skills Anthropic
   symlinkés en bloc + double injection SessionStart (superpowers + claude-mem).

Aucun de ces points ne justifie de reconstruire la config. Superpowers reste
pertinent. Un plugin custom n'est utile que pour **un** besoin précis (cf. §6).

---

## 2. État de l'art (références demandées)

### gstack (Garry Tan)
Framework MIT qui transforme Claude Code en « équipe virtuelle » de rôles startup
(CEO, EM, Designer, QA Lead, Security Officer). 28 slash commands. Idées à retenir :
- **`/slop-scan`** — détection de patterns « AI slop » (qualité sous le standard humain).
- **`/office-hours`** — questions de cadrage produit avant de coder (≈ `brainstorming`).
- **Daemon Chromium persistant** pour `/browse` — supprime le cold-start du browser.
- Limite : très orienté « solo founder qui livre un SaaS », rôles peu utiles pour
  un dev/CTO outillé. À piller pour les idées, pas à adopter en bloc.

### Peter Steinberger / openclaw
Pratiques convergentes avec la config actuelle : repo centralisé symlinkévers
`~/.claude/`, `install.sh` idempotent, skills comme « expertise encodée »,
sous-agents spécialisés. Insiste sur le **terminal-native** et la frugalité de
contexte. Rien de cassant — confirme la direction prise.

### Linus Torvalds (kernel)
Principes transposables à une config d'agent :
- **« Good taste »** — éliminer les cas particuliers plutôt que les empiler
  (ici : un seul mécanisme de déploiement, pas 3 chemins de symlink).
- **Commits petits et atomiques** — déjà appliqué (Conventional Commits).
- **Pas de sur-ingénierie spéculative** — ne pas construire un plugin custom
  « au cas où ». YAGNI.
- **Maintenabilité > cleverness** — un `install.sh` lisible qui *réconcilie* l'état
  vaut mieux qu'un script malin qui accumule.

### Superpowers (obra / Jesse Vincent) — challenge
- Workflow `brainstorm → plan → implement`, worktrees, TDD RED/GREEN.
- **Gain mesuré** : 40–60 % de tokens économisés sur les tâches multi-fichiers
  complexes (le plan évite l'errance dans le codebase).
- **Coût** : sur une petite tâche, générer un plan coûte *plus* de tokens que
  d'exécuter directement. C'est exactement ce que l'échelle d'effort du `CLAUDE.md`
  tente de neutraliser.
- **Tension réelle** : le skill `using-superpowers` est volontairement agressif
  (« 1 % de chance → tu DOIS invoquer le skill », « every project goes through
  brainstorming, even a todo list »). Il est injecté à chaque `SessionStart` et
  **contredit frontalement** l'échelle d'effort XS/S du `CLAUDE.md`. La priorité
  d'instruction joue en faveur du `CLAUDE.md`, mais le cadrage agressif arrive en
  premier dans le contexte et pousse au sur-process.
- **Verdict** : superpowers est bon *à la carte* (skills `systematic-debugging`,
  `test-driven-development`, `brainstorming`, `writing-plans`). Le problème n'est
  pas le plugin, c'est le **bootstrap par défaut** qui ne connaît pas l'échelle
  d'effort de Cyril.

---

## 3. Diagnostic de l'existant

### Symlinks morts (`~/.claude/`)
`install.sh` ne fait que `ln -sf`. Quand un fichier disparaît du repo (commit
`41569fe` « trim agents »), son symlink reste. Morts actuels :

- **Agents (11)** : `architect-reviewer`, `code-reviewer`, `compliance-auditor`,
  `debugger`, `deployment-engineer`, `devops`, `docker-expert`,
  `it-ops-orchestrator`, `penetration-tester`, `security-auditor`, `sre-engineer`.
- **Commands (3)** : `bootstrap`, `implement`, `review`.

Impact : pollution, risque de confusion, agents fantômes listés au routing.

### Agents — qualité hétérogène
| Agent | Lignes | Langue | Verdict |
|---|---|---|---|
| `python-pro` | 30 | FR | ✅ Taillé pour la stack Cyril (uv/ruff/mypy) |
| `rust-pro` | 22 | FR | ✅ Idem (clippy, thiserror/anyhow) |
| `software-architect` | 58 | FR | ✅ Cohérent |
| `api-designer` | 236 | EN | ❌ Copier-coller générique upstream |
| `ui-designer` | 173 | EN | ❌ Idem |
| `fullstack-developer` | 234 | EN | ❌ Idem |

Les 3 derniers viennent de `awesome-claude-code-subagents`, n'ont pas été adaptés,
et **invoquent un agent `context-manager` qui n'existe pas** dans la config →
instructions mortes. Incohérence de langue et de densité avec les 3 bons agents.

### Skills
- **7 skills custom** — bien ciblés, descriptions correctes. RAS, sauf :
  - `notion` est **obsolète** (confirmé) : la base documentaire DecaSaaS est
    désormais sur **Docmost auto-hébergé**, plus Notion. Le skill décrit un
    workspace et un MCP qui ne sont plus utilisés → à supprimer et remplacer par
    un skill `docmost`.
  - `openclaw` — enrichi (2026-05-15) d'une section « Qu'est-ce qu'OpenClaw »
    expliquant le projet upstream ([openclaw/openclaw](https://github.com/openclaw/openclaw))
    dont Nestor est une instance.
- **~18 skills Anthropic** (`upstream/anthropic-skills`) **tous symlinkés en bloc**
  par `install.sh`. Plusieurs ont une probabilité d'usage quasi nulle pour le
  profil de Cyril : `slack-gif-creator`, `algorithmic-art`, `canvas-design`,
  `theme-factory`, `brand-guidelines`, `internal-comms`. Chaque description est
  chargée dans le system prompt à *chaque* session.

### settings.json / hooks
- `bypassPermissions` + liste `deny` : raisonnable, assumé.
- `ccstatusline` invoqué via `bunx -y ccstatusline@latest` sur **3 points**
  (statusLine, hook Skill, hook UserPromptSubmit). `@latest` force une
  résolution npm à répétition → latence inutile. Devrait être **pinné** ou
  installé localement.
- Hooks `format-on-save`, `protect-env`, `notify-sound`, `rtk` : utiles, à garder.

### Documentation interne
- `README.md` **périmé** : annonce le plugin `github` (retiré au commit `d3e41f3`),
  parle de « 12 plugins officiels » / « 14 plugins ». Ne reflète plus `settings.json`.

### Poids du repo
20 Mo, dont deux submodules : `anthropic-skills` et
`awesome-claude-code-subagents` (149 fichiers `.md`, bibliothèque de référence).
Acceptable, mais la bibliothèque de 149 agents n'a de valeur que comme source de
copier-adapter — elle n'est jamais déployée.

---

## 4. Gap analysis — taxe tokens par session

Coût *fixe* injecté à chaque démarrage de session, indépendamment de la tâche :

| Source | Estimation | Maîtrisable ? |
|---|---|---|
| `CLAUDE.md` + `RTK.md` | ~7 KB | Oui — déjà dense, OK |
| Bootstrap `using-superpowers` (SessionStart hook) | ~10 KB | Partiellement |
| Index claude-mem (SessionStart) | ~10 KB | Oui — si claude-mem gardé |
| Descriptions de ~25 skills (system prompt) | ~3–5 KB | **Oui — levier principal** |
| `MEMORY.md` | ~1 KB | OK |

**Total ≈ 30–35 KB** consommés avant même la première action. Le levier le plus
propre : **curer les skills Anthropic déployés** plutôt que tout symlinker.

Angles morts (manques) :
- Pas de garde-fou côté config contre la dérive de superpowers (l'échelle
  d'effort vit dans `CLAUDE.md`, prose, non contraignante).
- Pas de skill « stack » réutilisable encodant les conventions Python/uv et
  TS/bun (aujourd'hui dispersées entre `CLAUDE.md`, `mvp`, agents).
- `install.sh` ne réconcilie pas l'état (pas de prune) → dette silencieuse.

---

## 5. Recommandations priorisées

> **Statut au 2026-05-15** : P0 exécuté et commité. Décisions du checkpoint
> intégrées ci-dessous (✅ tranché).

### P0 — Corrections (XS) — ✅ FAIT
1. `install.sh` réconcilie l'état (`prune_managed_links`) — déploiement déclaratif.
2. 14 symlinks morts purgés.
3. `README.md` synchronisé (retrait de `github`).

### P1 — Trim raisonné (S) — Lot A
4. **Agents génériques** ✅ : réécrire `api-designer` et `fullstack-developer`
   courts/FR/taillés stack (modèle `python-pro`) ; **supprimer `ui-designer`**
   (couvert par le plugin `frontend-design`).
5. **Curer les skills Anthropic déployés** ✅ : `install.sh` symlinke une
   *allowlist* explicite, pas le dossier entier. Garder : `claude-api`,
   `mcp-builder`, `skill-creator`, `webapp-testing`, `docx`, `pdf`, `pptx`,
   `xlsx`, `doc-coauthoring`. Écarter le reste (`algorithmic-art`,
   `canvas-design`, `slack-gif-creator`, `theme-factory`, `brand-guidelines`,
   `internal-comms`, `web-artifacts-builder`, et `frontend-design` upstream —
   doublon du plugin du même nom).
6. **Pinner `ccstatusline`** ✅ : version fixe, supprimer `@latest`.
7. **Supprimer le skill `notion`** ✅ (obsolète — Notion abandonné au profit de
   Docmost auto-hébergé). Le skill `docmost` est **différé** : pas d'accès API
   sans Docmost Pro pour l'instant. À reprendre quand l'accès sera disponible.

### P2 — Calibrage process — Lot B & C
8. **Plugin bootstrap custom** ✅ GO (Lot B, projet S/M, brainstorm dédié) — cf. §6.
9. **claude-mem** ✅ gardé pour l'instant (Lot C) : la **mémoire native de Claude
   Code** (« Auto Memory » : fichiers Markdown catégorisés + « Auto Dream »)
   couvre désormais l'essentiel du besoin cross-session, gratuitement. claude-mem
   coûte des appels API par observation + ~10 KB d'injection/session ; son edge
   résiduel = recherche vectorielle sur l'historique complet. → **Expérimentation**
   à planifier : désactiver claude-mem 1-2 semaines, vivre sur la mémoire native,
   comparer. Décision go/no-go ensuite.

---

## 6. Plugin custom — verdict

**Ne pas reconstruire superpowers.** Ses skills méthodologie sont bons et testés.

Un plugin custom n'a de sens que pour **un** besoin que rien ne couvre :
**posséder le bootstrap de session**. Aujourd'hui `using-superpowers` impose son
cadrage agressif ; l'échelle d'effort de Cyril ne vit que dans la prose du
`CLAUDE.md`. Un plugin custom minimal pourrait :

- Fournir un `SessionStart` qui injecte l'**échelle d'effort** comme cadre de
  routing (XS→direct, L→full superpowers) — *avant* que superpowers ne pousse au
  brainstorming systématique.
- Bundler 1–2 skills « stack » (`stack-python`, `stack-ts`) encodant les
  conventions uv/ruff/bun, réutilisables et versionnés proprement.

C'est un projet de taille **S/M**, pas une refonte.

**Décision (checkpoint 2026-05-15) : GO.** Construire ce plugin bootstrap minimal.
Il fera l'objet d'un brainstorm dédié (son propre spec → plan), car le packaging
« plugin » soulève des questions à trancher : marketplace locale vs hook simple
dans `settings.json`, structure, contenu exact des skills stack.

---

## 7. Plan de marche

| Lot | Contenu | Taille | Statut |
|-----|---------|--------|--------|
| P0 | Correctifs (install.sh, symlinks, README) | XS | ✅ Fait |
| **A** | P1 rationalisation (agents, allowlist skills, ccstatusline, suppr. `notion`) | S | Plan court → exécution |
| **B** | Réorg agents/skills — volet plugin bootstrap abandonné après challenge | S | ✅ Fait |
| **C** | Expérimentation claude-mem vs mémoire native | — | À planifier (différé) |
| (diff.) | Skill `docmost` | — | Différé (pas d'accès API) |
