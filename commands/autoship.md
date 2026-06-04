---
description: "Produit une petite feature/fix en autonomie totale (map→plan→build→review→doc→ship). Usage : /autoship <description de la feature/fix>"
argument-hint: <description de la feature/fix>
---

Lance la production autonome de la tâche suivante en mode fire-and-forget :

> $ARGUMENTS

Invoque le skill `autoship` et suis sa procédure de bout en bout (préflight → map → plan →
build → doc → ship → auto-correction post-merge). Mode fire-and-forget : ne pas s'arrêter
pour demander validation. Sur blocage dur, arrêt propre + rapport.

Si `$ARGUMENTS` est vide, demander la description de la tâche avant de lancer.
