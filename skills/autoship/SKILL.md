---
name: autoship
description: Produit une petite feature/fix en autonomie totale — map, plan, build (TDD+review), doc, ship (PR, CI, merge squash, déploiement) avec auto-correction post-merge. Invoqué par /autoship. À utiliser uniquement quand le risque de régression est jugé faible par l'utilisateur.
---

# Autoship

Production autonome d'une **petite feature ou fix à faible risque de régression**.
Mode **fire-and-forget** : aucune pause pour validation humaine. L'utilisateur décide en
lançant `/autoship` que le risque est acceptable — ce skill ne réarbitre pas ce jugement.

L'argument est la description de la tâche (`$ARGUMENTS` transmis par la commande).

## Principe

Orchestrer les briques existantes, pas réécrire leur logique. Retries **bornés**
(défaut 3) à chaque phase/boucle ; jamais de boucle infinie. Sur blocage dur : arrêt
propre, état laissé sûr, rapport.

## Phase 0 — Préflight (découverte + setup)

1. Résoudre les conventions du projet, dans l'ordre :
   - `CLAUDE.md` du projet (commandes test/lint/build, cible deploy)
   - skills `stack-*` et `deployment` applicables
   - manifestes : `pyproject.toml` / `package.json` / `Cargo.toml`
   - `.github/workflows/*` pour le workflow CI et la cible de déploiement
2. Établir explicitement : commande de test, commande de lint, commande de build,
   nom du workflow CI, cible de déploiement (staging/prod) si elle existe.
3. Vérifier l'état git (working tree propre attendu) et créer la branche de travail
   `autoship/<slug-de-la-tâche>` depuis la branche par défaut à jour.
4. **Abort si la commande de test reste introuvable** : rien n'a été modifié → rapport
   (cf. section Rapport) et fin.

Créer une todo-list (TodoWrite) avec une entrée par phase pour suivre la progression.

## Phase 1 — Map

Comprendre le code pertinent à la tâche via `Explore` ou `claude-mem:smart-explore`.
Produire une compréhension **ciblée** en contexte (zones de code impactées, contrats,
tests existants) — pas un dump de fichiers.

## Phase 2 — Plan

Concevoir l'architecture de la solution via `superpowers:writing-plans`, calibrée pour
une petite feature/fix. Pas de gate humain (fire-and-forget). Le plan reste interne au
run ; il n'est pas soumis à validation.

## Phase 3 — Build loop (sous-agents)

Exécuter via `superpowers:subagent-driven-development` + `superpowers:test-driven-development` :
par tâche → test d'abord (qui échoue), implémentation minimale, lint (via hooks, ne pas
relancer manuellement), tests verts. **Retries bornés (3)** par tâche.

Puis qualité sur le diff complet : `/code-review` puis `/simplify`, en appliquant les
corrections. La phase n'est validée que si **build vert + tests verts**.

Si après les retries le build/les tests ne passent pas → **abort** : commit du WIP sur la
branche de travail, pas de PR, rapport.

## Phase 4 — Doc

Mettre à jour doc / README / changelog **au prorata du changement uniquement**. Pas de
sur-documentation. Si rien ne le justifie, ne rien écrire.

## Phase 5 — Ship

Suivre `references/ship.md` (chorégraphie complète : commit → PR → CI → merge squash →
surveillance main + déploiement).

## Phase 5bis — Auto-correction post-merge

Déclenchée si, **après le merge sur main**, le CI sur main est rouge OU le healthcheck de
déploiement est KO. Procédure détaillée dans `references/ship.md`. **Bornée (3 itérations)**.
Fallback final (retries épuisés, main/prod toujours cassé) : **stop + rapport**, sans
rollback auto.

## Garde-fous (toutes phases)

- Retries bornés (défaut 3) ; jamais de boucle infinie.
- Règles git absolues : pas de `--no-verify`, pas de force push, rebase/squash (historique
  linéaire), Conventional Commits.
- Sur abort : état laissé sûr et explicite (branche poussée / PR draft / point d'arrêt
  nommé), sauf le cas post-merge cassé (assumé).

## Rapport final (systématique)

À la fin du run (succès comme échec), produire un résumé structuré :
- **Tâche** : la description fournie
- **Statut** : succès complet / abort à la phase X / bloqué post-merge
- **Fait** : phases franchies, branche, PR (URL), commit(s) sur main
- **Bloqué sur** : la cause précise s'il y a lieu
- **Action manuelle requise** : ce que l'utilisateur doit faire, le cas échéant

## Notification

En fin de run, envoyer une notification push (succès / blocage) via le canal disponible
(`PushNotification` si présent). Si aucun canal n'est configuré, dégrader silencieusement
en simple message final.
