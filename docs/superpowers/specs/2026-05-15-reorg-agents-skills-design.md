# Spec — Réorganisation agents/skills (Lot B)

**Date** : 2026-05-15 (révisé après challenge)
**Lot** : B (cf. `docs/audits/2026-05-15-etat-de-lart-config.md` §5.8, §6, §7)
**Taille** : S
**Statut** : design validé — prêt pour plan d'implémentation

---

## 0. Note de révision

La version initiale de ce spec proposait un **plugin bootstrap** avec un hook
`SessionStart` injectant l'échelle d'effort. Ce volet a été **abandonné** après
challenge :

- L'échelle d'effort est déjà dans le `CLAUDE.md`, injecté à chaque session. Un
  hook qui la recopie n'ajoute rien de mécaniquement vérifiable.
- Le hook ne résout pas le conflit qu'il visait (`using-superpowers` agressif) —
  ce que tranche le conflit, c'est la priorité d'instruction, qui existe déjà.
- L'ordre d'exécution entre hooks de plugins n'est pas garanti — le seul
  argument mécanique tombe.
- État de l'art : le bootstrap par hook est utilisé par les **auteurs de
  plugins** faute d'accès au `CLAUDE.md`. Pour une config personnelle, l'état de
  l'art *est* le `CLAUDE.md`.

Ne subsiste que ce qui a une vraie valeur : la **réorganisation agents/skills**.
Elle ne nécessite ni plugin ni hook.

## 1. Objectif

Appliquer le principe **« les skills portent les compétences, les agents
définissent les métiers »**.

Défaut corrigé : les conventions de stack (Python, Rust) sont aujourd'hui
piégées dans des agents (`python-pro`, `rust-pro`). Or l'échelle d'effort du
`CLAUDE.md` interdit de dispatcher un subagent pour du travail XS/S — précisément
le cas le plus fréquent. Résultat : ce savoir n'est jamais chargé en inline.

## 2. Principe directeur

- **Agent = métier** : une fenêtre de contexte isolée à qui l'on délègue une
  tâche entière (architecte, développeur). Coûteux — réservé au travail lourd.
- **Skill = compétence** : un bloc d'expertise chargé à la demande dans le
  contexte courant. Utilisable par le thread principal *et* par tout subagent.

Une spécialisation de langage (Python, Rust) ou une technique (design d'API) est
une **compétence**, pas un métier → c'est un skill.

## 3. Les skills compétences (nouveaux)

Quatre skills custom ajoutés dans `skills/`, déployés par symlink via
`install.sh` comme les 7 skills custom existants. Pas de plugin.

Chaque skill : court (~30–40 lignes), en français, modèle de l'agent
`python-pro` actuel — priorités ordonnées + règles absolues.

| Skill | Source du contenu | Contenu | Description (trigger) |
|---|---|---|---|
| `stack-python` | corps de `python-pro` + `CLAUDE.md` | uv (deps/venv), ruff (lint+format), mypy strict, pytest, `typer`+`rich` pour CLI, `async` sur tout I/O, Pydantic v2, exceptions typées hiérarchisées | édition de `.py`, `pyproject.toml`, question Python avancée |
| `stack-ts` | `CLAUDE.md` (net nouveau) | `bun` uniquement (runtime, package manager, bundler, test runner) — jamais npm/pnpm/yarn/node ; conventions TS | édition de `.ts`/`.tsx`, `package.json`, question TypeScript |
| `stack-rust` | corps de `rust-pro` | édition 2021, satisfaction du borrow checker, idiomes (itérateurs, `?`, `From`/`Into`), `clippy::pedantic`, `thiserror`/`anyhow`, jamais d'`unwrap`/`expect` hors tests | édition de `.rs`, `Cargo.toml`, question Rust |
| `api-design` | corps de `api-designer` | contrat d'abord (OpenAPI), REST (ressources plurielles, verbes HTTP sémantiques), codes statut précis, format d'erreur unique, pagination par curseur, schémas Pydantic distincts de l'ORM, GraphQL seulement si justifié | concevoir ou refactorer une API REST/GraphQL |

## 4. Migration des agents

État cible : **2 agents** (métiers), **4 skills** ajoutés (compétences).

1. **Supprimer** `agents/python-pro.md`, `agents/rust-pro.md`,
   `agents/api-designer.md`. Leurs symlinks dans `~/.claude/agents/` sont purgés
   automatiquement par `prune_managed_links` de `install.sh` (acquis du Lot P0).
2. **`fullstack-developer`** — recâbler : retirer du corps les conventions
   outillage redites (« `uv` côté Python, `bun` côté TS », règles `async`) ;
   les remplacer par « charger `stack-python`/`stack-ts` selon la couche ».
   Mettre à jour la dernière ligne `« pour le design d'API détaillé, à
   api-designer »` → `« charger le skill api-design »`.
3. **`software-architect`** — aucun changement (ne référence aucun agent
   supprimé ; vérifié 2026-05-15).
4. **`CLAUDE.md`** — section « Agents custom » réduite à `software-architect` et
   `fullstack-developer` ; ajouter une phrase énonçant le principe « skills =
   compétences, agents = métiers ». La section « Échelle d'effort » reste
   **intacte** (pas de fragmentation — le volet hook est abandonné).
5. **`README.md`** et l'audit — synchroniser ; le Lot B clôt le point §5.8 de
   l'audit (passer le Lot B à ✅ dans le plan de marche §7, en notant que le
   volet plugin a été abandonné).

Bilan tokens : −3 descriptions d'agent au routing, +4 descriptions de skill au
system prompt → ≈ neutre. Gain réel : le savoir de stack devient accessible en
inline (XS/S) là où il était piégé derrière un agent qu'on s'interdit de
dispatcher.

## 5. Déploiement

- Les 4 skills vont dans `skills/<nom>/SKILL.md`.
- `install.sh` les symlinke automatiquement vers `~/.claude/skills/` (mécanisme
  existant pour les skills custom — aucun changement de script nécessaire).
- Aucune modification de `settings.json`, `bootstrap-plugins.sh`, ni de
  marketplace.

## 6. Vérification (avant de déclarer le lot fini)

- `bash install.sh` puis : `~/.claude/skills/` contient `stack-python`,
  `stack-ts`, `stack-rust`, `api-design`.
- `~/.claude/agents/` ne contient plus `python-pro`, `rust-pro`, `api-designer`.
- `fullstack-developer` ne référence plus `api-designer`.
- Une nouvelle session liste les 4 nouveaux skills comme disponibles.

## 7. Hors périmètre (YAGNI)

- **Plugin bootstrap et hook `SessionStart`** — abandonnés (cf. §0).
- Pas de skill `stack-go`, `stack-java`, etc. — créés à l'apparition d'un besoin
  réel.
- Lot C (expérimentation claude-mem) et skill `docmost` restent différés.
