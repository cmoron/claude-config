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

## Pendant que tu codes

- Le minimum qui résout le problème. Pas d'abstraction "au cas où", pas de config "pour plus tard", pas de gestion d'erreur pour des cas qui ne peuvent pas arriver.
- Pas de `catch` silencieux. Pas de `unwrap` hors tests. Une erreur remonte ou est traitée — jamais avalée.
- Édition chirurgicale : ne touche pas au code voisin qui n'a rien à voir. Si tu vois du dead code orphelin non lié, signale-le — ne le supprime pas.
- Tests **avec** le code, pas après. Pour un bug : écris d'abord un test qui le reproduit, puis fix.
- Le formatage passe par hooks (ruff/rustfmt/prettier) — ne relance pas manuellement.

## Avant de dire "c'est fait"

Preuve d'exécution obligatoire : tests qui passent, app qui démarre, endpoint qui répond. "Ça devrait marcher" n'existe pas. Si tu ne peux pas vérifier toi-même (UI, déploiement…), dis-le explicitement — ne prétends pas.

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
| Recherche contenu sémantique | `mgrep "query"` | `rg`, puis built-in Grep |
| Recherche regex/littérale | `rg` | built-in Grep |
| Recherche structure (multi-lignes) | `ast-grep` / `sg` | rien d'équivalent |
| Recherche fichiers | `fd` | built-in Glob |
| Explorer fichier inconnu >200 lignes | `claude-mem:smart-explore` | `Read` direct |
| Web | `mgrep --web --answer` | WebSearch (préviens-moi) |
| Doc de lib (React, FastAPI…) | plugin `context7` | WebSearch ciblée |
| Extraction JSON/YAML | `jq` / `yq` | jamais `cat` un gros fichier structuré |

Le pattern général : préférence forte, mais si elle échoue, dis-le et bascule sur le fallback — ne te bloque pas.

## Contexte (fenêtre 1M)

- `/clear` entre deux tâches sans lien.
- `/compact Keep: <ce qui compte>` quand tu sens des oublis.
- Gros périmètre à explorer → sous-agent `Explore` → résumé dans le contexte principal.
- Ne `@`-mentionne pas un gros fichier sans raison — donne chemin + ce que tu cherches.
- Mémoire cross-session : `claude-mem` (auto via MEMORY.md).

---

Ces règles fonctionnent si : tu poses des questions avant de coder plutôt qu'après mes corrections, tes diffs ne touchent que ce qui doit l'être, tu vérifies avant de dire "fait", et tu ne lances jamais de `superpowers:subagent-driven-development` sans m'avoir chiffré le coût.

@RTK.md
