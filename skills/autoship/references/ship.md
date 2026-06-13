# Ship — chorégraphie de livraison

Appelé par la phase 5 du skill `autoship`. Hypothèse : build vert + tests verts, travail
sur la branche `autoship/<slug>`. Toutes les commandes `gh` supposent `gh` authentifié
(cf. skill `deployment`).

## 1. Commit & PR

1. Commit conventionnel (logique de la commande `/commit`) : `<type>(<scope>): <quoi>`,
   corps = pourquoi si non évident.
2. `git push -u origin autoship/<slug>`
3. `gh pr create --fill --base <branche-par-défaut>` (titre/corps dérivés du commit et de
   la description de tâche).

## 2. CI de la PR

1. `gh pr checks --watch` (ou `gh run watch <run-id>`) jusqu'à complétion.
2. CI **verte** → aller en section 3.
3. CI **rouge** → diagnostiquer via `gh run view <id> --log-failed`, corriger sur la
   branche, recommit, repush. **Borné à 3 tentatives.**
4. Toujours rouge après 3 tentatives → **abort** : convertir la PR en draft
   (`gh pr ready --undo`), laisser branche + PR en place, rapport. Pas de merge.

## 3. Merge & surveillance

1. `gh pr merge --squash --delete-branch` (squash = 1 commit, historique linéaire ;
   ne jamais force push).
2. `gh run watch` sur le run déclenché sur la branche par défaut.
3. **Gate staging (obligatoire si un staging existe).** Surveillance du déploiement selon
   le skill `deployment` :
   - Si une cible **staging** existe (détectée en Phase 0) : déployer staging d'abord,
     puis vérifier son **healthcheck**. Staging KO → **phase 5bis** (section 4) sans jamais
     toucher prod. Staging OK → promouvoir vers prod, puis vérifier le healthcheck prod.
   - Si **aucun staging n'existe** : déployer prod directement, vérifier le healthcheck —
     et **signaler dans le rapport** que le déploiement s'est fait sans gate staging
     (facteur de risque additionnel assumé par l'utilisateur via `/autoship`).
   - Le déploiement n'est validé que si le service répond.
4. Main CI verte + healthcheck OK → **succès**, passer au rapport final.
5. Main CI rouge OU healthcheck KO → **phase 5bis** (section 4).

## 4. Auto-correction post-merge (phase 5bis)

Boucle **bornée à 3 itérations** :

1. Diagnostiquer : `gh run view <id> --log-failed` (CI main) ou les logs du déploiement /
   healthcheck.
2. Créer une branche `autoship/<slug>-fix-<n>`, appliquer le fix (TDD si pertinent).
3. `gh pr create --fill` → `gh pr checks --watch`.
4. CI verte → `gh pr merge --squash --delete-branch` → re-surveiller main + déploiement
   (section 3, étapes 2–3).
5. Sain → **succès** (rapport). Toujours cassé → itération suivante.

**Fallback final** (3 itérations de fix-forward épuisées, main/prod toujours cassé) :
**auto-revert** plutôt que laisser prod cassé.

1. Identifier le(s) commit(s) de merge introduit(s) par ce run sur la branche par défaut.
2. `git revert --no-edit <sha-merge>` (du plus récent au plus ancien si plusieurs) sur une
   branche `autoship/<slug>-revert`. Le revert restaure le dernier état connu sain — il
   n'efface pas l'historique (compatible historique linéaire, pas de force push).
3. `gh pr create --fill` → `gh pr checks --watch`. Le revert doit rendre la CI verte.
4. CI verte → `gh pr merge --squash --delete-branch` → re-surveiller main + redéployer
   (section 3 : staging si présent, puis prod) → vérifier le healthcheck.
5. Sain après revert → **succès dégradé** : la feature n'est PAS livrée mais prod est
   restaurée. Le rapport le dit explicitement (revert appliqué, raison, action manuelle =
   reprendre la feature plus tard).

**Si le revert lui-même échoue** (CI du revert rouge, healthcheck toujours KO, ou conflit
de revert non trivial) : **stop + escalade**. C'est le seul cas où prod est laissé cassé —
le rapport l'indique explicitement avec l'action manuelle urgente requise.
