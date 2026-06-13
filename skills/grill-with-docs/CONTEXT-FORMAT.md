# Format de CONTEXT.md

`CONTEXT.md` est le glossaire du **langage ubiquitaire** d'un contexte : le
vocabulaire partagé entre toi et l'agent. Bénéfice : variables/fonctions/fichiers
nommés cohéremment, codebase plus facile à naviguer, moins de tokens dépensés en
verbiage (l'agent dispose d'un langage plus concis).

## Structure

```md
# {Nom du contexte}

{Une ou deux phrases : ce qu'est ce contexte et pourquoi il existe.}

## Langage

**Commande**:
{Une ou deux phrases décrivant le terme.}
_Éviter_: achat, transaction

**Facture**:
Une demande de paiement envoyée au client après livraison.
_Éviter_: note, demande de paiement

**Client**:
Une personne ou organisation qui passe des commandes.
_Éviter_: acheteur, compte, utilisateur
```

## Règles

- **Sois tranché.** Quand plusieurs mots existent pour un même concept, choisis le
  meilleur et liste les autres sous `_Éviter_`.
- **Définitions serrées.** Une à deux phrases max. Définis ce que le terme **est**,
  pas ce qu'il fait.
- **Uniquement les termes spécifiques à ce projet.** Les concepts de programmation
  généraux (timeouts, types d'erreur, patterns utilitaires) n'y sont pas, même si
  le projet les utilise beaucoup. Avant d'ajouter un terme : est-ce un concept
  propre à ce contexte, ou un concept de programmation général ? Seul le premier a
  sa place.
- **Groupe les termes sous des sous-titres** quand des clusters naturels émergent.
  Si tout appartient à un seul domaine cohérent, une liste plate suffit.

## Mono vs multi-contexte

**Mono-contexte (la plupart des repos)** : un seul `CONTEXT.md` à la racine.

**Multi-contextes** : un `CONTEXT-MAP.md` à la racine liste les contextes, où ils
vivent, et comment ils se relient :

```md
# Context Map

## Contextes

- [Commandes](./src/commandes/CONTEXT.md) — reçoit et suit les commandes client
- [Facturation](./src/facturation/CONTEXT.md) — génère factures et encaisse

## Relations

- **Commandes → Facturation** : Commandes émet `CommandePassée` ; Facturation le
  consomme pour générer une facture
- **Commandes ↔ Facturation** : types partagés pour `ClientId` et `Money`
```

Inférence de la structure :
- Si `CONTEXT-MAP.md` existe → le lire pour trouver les contextes.
- Sinon, si un `CONTEXT.md` racine existe → mono-contexte.
- Si ni l'un ni l'autre → créer un `CONTEXT.md` racine paresseusement au premier
  terme résolu.

Quand plusieurs contextes existent, infère celui auquel se rapporte le sujet
courant. Si c'est ambigu, demande.
