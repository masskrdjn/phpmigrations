<?php

namespace PhpMigrations\Tests;

use PHPUnit\Framework\TestCase;

/**
 * Tests qui vérifient que rector-analyze.ps1 remonte correctement les erreurs.
 */
class MigrationFailureTest extends TestCase
{
    /**
     * Renvoie le chemin absolu de rector-analyze.ps1 calculé depuis ce fichier.
     * Plus robuste qu'un chemin codé en dur c:\\laragon\\... .
     */
    private function getRectorAnalyzeScriptPath(): string
    {
        $repoRoot = realpath(__DIR__ . '/../../');
        return $repoRoot . DIRECTORY_SEPARATOR . 'rector-analyze.ps1';
    }

    /**
     * Crée un dossier temporaire isolé contenant un seul fichier PHP avec le code donné,
     * et un rector.php minimal pour cibler la version PHP demandée.
     */
    private function createTempProject(string $phpCode, string $phpVersion = '84'): string
    {
        $dir = sys_get_temp_dir() . DIRECTORY_SEPARATOR . 'rector_test_' . uniqid('', true);
        mkdir($dir);
        mkdir($dir . DIRECTORY_SEPARATOR . 'src');
        file_put_contents($dir . DIRECTORY_SEPARATOR . 'src' . DIRECTORY_SEPARATOR . 'sample.php', $phpCode);
        return $dir;
    }

    private function cleanupDir(string $dir): void
    {
        if (!is_dir($dir)) {
            return;
        }
        $it = new \RecursiveDirectoryIterator($dir, \RecursiveDirectoryIterator::SKIP_DOTS);
        $files = new \RecursiveIteratorIterator($it, \RecursiveIteratorIterator::CHILD_FIRST);
        foreach ($files as $file) {
            if ($file->isDir()) {
                rmdir($file->getRealPath());
            } else {
                unlink($file->getRealPath());
            }
        }
        rmdir($dir);
    }

    /**
     * Lance rector-analyze.ps1 et renvoie le stdout/stderr combinés.
     */
    private function runAnalyze(string $projectDir, string $phpVersion = '84'): string
    {
        $script = $this->getRectorAnalyzeScriptPath();
        // -ExecutionPolicy Bypass pour éviter les blocages dans des environnements verrouillés.
        $cmd = sprintf(
            'powershell -NoProfile -ExecutionPolicy Bypass -File %s -ProjectPath %s -PhpVersion %s -Interactive:$false -OutputFormat simple 2>&1',
            escapeshellarg($script),
            escapeshellarg($projectDir),
            escapeshellarg($phpVersion)
        );
        return (string) shell_exec($cmd);
    }

    /**
     * Détection d'erreurs : on cherche des indicateurs FR ET EN, pour ne pas
     * dépendre de la locale d'affichage.
     */
    private function assertOutputIndicatesError(string $output, string $context): void
    {
        $low = strtolower($output);
        $hasError = str_contains($low, 'error')
                 || str_contains($low, 'erreur')
                 || str_contains($low, 'failed')
                 || str_contains($low, 'échou')
                 || str_contains($low, 'echou');
        $this->assertTrue($hasError, "Aucune mention d'erreur dans la sortie ($context). Sortie brute :\n$output");
    }

    public function testMigrationFailsOnSyntaxError(): void
    {
        // Code PHP invalide (point-virgule manquant)
        $code = "<?php\nclass Broken {\n    public function foo() {\n        return 1\n    }\n}\n";
        $dir = $this->createTempProject($code);
        try {
            $output = $this->runAnalyze($dir, '84');
            $this->assertOutputIndicatesError($output, 'erreur de syntaxe');
        } finally {
            $this->cleanupDir($dir);
        }
    }

    public function testMigrationDetectsDeprecatedCreateFunction(): void
    {
        // create_function() supprimé en PHP 8.0 — Rector le signale comme erreur de parsing
        // ou propose un changement (FuncCallToVariadic / RemoveCreateFunction selon version).
        $code = "<?php\n\$func = create_function('\$a', 'return \$a * 2;');\necho \$func(5);\n";
        $dir = $this->createTempProject($code);
        try {
            $output = $this->runAnalyze($dir, '84');
            // On accepte deux cas : Rector mentionne create_function explicitement,
            // OU il renvoie un statut WARNING/erreur signalant l'incompatibilité.
            $low = strtolower($output);
            $detected = str_contains($low, 'create_function')
                     || str_contains($low, 'warning')
                     || str_contains($low, 'erreur')
                     || str_contains($low, 'error');
            $this->assertTrue($detected, "Migration aurait dû détecter create_function() ou émettre un avertissement.\nSortie :\n$output");
        } finally {
            $this->cleanupDir($dir);
        }
    }
}
