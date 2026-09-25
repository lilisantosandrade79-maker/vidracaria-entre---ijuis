@echo off
setlocal EnableExtensions EnableDelayedExpansion

color 0A

echo ============================================================
echo  VIDRACARIA ENTRE-IJUIS - CORRECAO E GERACAO DO APK
echo ============================================================
echo.
echo Este arquivo corrige o problema de Java/Gradle do projeto.
echo Ele procura o JDK 21, instala se necessario, fixa o Gradle
echo do projeto no JDK 21 e gera o APK de teste.
echo.

set "PROJECT=%~dp0"
if not exist "%PROJECT%\android" set "PROJECT=%USERPROFILE%\Downloads\Vidracaria_Entre-Ijuis-Android\vei_android_project"
if not exist "%PROJECT%" set "PROJECT=%USERPROFILE%\Downloads\Vidracaria_Entre-Ijuís-Android\vei_android_project"
if not exist "%PROJECT%" (
    echo ERRO: nao encontrei o projeto em:
    echo %USERPROFILE%\Downloads\Vidracaria_Entre-Ijuis-Android\vei_android_project
    echo.
    echo Coloque este arquivo .BAT na pasta do projeto e tente novamente,
    echo ou avise para eu ajustar o caminho.
    pause
    exit /b 1
)

cd /d "%PROJECT%"

echo [1/5] Procurando JDK 21...
set "JAVA_HOME="

for /d %%D in ("C:\Program Files\Microsoft\jdk-21*") do if exist "%%~fD\bin\java.exe" set "JAVA_HOME=%%~fD"
for /d %%D in ("C:\Program Files\Eclipse Adoptium\jdk-21*") do if exist "%%~fD\bin\java.exe" set "JAVA_HOME=%%~fD"
for /d %%D in ("C:\Program Files\Java\jdk-21*") do if exist "%%~fD\bin\java.exe" set "JAVA_HOME=%%~fD"

if not defined JAVA_HOME (
    echo JDK 21 nao encontrado. Instalando Microsoft OpenJDK 21...
    where winget >nul 2>&1
    if errorlevel 1 (
        echo ERRO: o Windows nao possui o WinGet.
        echo Instale o App Installer da Microsoft e execute este arquivo novamente.
        pause
        exit /b 1
    )
    winget install --id Microsoft.OpenJDK.21 -e --accept-source-agreements --accept-package-agreements
    echo.
    echo Procurando o JDK 21 instalado...
    for /d %%D in ("C:\Program Files\Microsoft\jdk-21*") do if exist "%%~fD\bin\java.exe" set "JAVA_HOME=%%~fD"
    for /d %%D in ("C:\Program Files\Eclipse Adoptium\jdk-21*") do if exist "%%~fD\bin\java.exe" set "JAVA_HOME=%%~fD"
    for /d %%D in ("C:\Program Files\Java\jdk-21*") do if exist "%%~fD\bin\java.exe" set "JAVA_HOME=%%~fD"
)

if not defined JAVA_HOME (
    echo ERRO: nao consegui localizar o JDK 21 depois da instalacao.
    echo.
    echo Abra um novo CMD e execute: java -version
    pause
    exit /b 1
)

set "PATH=%JAVA_HOME%\bin;%PATH%"
echo JDK escolhido: %JAVA_HOME%
"%JAVA_HOME%\bin\java.exe" -version
if errorlevel 1 (
    echo ERRO ao executar o JDK 21.
    pause
    exit /b 1
)

echo.
echo [2/5] Fixando o Gradle para usar este JDK 21...
if not exist "android\gradle.properties" type nul > "android\gradle.properties"
powershell -NoProfile -ExecutionPolicy Bypass -Command "$p='android\gradle.properties'; $lines=@(); if(Test-Path $p){$lines=Get-Content -LiteralPath $p | Where-Object {$_ -notmatch '^\s*org\.gradle\.java\.home\s*='}}; $j=$env:JAVA_HOME.Replace('\','/'); Set-Content -LiteralPath $p -Value ($lines + ('org.gradle.java.home='+$j)) -Encoding UTF8"

if not exist "node_modules" (
    echo.
    echo [3/5] node_modules nao encontrado. Executando npm install...
    call npm install
    if errorlevel 1 goto :buildfail
) else (
    echo [3/5] node_modules ja existe. OK.
)

echo.
echo [4/5] Sincronizando o Android...
if not exist "android\gradlew.bat" (
    echo Plataforma Android ainda nao existe. Criando agora...
    call npx cap add android
    if errorlevel 1 goto :buildfail
)
call npx cap sync android
if errorlevel 1 goto :buildfail

cd /d "%PROJECT%\android"

echo.
echo [5/5] Gerando o APK de teste...
call gradlew.bat --stop >nul 2>&1
call gradlew.bat assembleDebug
if errorlevel 1 goto :buildfail

set "APK=%PROJECT%\android\app\build\outputs\apk\debug\app-debug.apk"
echo.
echo ============================================================
echo  CONCLUIDO: APK GERADO COM SUCESSO
echo ============================================================
echo.
echo Arquivo:
echo %APK%
echo.
if exist "%APK%" (
    echo Abrindo a pasta do APK...
    explorer /select,"%APK%"
) else (
    echo AVISO: o build terminou, mas o APK nao foi encontrado no caminho esperado.
)
pause
exit /b 0

:buildfail
echo.
echo ============================================================
echo  O BUILD NAO TERMINOU.
echo ============================================================
echo.
echo O erro acima e o erro real. Nao feche esta janela.
echo Tire uma foto desta tela e envie aqui.
pause
exit /b 1
