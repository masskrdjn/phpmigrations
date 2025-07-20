# Contributing to Rector PHP Analysis Tools

Merci de votre intérêt pour contribuer à ce projet ! 🎉

## 🚀 Comment contribuer

### Signaler un bug
1. Vérifiez que le bug n'est pas déjà signalé dans les Issues
2. Créez une nouvelle Issue avec :
   - Description claire du problème
   - Étapes pour reproduire
   - Version de PowerShell et PHP
   - Exemple de sortie d'erreur

### Proposer une amélioration
1. Ouvrez une Issue pour discuter de votre idée
2. Attendez les retours avant de développer
3. Suivez les guidelines de développement

### Soumettre du code
1. Forkez le repository
2. Créez une branche feature (`git checkout -b feature/amazing-feature`)
3. Committez vos changements (`git commit -m 'Add amazing feature'`)
4. Pushez vers la branche (`git push origin feature/amazing-feature`)
5. Ouvrez une Pull Request

## 📝 Guidelines de développement

### Scripts PowerShell
- Utilisez des noms explicites pour les fonctions
- Commentez le code complexe
- Gérez les erreurs avec try/catch
- Testez sur PowerShell 5.1 et 7+

### Documentation
- Mettez à jour le README si nécessaire
- Documentez les nouvelles fonctionnalités
- Incluez des exemples d'usage

### Tests
- Testez avec différents projets PHP
- Vérifiez la compatibilité Windows
- Validez les formats de sortie

## 🔧 Structure du projet

```
phpmigrations/
├── scripts/              # Scripts PowerShell principaux
│   ├── install-rector.ps1
│   ├── analyze-rector-*.ps1
│   └── ...
├── config/              # Configurations Rector
├── templates/           # Modèles de rapports
├── examples/            # Projets d'exemple
├── docs/               # Documentation
└── rector-analyze.ps1  # Script principal
```

## 🏷️ Conventions de nommage

### Fichiers
- Scripts : `action-description.ps1`
- Configs : `rector-phpXX.php`
- Docs : `kebab-case.md`

### Fonctions PowerShell
- PascalCase : `Get-RectorAnalysis`
- Verbes approuvés : Get, Set, New, Remove, etc.

### Variables
- camelCase : `$projectPath`
- Descriptives : `$rectorConfigFile` vs `$config`

## 🧪 Tests

### Tests manuels
```powershell
# Test installation
.\scripts\install-rector.ps1 -ProjectPath ".\examples\sample-php-project"

# Test analyse
.\rector-analyze.ps1 -ProjectPath ".\examples\sample-php-project" -OutputFormat readable

# Test formats
foreach ($format in @("simple", "readable", "detailed", "json")) {
    .\rector-analyze.ps1 -OutputFormat $format
}
```

### Tests automatisés (à venir)
- Unit tests avec Pester
- Integration tests
- Performance tests

## 📋 Checklist PR

- [ ] Code testé sur Windows PowerShell 5.1
- [ ] Code testé sur PowerShell 7+
- [ ] Documentation mise à jour
- [ ] Exemples ajoutés si pertinent
- [ ] Pas de breaking changes (ou documentés)
- [ ] Respect des conventions de nommage

## 🎨 Style de code

### PowerShell
```powershell
# ✅ Bon
function Get-RectorAnalysis {
    param(
        [Parameter(Mandatory=$true)]
        [string]$ProjectPath
    )
    
    try {
        # Logique...
        return $result
    } catch {
        Write-Host "Erreur: $($_.Exception.Message)" -ForegroundColor Red
        throw
    }
}

# ❌ Éviter
function GetAnalysis($path) {
    # Sans gestion d'erreur...
}
```

### Documentation
```markdown
# ✅ Bon
## 🔧 Installation

### Prérequis
- Windows PowerShell 5.1+
- PHP 7.4+

### Étapes
1. Cloner le repo
2. Exécuter l'installation

# ❌ Éviter
Installation: cloner et installer
```

## 🏆 Reconnaissance

Les contributeurs seront mentionnés dans :
- README principal
- Section remerciements
- Release notes

## 📞 Support

- Issues GitHub pour les bugs
- Discussions pour les questions
- Email pour les questions sensibles

## 📄 Licence

En contribuant, vous acceptez que vos contributions soient sous licence MIT.

---

**Merci pour votre contribution ! 🙏**
