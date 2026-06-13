---
name: grill-with-docs
description: Interview contradictoire qui challenge un plan/design contre le langage du projet (glossaire CONTEXT.md) et les décisions documentées (ADR), et met à jour ces docs au fil de l'eau. Utiliser pour stress-tester un plan, se faire challenger sur un design, aligner le vocabulaire, ou quand l'utilisateur mentionne "grill me" / "grill with docs".
---

# Grill with docs

Interview-moi sans relâche sur chaque aspect de ce plan jusqu'à une compréhension
partagée. Parcours chaque branche de l'arbre de décision, en résolvant les
dépendances entre décisions une par une. Pour chaque question, donne ta réponse
recommandée.

**Pose les questions une à la fois**, en attendant le retour sur chacune avant de
continuer.

Si une question peut trouver sa réponse en explorant le codebase, **explore le
codebase** au lieu de demander.

## Conscience du domaine

Pendant l'exploration du code, repère aussi la documentation existante :

```
/
├── CONTEXT.md            ← glossaire du langage ubiquitaire
├── docs/
│   └── adr/              ← décisions d'architecture (0001-slug.md, 0002-…)
└── src/
```

Repo multi-contextes : un `CONTEXT-MAP.md` à la racine pointe vers chaque
contexte (cf. `CONTEXT-FORMAT.md`).

**Création paresseuse** : ne crée `CONTEXT.md` que quand le premier terme est
résolu, `docs/adr/` que quand le premier ADR est nécessaire. Pas de fichier vide.

## Pendant la session

- **Challenge contre le glossaire.** Si l'utilisateur emploie un terme qui entre en
  conflit avec `CONTEXT.md`, signale-le aussitôt. « Ton glossaire définit
  "annulation" comme X, mais tu sembles parler de Y — lequel ? »
- **Affûte le vocabulaire flou.** Sur un terme vague ou surchargé, propose un terme
  canonique précis. « Tu dis "compte" — tu parles du Client ou de l'Utilisateur ?
  Ce sont deux choses différentes. »
- **Discute des scénarios concrets.** Stress-teste les relations du domaine avec des
  scénarios spécifiques qui sondent les cas limites et forcent à être précis sur les
  frontières entre concepts.
- **Croise avec le code.** Quand l'utilisateur affirme comment quelque chose marche,
  vérifie que le code est d'accord. Si tu trouves une contradiction, remonte-la.

## Mettre à jour CONTEXT.md au fil de l'eau

Quand un terme est résolu, mets à jour `CONTEXT.md` **tout de suite** — ne batche
pas. Format : voir [CONTEXT-FORMAT.md](CONTEXT-FORMAT.md).

`CONTEXT.md` est **uniquement un glossaire** : aucun détail d'implémentation, pas
une spec, pas un bloc-notes. Ce qu'un terme **est**, pas ce qu'il **fait**.

## Proposer des ADR avec parcimonie

Ne propose un ADR que si les **trois** sont vrais :

1. **Dur à inverser** — changer d'avis plus tard coûte réellement.
2. **Surprenant sans contexte** — un futur lecteur se demandera « pourquoi avoir
   fait comme ça ? ».
3. **Résultat d'un vrai arbitrage** — il y avait de vraies alternatives, tu en as
   choisi une pour des raisons précises.

Si l'un des trois manque, pas d'ADR. Format : voir [ADR-FORMAT.md](ADR-FORMAT.md).
