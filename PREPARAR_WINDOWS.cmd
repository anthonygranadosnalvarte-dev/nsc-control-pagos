@echo off
setlocal
cd /d "%~dp0"
where flutter >nul 2>nul
if errorlevel 1 (
  echo No se encuentra Flutter. Instala el SDK y agregalo al PATH.
  echo Cierra y vuelve a abrir VS Code despues de instalarlo.
  pause
  exit /b 1
)
call flutter create --project-name nsc_control_escolar --platforms=android,ios,web,windows .
if errorlevel 1 goto error
call flutter pub get
if errorlevel 1 goto error
call dart format lib test
if errorlevel 1 goto error
call flutter analyze
if errorlevel 1 goto error
call flutter test
if errorlevel 1 goto error
echo Preparacion terminada. Para probar: flutter run -d chrome
pause
exit /b 0
:error
echo Hay un error. Copia el resultado de esta ventana para revisarlo.
pause
exit /b 1
