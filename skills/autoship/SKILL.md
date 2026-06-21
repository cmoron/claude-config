---
name: autoship
description: Produit une petite feature/fix en autonomie totale — map, plan, build (TDD + review indépendante), spec-gate, vérif comportementale, doc, ship. Jamais bloquant : se termine toujours soit livré, soit en PR prête à reviser (atterrissage sûr si zone sensible DB/auth/CI-CD). Invoqué par /autoship. À utiliser quand le risque de régression est jugé faible par l'utilisateur.
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

**Jamais bloquant.** On lance et on part : autoship ne s'arrête jamais pour demander une
décision. L'état terminal est toujours l'un de deux — **livré** (mergé + déployé + sain)
ou **PR prête laissée pour revue** (verte, documentée, reviewée). Toute condition qui
rendrait le merge auto risqué (zone sensible touchée, gate amont encore KO après retries,
CI rouge après retries) **dégrade vers la PR-prête + rapport**, jamais vers une question.

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

Comprendre le code pertinent à la tâche via le sous-agent `Explore`.
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

Puis **review en boucle** sur le diff complet, par un reviewer **indépendant** (pas
l'auteur) : `superpowers:requesting-code-review` → `superpowers:receiving-code-review` →
appliquer les corrections → re-review, **jusqu'à clean ou borne (3)**. Finir par
`/simplify` sur le diff final. La phase n'est validée que si **build vert + tests verts**.

Si après les retries le build/les tests ne passent pas → on ne peut pas atteindre une PR
verte : commit du WIP sur la branche de travail + rapport (toujours sans question).

## Phase 3bis — Spec-gate (a-t-on construit la *bonne* chose ?)

Brique réutilisable. Invoquer le skill `review` sur l'**axe Spec**, en lui donnant la
description de tâche (`$ARGUMENTS`) comme critères d'acceptation, sur le diff depuis le
merge-base : le diff répond-il à la demande **et** aux edge cases évidents ? Évaluation
par un agent **frais** (pas celui qui a codé).

- Conforme → continuer.
- Écart → rework **borné (3)** puis ré-évaluation. Toujours KO → atterrissage **PR-prête**
  (cf. Phase 5), raison « spec-gate : <écart> ». Pas de question.

## Phase 3ter — Vérif comportementale (ça marche *vraiment* ?)

Brique réutilisable. « Tests verts » ≠ « la feature marche ». Invoquer le skill `verify`
(lance l'app / appelle l'endpoint / `webapp-testing` Playwright si UI) pour observer le
comportement réel attendu par la tâche.

- OK → continuer.
- KO → rework **borné (3)** puis re-vérif. Toujours KO → atterrissage **PR-prête**
  (cf. Phase 5), raison « verify : <symptôme> ». Pas de question.

## Phase 4 — Doc

Mettre à jour doc / README / changelog **au prorata du changement uniquement**. Pas de
sur-documentation. Si rien ne le justifie, ne rien écrire.

## Phase 5 — Ship (avec atterrissage selon le risque)

Suivre `references/ship.md`. La chorégraphie choisit l'**atterrissage** selon les zones
touchées par le diff :
- **Auto** (rien de sensible, aucun gate amont dégradé) : commit → PR → CI → merge squash
  → staging → prod → auto-revert si casse.
- **PR-prête** (zone dimensionnante touchée — DB / auth-secrets / CI-CD-infra — ou gate
  amont ayant dégradé) : commit → PR → CI verte, puis **stop avant merge/deploy** →
  rapport « PR prête ». La taille du diff seule ne déclenche pas la PR-prête (on va au
  bout) ; elle est juste signalée dans le rapport.

## Phase 5bis — Auto-correction post-merge

Atterrissage **auto** uniquement (il y a eu un merge réel). Déclenchée si, **après le merge
sur main**, le CI sur main est rouge OU le healthcheck de déploiement est KO. Procédure détaillée dans `references/ship.md`. Fix-forward **borné
(3 itérations)**. Si épuisé et main/prod toujours cassé → **auto-revert** du merge
(restaure le dernier état sain via PR de revert) plutôt que laisser prod cassé. Prod n'est
laissé en l'état **que si le revert lui-même échoue** → stop + escalade.

## Garde-fous (toutes phases)

- Retries bornés (défaut 3) ; jamais de boucle infinie.
- **Jamais de pause pour validation** (fire-and-forget) : toute impasse dégrade vers
  PR-prête (verte) ou, si le build ne passe pas, WIP-branche + rapport — jamais une question.
- Règles git absolues : pas de `--no-verify`, pas de force push, rebase/squash (historique
  linéaire), Conventional Commits.
- Sur abort : état laissé sûr et explicite (branche poussée / PR draft / point d'arrêt
  nommé). Post-merge cassé → tenter le fix-forward puis l'auto-revert ; prod n'est laissé
  cassé que si le revert échoue (escalade explicite).

## Rapport final (systématique)

À la fin du run (succès comme échec), produire un résumé structuré :
- **Tâche** : la description fournie
- **Statut** : livré / **PR prête à reviser** (zone sensible ou gate non franchi) / WIP (build KO) / bloqué post-merge
- **Fait** : phases franchies, branche, PR (URL), commit(s) sur main
- **Bloqué sur** : la cause précise s'il y a lieu
- **Action manuelle requise** : ce que l'utilisateur doit faire, le cas échéant

## Notification

En fin de run, envoyer une notification push (succès / blocage) via le canal disponible
(`PushNotification` si présent). Si aucun canal n'est configuré, dégrader silencieusement
en simple message final.
