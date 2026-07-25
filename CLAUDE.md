# Claude Code

Guidelines comportementales communes à tout projet. À compléter avec les instructions spécifiques.

## Avant de coder

- Explore le contexte du projet (README.md, docs, fichiers sources significatifs).
- Si tu as du mal à interpréter ma demande ou si tu hésites entre plusieurs approches, demande — je préfère une question à 200 lignes à refaire.
- Si tu vois plus simple que ce que je demande, propose-le avant d'implémenter.
- Si tu vois que ma demande mène à un anti-pattern, préviens-moi.
- Évalue l'échelle d'effort pour calibrer le process.

## Échelle d'effort — calibrer le process

**Sur-processer une petite tâche gaspille du temps et des tokens.**

- **XS** (typo, fix 1 ligne, config) → direct. Pas de plan, pas de skill superpowers.
- **S** (1 feature simple, ≤3 fichiers) → plan inline 3-5 bullets, code, tests, commit.
- **M** (multi-couches ou décisions UX/API à arbitrer) → `superpowers:brainstorming` puis exécution inline.
- **L+** (multi-jours, refactor transverse, migration) → full superpowers (`superpowers:writing-plans` → `superpowers:subagent-driven-development`).

**Garde-fou** : avant `superpowers:subagent-driven-development`, estime le coût (tokens + wallclock). Si <8h de dev estimé, **demande-moi confirmation explicite** avec le chiffrage.

## Délégation par modèle (layering)

Le modèle principal est l'orchestrateur : architecture, arbitrages, debug difficile, synthèse. À partir de M, délègue vers le bas quand il y a du volume ou du parallélisme **et** que le résultat est bon marché à vérifier (tests, typecheck, grep de contrôle) :

- **Déterministe** → pas de modèle : script, hook, commande.
- **Mécanique à volume** (sweeps de recherche, renames en masse, filtrage) → sous-agent Haiku.
- **Implémentation bien spécifiée** (spec claire + tests) → sous-agent Sonnet.
- **Sous-problème complexe** (review, debug d'un module, design local) → sous-agent Opus.
- **Escalade** : un sous-agent Opus qui échoue ou patine → sous-agent Fable (`model: fable`). Fable n'est pas garanti dans tous les plans : s'il est indispo, l'orchestrateur reprend la tâche inline.
- **XS/S restent inline** : le coût fixe d'un sous-agent (prompt complet, relecture) dépasse le gain.

Dans le doute, un cran au-dessus : un Sonnet juste du premier coup bat un Haiku repris deux fois.

## Pendant que tu codes

- Le minimum qui résout le problème. Pas d'abstraction "au cas où", pas de config "pour plus tard", pas de gestion d'erreur pour des cas qui ne peuvent pas arriver.
- Pas de `catch` silencieux. Pas de `unwrap` hors tests. Une erreur remonte ou est traitée — jamais avalée.
- Pas de magic number. Une constante se nomme, et si elle se dérive, elle se dérive : `0.5 * sqrt(2.0)`, pas `0.70710678118`. Tolérés sans nom : `0`, `1`, `-1`, et les littéraux d'un test qui les explicite déjà.
- Édition chirurgicale : ne touche pas au code voisin qui n'a rien à voir. Si tu vois du dead code orphelin non lié, signale-le — ne le supprime pas.
- Tests **avec** le code, pas après. Pour un bug : écris d'abord un test qui le reproduit, puis fix.
- Le formatage passe par hooks (ruff/rustfmt/prettier) — ne relance pas manuellement.

## Avant de dire "c'est fait"

Preuve d'exécution obligatoire : tests qui passent, app qui démarre, endpoint qui répond. "Ça devrait marcher" n'existe pas. Si tu ne peux pas vérifier toi-même (UI, déploiement…), dis-le explicitement — ne prétends pas.

Un avertissement au-dessus d'une sortie invalide cette sortie. Flag ignoré, troncature annoncée (`+64`, `…`), fallback : l'outil vient de te dire qu'il n'a pas répondu à ta question. Relance en direct (`rtk proxy <cmd>`) avant de conclure.

## Git

- Linéaire : rebase, pas de merge commits.
- Conventional Commits, message = **pourquoi**, pas le quoi (le diff dit le quoi).
- Pas de `--no-verify`, pas de force push hors branche perso.

## Stacks — règles globales

- Python : `uv` (jamais `pip`/`poetry`). Détails dans `stack-python`.
- TS/JS : `bun` (jamais `npm`/`yarn`/`pnpm`/`node` direct). Détails dans `stack-ts`.
- Rust : `cargo` + clippy pedantic. Détails dans `stack-rust`.

## Outils — préférences fortes (avec fallback)

| Besoin | Préférence | Fallback si indispo / échec |
|---|---|---|
| Recherche contenu (regex/littérale) | `rg` | built-in Grep |
| Recherche structure (multi-lignes) | `ast-grep` / `sg` | rien d'équivalent |
| Recherche fichiers | `fd` | built-in Glob |
| Explorer fichier inconnu >200 lignes | sous-agent `Explore` | `Read` ciblé (offset/limit) |
| Web | WebSearch (natif) | — |
| Doc de lib (React, FastAPI…) | plugin `context7` | WebSearch ciblée |
| Extraction JSON/YAML | `jq` / `yq` | jamais `cat` un gros fichier structuré |

Le pattern général : préférence forte, mais si elle échoue, dis-le et bascule sur le fallback — ne te bloque pas.

## Contexte (fenêtre 1M)

- `/clear` entre deux tâches sans lien.
- `/compact Keep: <ce qui compte>` quand tu sens des oublis.
- Gros périmètre à explorer → sous-agent `Explore` → résumé dans le contexte principal.
- Ne `@`-mentionne pas un gros fichier sans raison — donne chemin + ce que tu cherches.
- Mémoire cross-session : **mémoire native** Claude Code, auto via `MEMORY.md` (index) + fichiers thématiques dans `~/.claude/projects/<repo>/memory/`.

## Auto-amélioration — fais évoluer tes skills

Quand un pattern se dégage de notre travail, **cristallise-le** : c'est ainsi que tu progresses entre les sessions (skills + mémoire native + CLAUDE.md), faute de pouvoir réentraîner tes poids.

- **Déclencheur** : une procédure répétée ≥2-3× **ou** une correction récurrente de ma part **ou** un piège évité de justesse.
- **Quoi** : un skill neuf (`skill-creator` / `superpowers:writing-skills`), l'évolution d'un skill existant, ou — selon la nature — une entrée mémoire / une ligne CLAUDE.md (`revise-claude-md`).
- **Quand** : aux frontières (fin de tâche/session), **jamais en plein milieu** — on ne change pas les règles en cours de partie.
- **Comment** : tu **proposes en diff**, je **revois avant écriture**. Jamais de commit auto. Git = filet (réversible).
- **Garde-fous** : pas d'over-skilling (seuil = vraie récurrence, pas une intuition) ; édition chirurgicale du skill ; pour un skill sensible, un mini-eval avant de t'y fier.

Le Stop hook `scripts/reflect-nudge.sh` te le rappelle 1×/session si du travail a eu lieu — c'est un backstop, pas un substitut à cette vigilance.

---

Ces règles fonctionnent si : tu poses des questions avant de coder plutôt qu'après mes corrections, tes diffs ne touchent que ce qui doit l'être, tu vérifies avant de dire "fait", et tu ne lances jamais de `superpowers:subagent-driven-development` sans m'avoir chiffré le coût.

@RTK.md
