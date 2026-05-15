# Spec — Plugin bootstrap (Lot B)

**Date** : 2026-05-15
**Lot** : B (cf. `docs/audits/2026-05-15-etat-de-lart-config.md` §5.8, §6, §7)
**Taille** : S/M
**Statut** : design validé — prêt pour plan d'implémentation

---

## 1. Objectif

Posséder le bootstrap de session et clarifier la frontière agents/skills.

Deux besoins, un seul livrable :

1. **Bootstrap de session** — injecter l'échelle d'effort comme cadre de routing
   actif au démarrage, pour que le calibrage du process (XS→direct, L→full
   superpowers) ne dépende plus uniquement de la prose du `CLAUDE.md`.
2. **Frontière agents/skills** — appliquer le principe **« les skills portent les
   compétences, les agents définissent les métiers »**. Aujourd'hui les
   conventions de stack sont piégées dans des agents (`python-pro`, `rust-pro`),
   donc inaccessibles pour le travail inline XS/S — précisément le cas le plus
   fréquent selon l'échelle d'effort.

## 2. Principe directeur

- **Agent = métier** : une fenêtre de contexte isolée à qui l'on délègue une
  tâche entière (architecte, développeur). Coûteux — réservé au travail lourd.
- **Skill = compétence** : un bloc d'expertise chargé à la demande dans le
  contexte courant. Utilisable par le thread principal *et* par n'importe quel
  subagent.

Une spécialisation de langage (Python, Rust) ou une technique (design d'API)
est une **compétence**, pas un métier → c'est un skill.

## 3. Architecture du livrable

Un plugin Claude Code local, distribué via une marketplace locale.

```
plugins/
├── .claude-plugin/
│   └── marketplace.json          marketplace "cyril-local" — liste le plugin bootstrap
└── bootstrap/
    ├── .claude-plugin/
    │   └── plugin.json           name: bootstrap, version: 0.1.0
    ├── hooks/
    │   ├── hooks.json            SessionStart (startup|clear|compact) → session-bootstrap
    │   └── session-bootstrap     script exécutable : émet effort-scale.md
    ├── effort-scale.md           table de routing XS/S/M/L/XL condensée — SOURCE UNIQUE
    └── skills/
        ├── stack-python/SKILL.md
        ├── stack-ts/SKILL.md
        ├── stack-rust/SKILL.md
        └── api-design/SKILL.md
```

Le plugin porte deux responsabilités : **(1)** le bootstrap de session (hook),
**(2)** les skills compétences versionnés proprement.

## 4. Le hook SessionStart

- `effort-scale.md` contient la table de routing condensée (signaux → process
  pour XS/S/M/L/XL, ~1–1,5 KB). C'est la **source unique** de la table.
- Le script `session-bootstrap` émet le contenu d'`effort-scale.md` au démarrage
  (matcher `startup|clear|compact`), comme cadre actif de routing.
- **Conséquence sur `CLAUDE.md`** : la section « Échelle d'effort » du `CLAUDE.md`
  ne doit plus dupliquer la table. Elle garde la prose non duplicable — règle
  d'or, anti-patterns, paragraphe « signal de stack vient d'une feature lourde »
  — et pointe vers le plugin pour la table. Pas de double-maintenance.
- L'ordre d'exécution entre ce hook et celui de superpowers n'est pas garanti et
  n'a pas besoin de l'être : la priorité d'instruction (`CLAUDE.md` >
  superpowers) reste le garde-fou ; le hook ne fait que rendre la table présente
  et active dès le démarrage.

## 5. Les skills compétences

Chaque skill : court (~30–40 lignes), en français, modèle de l'agent
`python-pro` actuel — priorités ordonnées + règles absolues.

| Skill | Source du contenu | Contenu | Description (trigger) |
|---|---|---|---|
| `stack-python` | corps de `python-pro` + `CLAUDE.md` | uv (deps/venv), ruff (lint+format), mypy strict, pytest, `typer`+`rich` pour CLI, `async` sur tout I/O, Pydantic v2, exceptions typées hiérarchisées | édition de `.py`, `pyproject.toml`, question Python avancée |
| `stack-ts` | `CLAUDE.md` (net nouveau) | `bun` uniquement (runtime, package manager, bundler, test runner) — jamais npm/pnpm/yarn/node ; conventions TS | édition de `.ts`/`.tsx`, `package.json`, question TypeScript |
| `stack-rust` | corps de `rust-pro` | édition 2021, satisfaction du borrow checker, idiomes (itérateurs, `?`, `From`/`Into`), `clippy::pedantic`, `thiserror`/`anyhow`, jamais d'`unwrap`/`expect` hors tests | édition de `.rs`, `Cargo.toml`, question Rust |
| `api-design` | corps de `api-designer` | contrat d'abord (OpenAPI), REST (ressources plurielles, verbes HTTP sémantiques), codes statut précis, format d'erreur unique, pagination par curseur, schémas Pydantic distincts de l'ORM, GraphQL seulement si justifié | concevoir ou refactorer une API REST/GraphQL |

## 6. Migration des agents

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
   compétences, agents = métiers ».
5. **`README.md`** et l'audit — synchroniser ; le Lot B clôt le point §5.8 de
   l'audit (passer le Lot B à ✅ dans le plan de marche §7).

Bilan tokens : −3 descriptions d'agent au routing, +4 descriptions de skill au
system prompt → ≈ neutre. Gain réel : le savoir de stack devient accessible en
inline (XS/S) là où il était piégé derrière un agent qu'on s'interdit de
dispatcher.

## 7. Déploiement

1. **`scripts/bootstrap-plugins.sh`** — ajouter l'enregistrement de la
   marketplace locale : `claude plugin marketplace add "$CONFIG_DIR/plugins"`,
   avant la boucle d'installation des plugins.
2. **`settings.json`** — `enabledPlugins` reçoit `"bootstrap@cyril-local": true`.
   Pour `extraKnownMarketplaces` : la source est un répertoire local ; le format
   exact est **à vérifier à l'implémentation**. Si `claude plugin marketplace
   add <path>` suffit à lui seul à rendre la marketplace persistante, ne rien
   ajouter à `extraKnownMarketplaces`.
3. **`install.sh`** — *aucun changement*. Les skills du plugin sont chargés par
   le système de plugins de Claude Code, pas symlinkés. C'est l'intérêt du
   packaging en plugin : versionnement propre, pas de dette de symlink.
4. **Hook** — enregistré via `plugins/bootstrap/hooks/hooks.json`, pas dans
   `settings.json`.

## 8. Vérification (avant de déclarer le lot fini)

- Redémarrer Claude Code → `/plugin` liste `bootstrap@cyril-local`.
- Les 4 skills `stack-python`, `stack-ts`, `stack-rust`, `api-design`
  apparaissent dans la liste des skills disponibles d'une nouvelle session.
- Une nouvelle session injecte bien le contenu d'`effort-scale.md` au démarrage.
- `~/.claude/agents/` ne contient plus `python-pro`, `rust-pro`, `api-designer`
  après `install.sh`.
- `fullstack-developer` ne référence plus `api-designer`.

## 9. Hors périmètre (YAGNI)

- Pas de skill `stack-go`, `stack-java`, etc. — créés à l'apparition d'un besoin
  réel.
- Pas de contre-cadrage explicite de superpowers dans le hook — la priorité
  d'instruction suffit ; on n'injecte que la table.
- Lot C (expérimentation claude-mem) et skill `docmost` restent différés.
