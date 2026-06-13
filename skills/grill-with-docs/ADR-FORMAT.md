# Format des ADR

Les ADR (Architecture Decision Records) vivent dans `docs/adr/` avec une
numérotation séquentielle : `0001-slug.md`, `0002-slug.md`, etc. Créer le dossier
`docs/adr/` paresseusement — seulement quand le premier ADR est nécessaire.

## Template

```md
# {Titre court de la décision}

{1 à 3 phrases : quel est le contexte, qu'a-t-on décidé, et pourquoi.}
```

C'est tout. Un ADR peut tenir en un paragraphe. La valeur est d'enregistrer
**qu'une** décision a été prise et **pourquoi** — pas de remplir des sections.

## Sections optionnelles

À n'inclure que si elles apportent une vraie valeur. La plupart des ADR n'en ont
pas besoin.

- **Status** (frontmatter : `proposed | accepted | deprecated | superseded by
  ADR-NNNN`) — utile quand les décisions sont revisitées.
- **Options considérées** — seulement quand les alternatives rejetées méritent
  d'être mémorisées.
- **Conséquences** — seulement quand des effets en aval non évidents doivent être
  signalés.

## Numérotation

Scanner `docs/adr/` pour le plus grand numéro existant et incrémenter de un.

## Quand proposer un ADR

Les **trois** doivent être vrais :

1. **Dur à inverser** — changer d'avis plus tard coûte réellement.
2. **Surprenant sans contexte** — un futur lecteur regardera le code et se demandera
   « pourquoi diable ont-ils fait comme ça ? ».
3. **Résultat d'un vrai arbitrage** — il y avait de vraies alternatives, on en a
   choisi une pour des raisons précises.

Si une décision est facile à inverser, passe — tu l'inverseras. Si elle n'est pas
surprenante, personne ne se demandera pourquoi. S'il n'y avait pas de vraie
alternative, il n'y a rien à enregistrer au-delà de « on a fait l'évident ».

### Ce qui qualifie

- **Forme architecturale.** « On utilise un monorepo. » « Write model event-sourcé,
  read model projeté dans Postgres. »
- **Patterns d'intégration entre contextes.** « Commandes et Facturation
  communiquent par événements de domaine, pas en HTTP synchrone. »
- **Choix techno avec lock-in.** Base de données, bus de messages, provider d'auth,
  cible de déploiement. Pas chaque librairie — seulement celles qu'il faudrait un
  trimestre pour remplacer.
- **Décisions de frontière et de périmètre.** « Les données Client sont possédées
  par le contexte Client ; les autres y réfèrent par ID uniquement. » Les **non**
  explicites valent autant que les oui.
- **Déviations délibérées du chemin évident.** « SQL manuel plutôt qu'un ORM parce
  que X. » Tout ce où un lecteur raisonnable supposerait l'inverse — ça empêche le
  prochain ingénieur de « réparer » un choix délibéré.
- **Contraintes invisibles dans le code.** « Pas d'AWS pour cause de compliance. »
  « Temps de réponse < 200 ms à cause du contrat de l'API partenaire. »
- **Alternatives rejetées quand le rejet est non évident.** Si on a considéré
  GraphQL et choisi REST pour des raisons subtiles, enregistre-le — sinon quelqu'un
  re-proposera GraphQL dans six mois.
