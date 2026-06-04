# Autoship — production autonome de features/fix

**Date :** 2026-06-04
**Statut :** design validé, à implémenter

## Problème

Pour les **petites features et fix à faible risque de régression**, je veux pouvoir
lancer Claude Code en autonomie totale et sortir de la boucle. Aucun outil built-in ne
couvre toute la chaîne (map → plan → build → review → doc → ship) d'un bout à l'autre.
Toutes les briques existent déjà dans ma config ; il manque un **orchestrateur** qui les
enchaîne sans intervention humaine.

Le périmètre — « petite feature / fix à faible risque » — est jugé **par moi au moment
du lancement**. La commande n'arbitre pas elle-même si le risque est faible : pas de
garde-fou « est-ce trop gros ? » qui contredirait le fire-and-forget.

## Décisions structurantes

| Décision | Choix |
|---|---|
| Modèle d'autonomie | **Fire-and-forget total** — jusqu'au déploiement prod, sans gate humain |
| Blocage dur (build, CI PR…) | **Retries bornés → stop propre + rapport**, état laissé sûr (branche/PR draft non mergée) |
| Découverte des conventions projet | **CLAUDE.md projet + auto-détection** (manifestes, workflows) |
| Forme du livrable | **Skill `autoship` + commande mince `/autoship`** ; build loop en sous-agents |
| Échec **après** merge sur main | **Boucle d'auto-correction post-merge** (fix-forward, bornée) |
| Fallback si l'auto-correction post-merge épuise ses retries | **Stop + rapport**, main/prod laissé en l'état (intervention manuelle) |

## Architecture

```
skills/autoship/
  SKILL.md            # orchestrateur : séquence des phases, gates, règles d'abort, découverte projet
  references/
    ship.md           # chorégraphie git/PR/CI/deploy détaillée (phase la plus touffue)
commands/autoship.md  # déclencheur mince → invoque le skill autoship avec $ARGUMENTS
```

**Parti-pris :** un seul fichier de référence (`ship.md`). Les phases map/plan/build/
review/doc **délèguent aux briques existantes** plutôt que de réécrire leur logique :

- map → `Explore` / `claude-mem:smart-explore`
- plan → `superpowers:writing-plans`
- build → `superpowers:subagent-driven-development` + `superpowers:test-driven-development`
- review → `/code-review` + `/simplify`
- ship → skill `deployment` (`gh run watch`, healthcheck) + logique `/commit`

Seule la phase **ship** mérite un fichier dédié : sa chorégraphie n'est couverte nulle
part en un seul endroit.

## Pipeline

`/autoship <description de la feature/fix>` enchaîne sans jamais s'arrêter pour un go :

### 0. Préflight (découverte + setup)
- Résout les conventions dans l'ordre : `CLAUDE.md` projet → skills `stack-*` /
  `deployment` → manifestes (`pyproject` / `package.json` / `Cargo.toml`) →
  `.github/workflows`.
- Établit : commandes test / lint / build, workflow CI, cible de déploiement.
- Vérifie l'état git, crée la branche de travail.
- **Abort si** la commande de test reste introuvable → rapport, rien n'a été touché.

### 1. Map
- Comprend le code pertinent via `Explore` / `smart-explore`.
- Sortie : compréhension ciblée en contexte (pas un dump de fichiers).

### 2. Plan
- Architecture de la solution via `writing-plans`, calibrée « petite feature/fix ».
- Pas de gate humain (fire-and-forget).

### 3. Build loop (sous-agents)
- `subagent-driven-development` + TDD : par tâche → test d'abord, implémentation,
  lint (via hooks), tests verts.
- **Retries bornés (défaut 3)** par tâche.
- Qualité : `/code-review` + `/simplify` appliqués.
- Phase validée **uniquement** si build vert + tests verts.

### 4. Doc
- Met à jour doc / README / changelog **au prorata du changement**. Minimal.

### 5. Ship (cf. `references/ship.md`)
- Commit conventionnel (logique `/commit`) → push → `gh pr create`.
- `gh run watch` sur la PR :
  - CI rouge → retries bornés de fix ; toujours rouge → **abort : PR laissée ouverte
    (draft) + rapport**, pas de merge.
  - CI verte → **merge squash + rebase** (historique linéaire, 1 commit sur main).
- `gh run watch` sur main → surveillance déploiement staging/prod (healthcheck, skill
  `deployment`).

### 5bis. Auto-correction post-merge
- Déclenchée si, **après le merge**, le CI sur main est rouge **ou** le healthcheck
  deploy est KO.
- Fix-forward : diagnostic → fix sur une branche → PR → `gh run watch` → merge
  squash/rebase → re-surveille main + deploy.
- **Bornée (défaut 3 itérations).**
- **Fallback final** (retries épuisés, main/prod toujours cassé) : **stop + rapport**,
  main/prod laissé en l'état pour intervention manuelle. Pas de rollback auto.

## Garde-fous transverses

- Retries **bornés** (défaut 3) par phase/boucle ; jamais de boucle infinie.
- Règles git absolues respectées : pas de `--no-verify`, pas de force push, rebase/squash
  (linéaire), Conventional Commits.
- Sur abort : état laissé **sûr et explicite** (branche poussée / PR draft / point
  d'arrêt nommé) — sauf le cas post-merge cassé acté ci-dessus.

## Rapport & notification

- **Rapport final systématique** (succès comme échec) : ce qui a été fait, où ça s'est
  arrêté, pourquoi, action manuelle requise s'il y a lieu.
- **Notification push en fin de run** (succès / blocage) pour ne pas avoir à surveiller.
  Dégrade en simple message final si aucun canal push n'est configuré (optionnel).

## Hors périmètre (YAGNI)

- Pas de jugement automatique « cette tâche est-elle trop grosse / risquée ? ».
- Pas de rollback automatique (l'auto-correction post-merge est le filet ; au-delà,
  intervention manuelle).
- Pas de control-flow scripté headless (`claude -p`) : on s'appuie sur le harness et les
  sous-agents.
