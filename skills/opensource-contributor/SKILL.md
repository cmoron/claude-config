---
name: opensource-contributor
description: Process obligatoire AVANT d'ouvrir une PR ou une issue sur un projet open source qu'on ne possède pas (upstream, fork→upstream, repo tiers). Vérifie les doublons (issue ET PR déjà existantes), confirme dans le code que la limitation signalée existe vraiment et qu'aucune option ne la couvre déjà, lit la doc de contribution (CONTRIBUTING/DCO/template), respecte les règles sur les contributions assistées par IA, et crée l'issue de traçabilité si absente avant de lier la PR. Charger dès qu'il est question de contribuer, remonter un fix, proposer un patch, upstreamer, ou ouvrir une pull request / issue sur un repo externe — même si l'utilisateur ne cite pas explicitement « open source ».
---

# Open Source Contributor

Ouvrir une PR ou une issue upstream est une **action publique, coûteuse pour le mainteneur** et
difficilement réversible. On n'ouvre jamais « à froid ». Ce skill est un garde-fou : vérifier
qu'on ne duplique pas, qu'on respecte le process du projet, et qu'une contribution assistée par
IA non balisée ne va pas se faire rejeter — **avant** de pousser.

S'applique aux repos qu'on **ne possède pas** (upstream d'un fork, projet tiers). Pour ses propres
repos, c'est plus léger — mais la vérif de doublon reste utile.

## L'ordre est bloquant

Ne pas appeler `gh pr create` / `gh issue create` tant que les étapes 1→4 ne sont pas faites.

### 1. Chercher les doublons — issue ET PR (bloquant)

Le piège classique : corriger un bug déjà signalé et/ou déjà corrigé dans une PR ouverte → on
ajoute du bruit dans la queue du mainteneur et on gaspille son temps de triage.

Chercher **large**, plusieurs requêtes, ouvertes **et** fermées, par symptôme ET par cause
racine / fichier touché (les gens décrivent le même bug avec des mots différents) :

```bash
gh search issues --repo OWNER/REPO "symptôme mots-clés" --limit 20
gh search prs    --repo OWNER/REPO "cause racine / fonction" --limit 20
gh pr list       --repo OWNER/REPO --state all --search "mots-clés"
```

⚠️ **Zéro résultat n'est pas une preuve tant que la commande n'est pas prouvée.** Les
flags diffèrent entre `gh search` et `gh pr list` (`gh search` n'accepte pas
`--state all` : c'est `open|closed`, ou rien du tout pour tout couvrir). Une commande
qui échoue dans un pipe rend « aucun doublon » indiscernable de « recherche cassée ».
Contrôle : relancer une requête sur un terme dont on **sait** qu'il existe dans le repo.
Si elle ne renvoie rien non plus, c'est l'outil qui est en cause, pas le corpus.

Résultats possibles :
- **Une PR corrige déjà le problème** → ne pas ouvrir de doublon. Soutenir l'existante par un
  commentaire *argumenté* (repro indépendante, confirmation de la cause racine, review technique —
  pas un « +1 »), ou proposer un complément seulement s'il apporte réellement autre chose. La
  décision finale (fermer la sienne, garder, reviewer l'autre) revient à l'utilisateur.
- **Une issue existe mais pas de PR** → la référencer dans la PR (`Closes #N`) et enchaîner.
- **Rien** → étape 5.

### 2. Vérifier que le problème existe tel qu'on le décrit (bloquant)

Signaler une limitation qui n'existe pas, ou qu'une option couvre déjà, coûte au
mainteneur sa crédibilité en nous et fait fermer l'issue en « works as designed ».

**Avant d'écrire « X est impossible » : lire le code qui l'implémente.** Le parseur
d'options, le `--help`, la fonction concernée — pas la doc, qui retarde souvent sur le
code. Une option non documentée qui fait déjà le travail est le cas le plus fréquent.

**Avant de préserver un comportement au nom de la compatibilité : chercher ses vrais
appelants.** « On ne peut pas changer ça, ça casserait des gens » est une hypothèse, pas
un fait. Un `rg` sur le dépôt, sa CI, sa doc, son wiki et les projets consommateurs
connus la tranche en trente secondes :

```bash
rg -n -- "--le-flag|nom_de_fonction" . ../autres-consommateurs
gh search code --owner ORG "le_flag"     # si l'écosystème dépasse les checkouts locaux
```

Zéro appelant réel change la conclusion : ce qu'on croyait intouchable devient
modifiable, et la solution propre redevient accessible au lieu d'être contournée. Si des
appelants existent, le changement de comportement s'énonce **en clair** dans l'issue, la
PR et le message de commit — jamais découvert à la review.

Dans les deux cas, la vérif fait aussi le travail de rédaction : elle fournit les
références de lignes exactes qui rendent l'issue crédible.

### 3. Lire la doc de contribution (bloquant)

Chaque projet a ses règles. Les ignorer = PR rejetée ou retravaillée. Lire, dans cet ordre :

- `CONTRIBUTING.md`, `CONTRIBUTING`, `.github/CONTRIBUTING.md`, `docs/contributing*`
- `.github/PULL_REQUEST_TEMPLATE*` (remplir le template imposé)
- `CODE_OF_CONDUCT.md`, exigence de **DCO / sign-off** (`git commit -s` → trailer `Signed-off-by`)
- convention de commits, branche cible, style, exigences de tests

```bash
gh api repos/OWNER/REPO/contents/CONTRIBUTING.md -q .content 2>/dev/null | base64 -d | head -100
# fallback : cloner/lire, ou consulter la page GitHub du repo
```

Appliquer ce qui est imposé (format de commit, sign-off, template, base branch).

### 4. Vérifier les règles sur les contributions assistées par IA (bloquant)

De plus en plus de projets encadrent — voire **interdisent** — les contributions générées ou
assistées par IA. Les régimes varient :
- **transparence obligatoire** (déclarer l'assistance IA, ex. noyau Linux : `Signed-off-by`
  engage le DCO, et l'usage d'outils doit être divulgué),
- **interdiction** pure de patchs IA non supervisés,
- ou au contraire **interdiction de mentions** type « Generated with … » dans les commits.

Chercher ces règles dans CONTRIBUTING, docs, README, `.github`, une éventuelle AI policy —
termes : `AI`, `LLM`, `generated`, `assisted`, `agent`, `Copilot`, `ChatGPT`, `Claude`.

- Des règles existent → **les respecter à la lettre** (divulgation ou non, sign-off, format).
- Interdiction, ou doute non levé → **ne pas pousser** sans validation explicite de l'utilisateur.
- **Pas de règle trouvée → divulgation par défaut, jamais silence.** Deux traces obligatoires :
  - trailer de commit, après le `Signed-off-by` :
    `Assisted-by: <nom du modèle> (<model-id>) via Claude Code.`
    (ex. `Assisted-by: Claude Fable 5 (claude-fable-5) via Claude Code.`)
  - une ligne équivalente dans le corps de la PR ou de l'issue.
  C'est la position défendue publiquement par Cyril (conf devant la gouvernance
  LOTUSim) : la transparence est le défaut, l'omission n'est pas neutre.

Tout ce qui précède existe dans le noyau Linux ; ce ne sera pas le cas de tous les projets —
d'où la vérif systématique plutôt qu'une hypothèse.

### 5. Si rien n'existe → créer l'issue PUIS la PR

Une PR sans issue de traçabilité est plus difficile à trier et à prioriser pour le mainteneur.
Donc, quand aucune issue ne couvre le problème :

1. Créer l'**issue** d'abord (symptôme, repro, environnement, captures si utile).
2. Ouvrir la **PR** qui la référence : `Closes #N` (ou `Fixes #N`) dans le corps.

### 6. Feu vert utilisateur avant toute action publique

Ouvrir/fermer/commenter une issue ou une PR est public. Confirmer avec l'utilisateur avant de
pousser — l'approbation d'une étape ne vaut pas pour la suivante.

## Checklist express

- [ ] Recherché issues **et** PRs (open+closed, plusieurs requêtes, symptôme + cause racine)
- [ ] Recherche prouvée non cassée (un terme connu remonte bien) — zéro résultat ≠ zéro doublon
- [ ] Pas de PR doublon (sinon : soutenir/reviewer l'existante, décision utilisateur)
- [ ] Lu le code concerné : la limitation existe, aucune option ne la couvre déjà
- [ ] Cherché les vrais appelants de tout comportement qu'on préserve « par compatibilité »
- [ ] Changement de comportement, s'il y en a un, énoncé en clair (issue + PR + commit)
- [ ] Lu CONTRIBUTING / template / CODE_OF_CONDUCT / exigence DCO-sign-off
- [ ] Vérifié la politique sur les contributions IA → respectée
- [ ] Issue existante liée (`Closes #N`), ou issue créée si absente
- [ ] Feu vert utilisateur avant `gh pr create` / `gh issue create`
