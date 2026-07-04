---
name: opensource-contributor
description: Process obligatoire AVANT d'ouvrir une PR ou une issue sur un projet open source qu'on ne possède pas (upstream, fork→upstream, repo tiers). Vérifie les doublons (issue ET PR déjà existantes), lit la doc de contribution (CONTRIBUTING/DCO/template), respecte les règles sur les contributions assistées par IA, et crée l'issue de traçabilité si absente avant de lier la PR. Charger dès qu'il est question de contribuer, remonter un fix, proposer un patch, upstreamer, ou ouvrir une pull request / issue sur un repo externe — même si l'utilisateur ne cite pas explicitement « open source ».
---

# Open Source Contributor

Ouvrir une PR ou une issue upstream est une **action publique, coûteuse pour le mainteneur** et
difficilement réversible. On n'ouvre jamais « à froid ». Ce skill est un garde-fou : vérifier
qu'on ne duplique pas, qu'on respecte le process du projet, et qu'une contribution assistée par
IA non balisée ne va pas se faire rejeter — **avant** de pousser.

S'applique aux repos qu'on **ne possède pas** (upstream d'un fork, projet tiers). Pour ses propres
repos, c'est plus léger — mais la vérif de doublon reste utile.

## L'ordre est bloquant

Ne pas appeler `gh pr create` / `gh issue create` tant que les étapes 1→3 ne sont pas faites.

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

Résultats possibles :
- **Une PR corrige déjà le problème** → ne pas ouvrir de doublon. Soutenir l'existante par un
  commentaire *argumenté* (repro indépendante, confirmation de la cause racine, review technique —
  pas un « +1 »), ou proposer un complément seulement s'il apporte réellement autre chose. La
  décision finale (fermer la sienne, garder, reviewer l'autre) revient à l'utilisateur.
- **Une issue existe mais pas de PR** → la référencer dans la PR (`Closes #N`) et enchaîner.
- **Rien** → étape 4.

### 2. Lire la doc de contribution (bloquant)

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

### 3. Vérifier les règles sur les contributions assistées par IA (bloquant)

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

Tout ce qui précède existe dans le noyau Linux ; ce ne sera pas le cas de tous les projets —
d'où la vérif systématique plutôt qu'une hypothèse.

### 4. Si rien n'existe → créer l'issue PUIS la PR

Une PR sans issue de traçabilité est plus difficile à trier et à prioriser pour le mainteneur.
Donc, quand aucune issue ne couvre le problème :

1. Créer l'**issue** d'abord (symptôme, repro, environnement, captures si utile).
2. Ouvrir la **PR** qui la référence : `Closes #N` (ou `Fixes #N`) dans le corps.

### 5. Feu vert utilisateur avant toute action publique

Ouvrir/fermer/commenter une issue ou une PR est public. Confirmer avec l'utilisateur avant de
pousser — l'approbation d'une étape ne vaut pas pour la suivante.

## Checklist express

- [ ] Recherché issues **et** PRs (open+closed, plusieurs requêtes, symptôme + cause racine)
- [ ] Pas de PR doublon (sinon : soutenir/reviewer l'existante, décision utilisateur)
- [ ] Lu CONTRIBUTING / template / CODE_OF_CONDUCT / exigence DCO-sign-off
- [ ] Vérifié la politique sur les contributions IA → respectée
- [ ] Issue existante liée (`Closes #N`), ou issue créée si absente
- [ ] Feu vert utilisateur avant `gh pr create` / `gh issue create`
