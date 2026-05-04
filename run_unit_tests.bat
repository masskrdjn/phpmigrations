@echo off
REM Script pour lancer les tests unitaires / Script to run unit tests

echo Lancement des tests unitaires... / Starting unit tests...
cd /d "%~dp0unit_tests"
composer test
echo.
echo Tests termines. / Tests completed.
pause