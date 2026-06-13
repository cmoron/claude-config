# Audit claude-config — état de l'art & points forts / faibles

**Date** : 2026-06-13
**Périmètre** : `~/src/claude-config` (config Claude Code personnelle de Cyril)
**Précédent** : [`2026-05-15-etat-de-lart-config.md`](2026-05-15-etat-de-lart-config.md)
**Objectif** : second passage — état de l'art (Cherny, Steinberger, mattpocock/skills),
points forts/faibles, et exécution des corrections à fort ratio.

---

## 1. TL;DR

La config était déjà saine en mai (échelle d'effort, déploiement déclaratif, hooks
de feedback). Depuis, elle a évolué (agents custom **tous retirés**, ajout d'`autoship`)
mais le **README a re-dérivé**. Quatre actions exécutées dans ce passage :

1. **RTK shippé proprement** — étude faite : gain réel **67.7 %** mesuré → keep.
   `RTK.md` versionné + symlinké, hooks rendus gracieux, binaire documenté.
2. **README resynchronisé** — section agents (vide) + ref submodule VoltAgent retiré.
3. **`grill-with-docs` adopté** (remplace `grill-me`) — apporte `CONTEXT.md` + ADR.
4. **`autoship` durci** — gate staging + auto-revert au lieu de laisser prod cassé.
5. **claude-mem retiré** — étude SOTA mémoire faite : la native (v2.1.59+) couvre le
   besoin ; double injection supprimée, worker + ~848 Mo + hack `.profile` nettoyés (§4bis).

---

## 2. État de l'art (références demandées)

### Boris Cherny (créateur de Claude Code)
- **Opus + thinking pour tout** : plus rapide au final (meilleur tool-use, moins de
  steering). → aligné (`model: opus`, `effortLevel: xhigh`).
- **Parallélisme** : 5 Claudes en tabs numérotés + 5-10 sur claude.ai/code, « teleport ».
- **Permissions en allowlist** : il *évite* `--dangerously-skip-permissions`, pré-autorise
  les bash safe via `/permissions`. ← divergence : la config fait bypass + **denylist**.
- **Plan mode par défaut**, slash commands inner-loop, **hook PostToolUse de formatage** (✅).
- **« Donner à Claude un moyen de vérifier » = qualité ×2-3.** → couvert (preuve
  d'exécution + playwright/webapp-testing).
- Un seul `CLAUDE.md`/repo, enrichi plusieurs fois/semaine.

### Peter Steinberger
- **CLI-first / "close the loop"** : lint/format/test automatisés = signal immédiat (✅ hooks).
- **Codebase agent-centric** : conçu pour que l'agent navigue vite → c'est exactement ce
  que `CONTEXT.md` (cf. §3) rend concret.
- 5-10 agents en parallèle ; méta-outillage (Peekaboo, Poltergeist, **Oracle** = review
  cross-IA quand bloqué).

### mattpocock/skills
Contre-point assumé aux frameworks lourds (GSD/BMAD/Spec-Kit qui « possèdent le process et
retirent le contrôle ») : skills **petits, adaptables, composables**. Quatre modes d'échec
adressés : désalignement (`grill-*`), verbosité (langage ubiquitaire `CONTEXT.md`), code qui
ne marche pas (`tdd`/`diagnose`), ball-of-mud (`improve-codebase-architecture`).

**Valeur transférée** (cf. §3) :
| Technique | Statut | Action |
|---|---|---|
| `CONTEXT.md` + ADR (`grill-with-docs`) | ❌ absent | ✅ adopté ce passage |
| Gouvernance skills (README/buckets) | ⚠️ partiel | partiellement corrigé (README) |
| `caveman` (compression ~75 %) | ❌ | différé (win pas cher, à évaluer) |
| `improve-codebase-architecture` | ❌ | différé |
| `handoff` | ~ chevauche claude-mem | non retenu |

---

## 3. Diagnostic — ce qui a changé depuis mai

### Corrigé en mai, toujours sain
- Déploiement déclaratif (`prune_managed_links`) : `~/.claude/agents/` propre, 0 mort.
- Skills stack (`stack-python/ts/rust`) livrés. `notion` supprimé. ccstatusline pinné
  (`2.2.17`). Allowlist skills Anthropic dans `install.sh`.

### Nouvelles dérives / nouveaux objets
- **`agents/` est désormais vide** (commit `52422f5`), mais le README gardait une section
  « Agents custom » listant 2 agents inexistants + une ref au submodule VoltAgent retiré.
  → **corrigé ce passage**.
- **`@RTK.md` non versionné** : `CLAUDE.md` importe `@RTK.md`, mais le fichier n'existait
  que dans `~/.claude/RTK.md` (hors repo). Install fraîche cassée. → **corrigé** (versionné
  + symlinké + hook gracieux).
- **`autoship` ajouté** : orchestrateur fire-and-forget jusqu'au merge + déploiement. Bien
  borné (retries, abort propre, rapport) mais laissait **prod cassé sans rollback**.
  → **durci** (gate staging + auto-revert).

### Taxe tokens fixe par session — inchangée
Trois injections SessionStart cohabitent toujours : bootstrap `using-superpowers`
(~10 KB) + index claude-mem (~11 KB observé) + `MEMORY.md`. ~30-35 KB avant la première
action. L'expérimentation « couper claude-mem 1-2 semaines » (Lot C de mai) n'a pas été
faite.

---

## 4. Étude RTK (Rust Token Killer)

Proxy CLI open-source ([rtk-ai/rtk](https://github.com/rtk-ai/rtk)) qui intercepte les
commandes bash de l'agent et compresse leur sortie (strip logs/progress/boilerplate de
tests verts ; préserve erreurs + stack traces). Hook `PreToolUse` qui réécrit
`git status` → `rtk git status`, transparent.

**Gain mesuré sur la machine de Cyril** (`rtk gain`, pas du marketing) :

| Métrique | Valeur |
|---|---|
| Commandes proxifiées | 6 884 |
| Tokens économisés | **1.8M (67.7 %)** |
| Overhead | 442 ms moyen (gonflé par `git fetch` réseau ; local 0-60 ms) |
| Top impact | `rtk read` (832K), curl gros fetch (99.9 %), `grep` (148K), `git commit` (80.6 %) |

**Verdict : keep.** Gain réel et substantiel, overhead local négligeable. C'est le
« close the loop sans noyer le contexte » de Cherny/Steinberger, chiffré.

**Shipping** (dépendance binaire → même traitement que `rg`/`fd`/`bun`/`jq`) :
- `RTK.md` versionné dans le repo + symlinké par `install.sh` (répare la repro).
- Binaire documenté dans `README.md` § Prérequis (cargo/brew) — **pas auto-installé**
  (cohérent avec les autres deps).
- Hooks rendus gracieux : `command -v rtk >/dev/null && rtk hook claude || true` — sur
  machine sans rtk, le hook ne pollue pas chaque Bash. Idem appliqué aux hooks `atuin`.

---

## 4bis. Étude mémoire cross-session & décision claude-mem

**Constat** : deux systèmes tournaient en parallèle —
- **Mémoire native** Claude Code (v2.1.177 ≥ 2.1.59, activée par défaut) : `MEMORY.md`
  (≤200 l / 25 KB) + fichiers thématiques on-demand, project-scoped.
- **claude-mem** (worker Bun sur `127.0.0.1:37777`, ~848 Mo) : index injecté ~17 K
  tokens/session (mesuré) + compression ~16,5 K tokens/session (haiku).
→ Double injection SessionStart (~42 K tokens) pour un besoin largement recouvrant.

| Système | Edge | Limite |
|---|---|---|
| Native Auto Memory | Zéro-config, gratuit, project-scoped | Pas de recherche vectorielle |
| claude-mem | FTS5 + ChromaDB sur l'historique | Worker Bun, coût tokens, caveats Chroma (fuite sous-process, port 37777 sans auth) |
| mem0 / OpenMemory | Multi-plateforme, 91,6 % LoCoMo | Cloud (clé API) |
| MCP basic-memory | Léger | Pas de persistance cross-session |

claude-mem a été conçu **avant** que Claude Code ait une mémoire native ; depuis la
v2.1.59 la native couvre ~80-90 % du besoin, gratuitement et sans intégration. L'edge
résiduel (vector search sur l'historique) est déjà couvert par `mgrep`.

**Décision : suppression.** Plugin désinstallé, marketplace retirée, worker arrêté, ~848 Mo
purgés, bloc de pré-démarrage retiré de `dotfiles/.profile`, références nettoyées (settings,
CLAUDE.md, README, autoship, bootstrap-plugins). Mémoire cross-session = native + `mgrep`
pour le sémantique.

## 5. Points forts / points faibles (synthèse)

### Forts
1. Déploiement déclaratif idempotent (niveau Cherny/Steinberger).
2. **Échelle d'effort XS/S/M/L+** — rare, contre le biais sur-process.
3. Frugalité de contexte assumée (allowlist, pin, fallbacks outils).
4. Feedback loops câblées (format-on-save, protect-env, preuve d'exécution).
5. Stacks encodées en skills réutilisables.
6. Discipline méta : `docs/audits/` daté + `docs/superpowers/specs/`.
7. `autoship` bien borné (et désormais avec rollback).

### Faibles (statut après ce passage)
| # | Faiblesse | Sévérité | Statut |
|---|---|---|---|
| 1 | `@RTK.md` non versionné (repo non reproductible) | 🔴 M-H | ✅ corrigé |
| 2 | README périmé (agents vides, submodule retiré) | 🟠 M | ✅ corrigé |
| 3 | Double mémoire active (claude-mem + native), taxe fixe | 🟠 M | ✅ corrigé (claude-mem retiré, §4bis) |
| 4 | `autoship` : prod cassé sans rollback | 🟠 M | ✅ corrigé (revert + gate staging) |
| 5 | Sécurité = denylist (incomplète par nature) vs allowlist Cherny | 🟡 L-M | assumé (trade-off documenté) |
| 6 | Tension `using-superpowers` (agressif) vs échelle d'effort | 🟡 L | assumé (priorité d'instruction tranche) |
| 7 | Pas de `CONTEXT.md`/ubiquitous-language | gap | ✅ comblé (`grill-with-docs`) |

---

## 6. Actions exécutées (2026-06-13)

1. `RTK.md` créé + versionné ; `install.sh` symlinke `RTK.md` ; `settings.json` : hooks
   `rtk`/`atuin` gardés par `command -v` ; `README.md` : prérequis rtk.
2. `README.md` : section Agents réécrite (vide → délégué aux plugins) ; liste skills
   (grill-me → grill-with-docs).
3. Skill `grill-with-docs` (SKILL + CONTEXT-FORMAT + ADR-FORMAT), FR ; `grill-me` supprimé.
4. `autoship` : `references/ship.md` (gate staging §3 + auto-revert §4) + `SKILL.md`
   (Phase 5bis + garde-fous).
5. **claude-mem retiré** : `settings.json` (enabledPlugins + marketplace), `CLAUDE.md`
   (tools + mémoire), `README.md`, `skills/claude-config`, `skills/autoship`,
   `scripts/bootstrap-plugins.sh` ; côté système : plugin désinstallé, marketplace retirée,
   worker arrêté, ~848 Mo purgés, bloc retiré de `dotfiles/.profile` (repo séparé).

## 7. Décisions prises (2026-06-13)

- **claude-mem** : retiré (cf. §4bis).
- **Permissions** : on reste en **denylist** (trade-off assumé).
- **`caveman`** : écarté — trop abrupt pour la fluidité quotidienne.
- **`improve-codebase-architecture`** : écarté pour l'instant — coût jugé trop élevé.
