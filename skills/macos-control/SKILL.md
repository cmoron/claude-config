---
name: macos-control
description: Piloter macOS depuis Claude Code — captures d'écran, clics, frappe clavier, automatisation d'apps GUI. Charger dès qu'il s'agit de contrôler le Mac, cliquer quelque part, prendre une capture, tester une app native, piloter une interface graphique ou automatiser un outil sans CLI, même si « computer use » n'est jamais prononcé. Donne la règle de choix entre le serveur MCP natif `computer-use` et le chemin CLI de secours (screencapture / osascript / CGEvent) pour les sessions `-p`, hooks et cron — plus les pièges qui coûtent des heures de faux diagnostics.
---

# Contrôle macOS

Deux chemins, et le choix n'est pas une question de goût : le natif est meilleur
partout où il s'applique. Le chemin CLI n'existe que pour les contextes où le
natif est indisponible.

## 1. D'abord : `computer-use` natif

Serveur MCP intégré à Claude Code, désactivé par défaut.

```
/mcp        # trouver « computer-use » → Enable (persiste par projet)
```

Il fournit quatre outils — **Screenshot, Click, Type, Key** — et surtout des
garanties que le chemin CLI n'a pas :

- **downscaling Retina automatique** : plus de conversion pixels/points à faire
- **approbation par app et par session**, avec avertissement explicite sur les
  apps à large portée (Terminal/IDE = équivalent shell, Finder = tous les
  fichiers, Réglages Système = configuration machine)
- **les autres apps sont masquées** pendant le travail, et **le terminal est
  exclu des captures** — une protection anti prompt-injection réelle
- **`Esc` global** interrompt tout ; verrou machine mono-session

Prérequis, tous obligatoires : macOS, plan **Pro ou Max**, authentification
claude.ai (pas Bedrock/Vertex/Foundry), session **interactive**. Si
`computer-use` n'apparaît pas dans `/mcp`, c'est l'un de ces quatre qui manque —
`/status` confirme le plan.

Permissions demandées au premier usage : **Accessibilité** (cliquer, taper) et
**Enregistrement de l'écran** (voir). macOS exige parfois un redémarrage de
Claude Code après l'octroi de l'enregistrement d'écran.

Doc : https://code.claude.com/docs/en/computer-use

## 2. Sinon : le chemin CLI

À réserver aux cas où le natif ne s'applique pas — mode `-p`/headless, hooks,
cron, ou pilotage scripté déterministe depuis Bash (un script shell, pas un tour
de modèle).

Les permissions se donnent au **bundle de l'app hôte**, pas au binaire `claude`.
Pour l'identifier, remonter les ancêtres :

```bash
p=$$; while [ "$p" != 1 ]; do read p c <<< "$(ps -o ppid=,comm= -p $p)"; echo "$c"; done
```

Puis, dans Réglages Système → Confidentialité et sécurité, cocher ce bundle dans
**Accessibilité** et **Enregistrement de l'écran**. Impossible en ligne de
commande : `tccutil` sait révoquer, jamais accorder.

Vérifier l'état :

```bash
osascript -e 'tell application "System Events" to return UI elements enabled'   # accessibilité
```

### Capture

```bash
screencapture -x out.png              # écran entier, silencieux
screencapture -x -R 0,0,800,600 out.png   # région
```

Puis **lire l'image** — c'est le seul moyen fiable de savoir où on en est.

### Clavier

```bash
osascript -e 'tell application "System Events" to keystroke "bonjour"'
osascript -e 'tell application "System Events" to keystroke "s" using command down'
osascript -e 'tell application "System Events" to key code 36'   # 36 Entrée · 53 Échap · 48 Tab · 51 Retour arrière · 123-126 flèches
```

### Clic — élément nommé d'abord

Viser un élément de l'arbre d'accessibilité est plus robuste que des
coordonnées : ça survit à un déplacement de fenêtre ou à un changement de
résolution.

```bash
osascript -e 'tell application "System Events" to tell process "Finder" \
  to click menu bar item "Présentation" of menu bar 1'
```

Quand aucun élément ne correspond (canvas, jeu, app non instrumentée), passer
aux coordonnées via le binaire fourni :

```bash
scripts/click.sh <x> <y> [left|right] [nb_clics]
```

Il se compile tout seul au premier appel (`swiftc`, Xcode Command Line Tools) et
ne dépend que des frameworks système.

## Les quatre pièges du chemin CLI

Chacun a produit un faux diagnostic durable. Ils ne s'appliquent **qu'au chemin
CLI** — le natif les absorbe.

1. **`click at {x,y}` de System Events est inerte.** Sur macOS 26 il s'exécute
   sans erreur et ne délivre aucun événement. C'est la raison pour laquelle
   « cliquer en AppleScript pur » ne marche pas, et pourquoi `click.sh` passe par
   `CGEvent`. La forme `click <élément>`, elle, fonctionne.

2. **Deux repères de coordonnées.** `screencapture` produit des **pixels
   physiques** (2940×1912 sur un Retina), les clics attendent des **points**
   (1470×956) → diviser par le facteur d'échelle. Mais `position of` en
   accessibilité rend déjà des points : viser un élément évite entièrement la
   conversion.

3. **Locale française.** AppleScript formate les réels avec une virgule
   (`136,5`), que tout parseur numérique refuse. Arrondir en entier *dans*
   l'AppleScript avant de passer la valeur à un autre programme. Attention aussi
   à `round X as text`, qui se parse en `round (X as text)` et échoue.

4. **L'arbre d'accessibilité ment sur les effets.** `AXSelected` a indiqué
   « clic sans effet » alors que le menu visé était grand ouvert. Un attribut AX
   décrit un état interne, pas ce que l'utilisateur voit. **Valider par capture
   d'écran, systématiquement.**

## Discipline de vérification

- Après chaque action qui modifie l'écran : capture, puis lecture de l'image.
  Rien d'autre ne constitue une preuve.
- Les tests de clic et de frappe se battent avec le focus : si quelqu'un tape
  pendant le test, la frappe part dans la mauvaise app. Le demander explicitement
  avant de lancer une séquence.
- Une frappe qui rate sa cible atterrit ailleurs et peut renommer un fichier ou
  déclencher un raccourci. Après une séquence qui a dérapé, vérifier :
  `find ~/Desktop ~/Documents ~/Downloads -maxdepth 2 -mmin -30`.
- Un test qui ouvre une app doit la refermer. Sinon l'état résiduel pollue le
  test suivant et produit des résultats incompréhensibles.

## Limite

Le chemin CLI ne reproduit pas les garde-fous du natif : pas d'approbation par
app, pas de masquage, **le terminal reste visible dans les captures** — donc le
contenu de la session peut revenir dans le contexte du modèle. Autoriser un
terminal en Accessibilité donne le contrôle clavier/souris à tout ce qui y
tourne. À préférer le natif dès qu'il est disponible.
