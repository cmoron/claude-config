---
name: openclaw
description: Pour travailler sur Nestor/openclaw : VPS mymelon.tech, configuration du service, workspace de l'agent, services actifs, déploiement et migration NAS.
---

# Openclaw — Nestor

Nestor est un assistant IA personnel tournant sur un VPS Hostinger, accessible via Telegram.
Ce skill fournit le contexte nécessaire pour le maintenir et le faire évoluer.

## Accès

- **VPS** : `cyril@mymelon.tech` (clefs SSH configurées, connexion directe)
- **Repo local** : `~/src/openclaw/` (synchronisé avec le VPS)
- **Config sur VPS** : `~/.openclaw/`
- **Service** : `systemctl --user status openclaw-gateway`

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

## Contrainte Chrome sur VPS

Chrome est **éteint par défaut** (VPS Hostinger 1 vCPU partagé, 0 swap — Chrome sature le CPU).
Si Nestor a besoin du browser (Keep, Carrefour) : il échoue immédiatement et notifie Cyril.
Cyril lance Chrome manuellement depuis VNC si nécessaire.

## Objectif migration NAS

Faire tourner Chrome en service systemd permanent sur une VM KVM (NAS Cyril, Ryzen 5 5600GT, 14 GB RAM) :
- Xvfb + Chrome démarrent au boot, redémarrés par systemd si crash
- Sessions Carrefour / Google Keep persistées dans le profil Chrome
- Une seule intervention manuelle : login initial via VNC après migration
- Résultat : autonomie totale sur tous les services

## Workflow de modification

1. Modifier les fichiers dans `~/src/openclaw/` (local)
2. Pousser sur GitHub : `git add -p && git commit && git push`
3. Sur le VPS : `cd ~/src/openclaw && git pull`
4. Redémarrer si besoin : `systemctl --user restart openclaw-gateway`
5. Vérifier : `systemctl --user status openclaw-gateway` + tester via Telegram

Pour les fichiers workspace (SOUL.md, AGENTS.md, etc.), les changements sont lus au prochain message sans redémarrage.
