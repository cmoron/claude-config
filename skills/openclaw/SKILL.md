---
name: openclaw
description: Pour travailler sur Nestor/openclaw : VM NAS locale (openclaw-vm), configuration du service, workspace de l'agent, services actifs, déploiement via Ansible.
---

# Openclaw — Nestor

Nestor est un assistant IA personnel tournant sur une VM KVM locale (NAS), accessible via Telegram.
Ce skill fournit le contexte nécessaire pour le maintenir et le faire évoluer.

## Qu'est-ce qu'OpenClaw

[OpenClaw](https://github.com/openclaw/openclaw) (MIT, ex-Clawdbot/Moltbot, créé par
Peter Steinberger) est une plateforme open-source **auto-hébergée** qui transforme un
LLM en agent personnel persistant et autonome, accessible via messagerie.
**Nestor est une instance d'OpenClaw** — l'agent IA personnel de Cyril. Modifier Nestor,
c'est configurer une instance de ce projet ; les concepts ci-dessous sont ceux d'OpenClaw.

### Architecture (hub-and-spoke)

Un processus **Gateway** unique au centre, en 4 couches :

1. **Channel adapters** — normalisent les entrées des canaux de messagerie (Telegram,
   WhatsApp, Slack, Discord…). Nestor n'utilise que **Telegram**.
2. **Gateway / control plane** — serveur WebSocket Node.js : routage des messages,
   gestion des sessions, mapping canal → workspace → modèle.
3. **Agent runtime** — assemble le contexte (historique, prompts, skills) et exécute la
   **boucle agentique** : recevoir le contexte → appeler le LLM → exécuter les tools →
   observer le résultat → répondre.
4. **Tools & exécution** — shell, fichiers, navigateur, emails ; optionnellement isolés
   en sandbox Docker pour limiter le blast radius.

Model-agnostic : on fournit ses propres clés API (Nestor tourne sur Gemini 3 Flash).

### Concepts clés

- **Workspace** — répertoire de fichiers Markdown, source de vérité de l'agent. À chaque
  tour, le runtime compose le system prompt à partir de `SOUL.md` (personnalité),
  `AGENTS.md` (manuel opératoire / règles), l'historique de session et les skills pertinents.
- **Skills** — playbooks `SKILL.md` à frontmatter YAML, **lazy-loaded** : seul le metadata
  est lu en permanence, le contenu complet n'est chargé que si la tâche matche le skill
  (même principe d'économie de tokens que les skills Claude Code).
- **Heartbeat** — tours d'agent **périodiques** déclenchés sans message utilisateur, pour
  vérifier proactivement des tâches (Nestor : toutes les 4h, 08h-22h30). Checklist dans
  `HEARTBEAT.md`.
- **Mémoire** — hybride : fichiers Markdown durables (`MEMORY.md`) + base vectorielle
  SQLite pour le rappel sémantique des conversations passées.
- **MCP** — OpenClaw peut se connecter à des services externes via Model Context Protocol.

Le mapping concret de ces concepts sur l'instance Nestor est détaillé ci-dessous.

## Accès

- **VM** : `cyril@192.168.122.100` via ProxyJump `nas` — ou `ssh -J nas cyril@192.168.122.100`
- **Ansible** : `~/src/openclaw/ansible/` (inventaire + playbooks de déploiement)
- **Config sur VM** : `~/.openclaw/`
- **Service** : `systemctl --user status openclaw-gateway`
- **VNC** : `vnc-openclaw.home.moron.at` (pour Chrome manuel si besoin)

## Architecture du service

```
~/.openclaw/
├── openclaw.json          # Config principale (modèles, canaux, heartbeat)
├── .env                   # Clefs API, tokens (ne jamais committer)
└── workspace/             # Contexte injecté dans l'agent
    ├── SOUL.md            # Personnalité et règles de base
    ├── AGENTS.md          # Instructions de comportement et d'autonomie
    ├── HEARTBEAT.md       # Tâches des checks périodiques (toutes les 4h, 08h-22h30)
    ├── TOOLS.md           # Infos setup : comptes, profils, CLIs disponibles
    ├── USER.md            # Profil Cyril + contacts autorisés (Estelle)
    ├── MEMORY.md          # Mémoire persistante de Nestor
    ├── memory/            # Journaux quotidiens + état heartbeat
    └── skills/
        ├── gog/           # Skill Google Workspace (gmail, calendar)
        └── gkeep/         # Skill Google Keep (browser)
```

## Modèles IA

- **Principal** : `google/gemini-3-flash-preview`
- **Fallbacks** : `google/gemini-3-pro-preview`, `google/gemini-2.5-flash-lite`
- **Subagents** : `google/gemini-2.5-flash`
- **⚠️ Ne pas utiliser Flash Lite comme modèle principal** — confond outils natifs et skills

## Canaux Telegram

- Cyril ID : `1595199898`
- Estelle ID : `1344871168` (paired, accès limité — pas de tools)

## Services actifs

| Service | Outil | État | Notes |
|---------|-------|------|-------|
| Gmail | `gog gmail` | ✓ OK | API Google, pas de browser |
| Google Calendar | `gog calendar` | ✓ OK | API Google, pas de browser |
| Recherche web | skill `ddg-search` | ✓ OK | Python pur |
| Météo | skill `weather` | ✓ OK | |
| Google Keep | Browser headless | ⚠️ Partiel | Chrome doit être lancé manuellement |
| Carrefour Drive | Browser CDP port 19222 | ⚠️ Partiel | Chrome non-headless + Xvfb DISPLAY:1 requis |

## Chrome sur la VM NAS

Chrome tourne en service systemd permanent sur la VM (Ryzen 5 5600GT, 14 GB RAM, 3 vCPUs) :
- Xvfb + Chrome démarrent au boot, redémarrés automatiquement par systemd si crash
- Sessions Carrefour / Google Keep persistées dans le profil Chrome (`~/.openclaw/browser/chrome-profile`)
- Debug port : `9222` — display : `:1`
- En cas de problème de session : accès VNC via `vnc-openclaw.home.moron.at`

## Workflow de modification

1. Modifier les fichiers dans `~/src/openclaw/` (local)
2. Déployer via Ansible : `ansible-playbook -i ansible/inventory.yml ansible/playbooks/03-openclaw.yml`
3. Redémarrer si besoin : `ssh -J nas cyril@192.168.122.100 'systemctl --user restart openclaw-gateway'`
4. Vérifier : status + tester via Telegram

Pour les fichiers workspace (SOUL.md, AGENTS.md, etc.), les changements sont lus au prochain message sans redémarrage.

## Montées de version openclaw

**On NE met PAS à jour openclaw via `npm i -g openclaw`.** Le mécanisme canonique est la commande CLI **`openclaw update`** (l'historique de la VM est plein de `openclaw update`).

⚠️ Le `openclaw` du PATH interactif tape un **Node v18** → erreur *"Node v22+ required"*. Invoquer via Node v24 :
```bash
NODE=~/.nvm/versions/node/v24.13.1/bin/node
DIST=~/.nvm/versions/node/v24.13.1/lib/node_modules/openclaw
$NODE $DIST/dist/index.js update --dry-run        # prévisualiser
```

- **Canaux** : `--channel stable|beta|dev` (persisté dans `openclaw.json` → bloc `update`, vide = stable par défaut).
  - `stable` / `beta` → install **mode npm package** : `openclaw update` résout via le package manager, donc **limité à ce qui est publié** (la beta dist-tag peut pointer = stable). Notre install est en mode package (pas de `.git` dans le dist).
  - `dev` → **bascule en git checkout** (build depuis les sources GitHub) : seul moyen d'avoir du code pas encore packagé, mais bleeding-edge + rebuild à chaque update.
- `--tag <version|dist-tag|spec>` cible une version précise ; `--dry-run` prévisualise (montre `Target version` + l'action) ; `--no-restart`, `--yes`, `--timeout <s>`.
- `openclaw update status` (canal + versions) ; `openclaw update wizard` (interactif).
- **Plugins versionnés séparément** via `openclaw plugins install/update/uninstall` (codex, discord, whatsapp sont des plugins npm externes dans `~/.openclaw/npm/projects/`). Un plugin peut **exiger un runtime ≥ version** : ex. codex 0.139 vit dans `@openclaw/codex@2026.6.6-beta.1` qui exige openclaw runtime ≥2026.6.6-beta.1 — installer le plugin sur un runtime trop vieux est rejeté.
- Toujours redémarrer après via `openclaw gateway restart` (cf. règle restart), puis vérifier `gateway ready` + heartbeat/telegram dans les logs.

## Re-auth OAuth codex/OpenAI sur la VM headless (tunnel SSH)

La VM **n'a pas de navigateur utilisable** (Chrome sur Xvfb:1 via VNC seulement, pas de copier-coller). Le flow OAuth **par défaut** de codex (`codex login` / `openclaw models auth login --provider openai`) ouvre un serveur de callback sur **`localhost:<port>` de la VM** et y redirige après sign-in → il faut un navigateur qui « revient » sur la VM. Le flow **device** (`--device-code`) est censé éviter ça mais en pratique a posé souci (URL `https://auth.openai.com/codex/device` sans flux de code clair).

**Méthode fiable = forwarder le port de callback via SSH, ouvrir l'URL sur SON navigateur local :**
```bash
# 1. Depuis le laptop, ouvrir une session avec le port de callback forwardé
#    (codex écoute historiquement sur 1455 ; confirmer via le redirect_uri de l'URL affichée)
ssh -J nas -L 1455:localhost:1455 cyril@192.168.122.100

# 2. Dans cette session, lancer le login SANS --device-code (force le flow navigateur)
openclaw models auth login --provider openai --force        # --force vire le profil bloqué

# 3. Copier l'URL affichée, l'ouvrir dans le navigateur DU LAPTOP, se connecter
#    (cyril.moron@gmail.com), approuver.
# 4. La redirection part vers localhost:1455 → le tunnel la renvoie à la VM →
#    le terminal capte le callback et finit le login tout seul.
```
- Si l'URL contient `redirect_uri=http://localhost:XXXX` avec un **autre port**, refaire le `ssh -L XXXX:localhost:XXXX`.
- Codex 0.139 expose aussi `codex login --with-access-token` / `--with-api-key` (lecture sur stdin) si on récupère un token par un autre canal.
- Le flow par défaut imprime l'URL **et** écoute le port même sans navigateur sur la VM — donc le tunnel suffit, aucun navigateur VM requis.
- ⚠️ **`--force` SUPPRIME les autres profils du provider** : pour AJOUTER un 2e compte (ex. backup), login **SANS `--force`**. Pour repartir propre (token bloqué), `--force`.
- ⚠️ **Si le terminal ne rend pas la main** après "Authentication successful" navigateur (callback `localhost:port` qui n'atteint pas le listener) : l'auth est souvent **déjà persistée quand même** → `Ctrl-C` et vérifier avec un run test. Sinon, livrer le callback à la main : `curl "<url-de-redirection-copiée>"` **depuis la VM** (le listener tourne sur la VM:localhost:port).
- **Plusieurs profils valides = round-robin** par défaut. Pour forcer un ordre déterministe (ex. compte principal d'abord, backup en secours) : `openclaw models auth order set --agent <id> --provider openai <profil1> <profil2>` (persisté dans `auth-state.json`, `… order clear` pour revenir au round-robin).
- **Pourquoi re-auth** : la rotation des refresh-tokens OpenAI invalide les tokens (`token_invalidated` / `refresh_token_reused`) → seuls les comptes re-signés récemment marchent. Cf. `project_codex_oauth_warmup.md` dans la mémoire.
