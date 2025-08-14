# 🎯 Planners Simplifiés - Approche KISS

**Philosophie** : 5 planners maximum pour éliminer la paralysie décisionnelle et maximiser l'efficacité.

## 🚀 Les 5 Planners Universels

### 1. 📦 `plan-feature.md` - **80% des cas**
**Quand l'utiliser** : Développement de nouvelles fonctionnalités
- "Ajouter un bouton de connexion"
- "Créer une page de profil"
- "Implémenter un système de commentaires"
- "Ajouter une fonctionnalité de recherche"

### 2. 🔧 `plan-fix.md` - **15% des cas**
**Quand l'utiliser** : Correction de bugs et problèmes
- "Le bouton de login ne fonctionne pas"
- "L'app crash sur iOS"
- "Les emails ne s'envoient plus"
- "Erreur 500 sur l'API"

### 3. 🏗️ `plan-architect.md` - **3% des cas**
**Quand l'utiliser** : Architecture et refactoring majeur
- "Refactoriser l'architecture backend"
- "Migrer vers microservices"
- "Optimiser les performances système"
- "Restructurer le code legacy"

### 4. 🔍 `plan-research.md` - **2% des cas**
**Quand l'utiliser** : Analyses et études
- "Analyser la concurrence"
- "Évaluer des technologies"
- "Étudier les tendances UX"
- "Analyser les retours utilisateurs"

### 5. ✍️ `plan-content.md` - **Cas rares**
**Quand l'utiliser** : Création de contenu
- "Créer la documentation API"
- "Rédiger du contenu marketing"
- "Produire des tutoriels"

## 🎯 Règle de Choix (2 secondes max)

```
Je veux... → Utilise...
├── Ajouter/créer quelque chose → plan-feature
├── Réparer/corriger quelque chose → plan-fix  
├── Refactorer/restructurer → plan-architect
├── Analyser/étudier → plan-research
└── Rédiger/documenter → plan-content
```

## ✅ Avantages de cette Approche

### ❌ AVANT (25 planners)
- Paralysie décisionnelle
- Navigation complexe (7 catégories)
- Redondances massives
- "Je veux ajouter un bouton" → Quel planner ?

### ✅ APRÈS (5 planners)
- Choix intuitif en 2 secondes
- Structure plate, pas de catégories
- Noms évidents
- 90% des cas = feature ou fix

## 🔄 Protocole Universel

**Tous les planners suivent le même protocole TODO.md** :

```yaml
**AVANT TOUT TRAVAIL** :
1. 🔒 **Claim d'abord** : status: todo → status: claimed
2. 🚀 **Puis travaille** : status: claimed → status: in_progress  
3. ✅ **Enfin termine** : status: in_progress → status: done

**JAMAIS de travail sans claim** - évite les race conditions !
```

## 📊 Statistiques d'Usage Prévues

- **plan-feature** : 80% (développement quotidien)
- **plan-fix** : 15% (maintenance et bugs)
- **plan-architect** : 3% (décisions techniques majeures)
- **plan-research** : 2% (analyses ponctuelles)
- **plan-content** : Rare (documentation/marketing)

## 🎪 Migration depuis l'Ancienne Structure

La structure complexe (25 planners en 7 catégories) a été sauvegardée dans `./planners-backup-archive/` à la racine du projet au cas où.

**Mapping de migration** :
- Tous les planners engineering → `plan-feature` ou `plan-architect`
- Tous les planners debug → `plan-fix`
- Tous les planners research → `plan-research`
- Tous les planners marketing/design → `plan-content`

## 🚀 Principe KISS Appliqué

**Keep It Simple, Stupid** - L'utilisateur doit pouvoir choisir le bon planner en 2 secondes maximum, sans réfléchir.

**Focus** : Ergonomie > Complétude