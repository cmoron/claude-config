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
3. Surveillance du déploiement staging/prod selon le skill `deployment` : attendre la fin
   du job de déploiement puis vérifier le **healthcheck** (le déploiement n'est validé que
   si le service répond).
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

**Fallback final** (3 itérations épuisées, main/prod toujours cassé) : **stop + rapport**.
Main/prod est laissé en l'état ; le rapport indique explicitement l'état cassé et l'action
manuelle requise. Pas de rollback automatique.
