# Contributing to Rector PHP Analysis Tools

Thank you for your interest in contributing to this project! 🎉

## 🚀 How to contribute

### Report a bug
1. Check that the bug is not already reported in Issues
2. Create a new Issue with:
   - Clear description of the problem
   - Steps to reproduce
   - PowerShell and PHP version
   - Example error output

### Suggest an improvement
1. Open an Issue to discuss your idea
2. Wait for feedback before developing
3. Follow development guidelines

### Submit code
1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📝 Development guidelines

### PowerShell Scripts
- Use explicit names for functions
- Comment complex code
- Handle errors with try/catch
- Test on PowerShell 5.1 and 7+

### Documentation
- Update README if necessary
- Document new features
- Include usage examples

### Testing
- Test with different PHP projects
- Check Windows compatibility
- Validate output formats

## 🔧 Project structure

```
phpmigrations/
├── scripts/              # Main PowerShell scripts
│   ├── install-rector.ps1
│   ├── analyze-rector-*.ps1
│   └── ...
├── config/              # Rector configurations
├── templates/           # Report templates
├── examples/            # Example projects
├── docs/               # Documentation
└── rector-analyze.ps1  # Main script
```

## 🏷️ Naming conventions

### Files
- Scripts: `action-description.ps1`
- Configs: `rector-phpXX.php`
- Docs: `kebab-case.md`

### PowerShell Functions
- PascalCase: `Get-RectorAnalysis`
- Approved verbs: Get, Set, New, Remove, etc.

### Variables
- camelCase: `$projectPath`
- Descriptive: `$rectorConfigFile` vs `$config`

## 🧪 Testing

### Manual tests
```powershell
# Test installation
.\scripts\install-rector.ps1 -ProjectPath ".\examples\sample-php-project"

# Test analysis
.\rector-analyze.ps1 -ProjectPath ".\examples\sample-php-project" -OutputFormat readable

# Test formats
foreach ($format in @("simple", "readable", "detailed", "json")) {
    .\rector-analyze.ps1 -OutputFormat $format
}
```

### Automated tests (coming soon)
- Unit tests with Pester
- Integration tests
- Performance tests

## 📋 PR Checklist

- [ ] Code tested on Windows PowerShell 5.1
- [ ] Code tested on PowerShell 7+
- [ ] Documentation updated
- [ ] Examples added if relevant
- [ ] No breaking changes (or documented)
- [ ] Naming conventions respected

## 🎨 Code style

### PowerShell
```powershell
# ✅ Good
function Get-RectorAnalysis {
    param(
        [Parameter(Mandatory=$true)]
        [string]$ProjectPath
    )
    
    try {
        # Logic...
        return $result
    } catch {
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
        throw
    }
}

# ❌ Avoid
function GetAnalysis($path) {
    # Without error handling...
}
```

### Documentation
```markdown
# ✅ Good
## 🔧 Installation

### Prerequisites
- Windows PowerShell 5.1+
- PHP 7.4+

### Steps
1. Clone the repo
2. Run installation

# ❌ Avoid
Installation: clone and install
```

## 📚 Documentation standards

### Language support
- **French**: Primary documentation in French
- **English**: Complete English translations for international community
- **Bilingual**: Index and navigation documents support both languages

### Documentation files
- Main guides must have both French and English versions
- Use `-en` suffix for English versions (e.g., `quick-start-en.md`)
- Update both versions when making changes

### Translation guidelines
- Maintain equivalent content structure
- Adapt examples to be culturally neutral
- Keep technical terms consistent between languages
- Update cross-references in both languages

## 🌐 Multi-version PHP support

### Adding new PHP version configurations
1. Create new config file: `config/rector-phpXX.php`
2. Follow existing configuration patterns
3. Update documentation tables in both languages
4. Add corresponding VS Code task if relevant
5. Test with representative PHP projects

### Configuration standards
- Include appropriate PHP version sets
- Add meaningful code quality rules
- Exclude common problematic paths
- Document version-specific features in comments

## 🏆 Recognition

Contributors will be mentioned in:
- Main README (both versions)
- Acknowledgments section
- Release notes

## 📞 Support

- GitHub Issues for bugs
- Discussions for questions
- Email for sensitive inquiries

## 📄 License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

**Thank you for your contribution! 🙏**
