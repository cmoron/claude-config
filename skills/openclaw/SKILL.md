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
