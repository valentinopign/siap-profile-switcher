@echo off
REM ===================================================================
REM  cambiar-siap.bat
REM  Alterna entre perfiles del SIAP en VirtualStore y lo ejecuta
REM ===================================================================

setlocal enabledelayedexpansion
chcp 65001 >nul

REM ============ RUTAS DE CONFIGURACION ===================
set "SIAP_PARENT=%LOCALAPPDATA%\VirtualStore\Program Files (x86)"
set "SIAP_NAME=S.I.Ap"
set "SIAP_EXE=C:\Program Files (x86)\S.I.Ap\AFIP\SIAp.exe"
REM =======================================================

set "SIAP_ACTIVE=!SIAP_PARENT!\!SIAP_NAME!"

REM --- Verificar que SIAP no este corriendo ---
tasklist /FI "IMAGENAME eq SIAp.exe" 2>NUL | find /I "SIAp.exe" >NUL
if not errorlevel 1 (
    echo.
    echo  ERROR: Cerra el SIAP antes de cambiar de perfil.
    echo.
    pause
    exit /b 1
)

REM --- Verificar que existe la carpeta padre ---
if not exist "!SIAP_PARENT!" (
    echo.
    echo  ERROR: No existe la ruta:
    echo  !SIAP_PARENT!
    echo.
    pause
    exit /b 1
)

REM --- Detectar perfil actualmente activo ---
set "ACTUAL="
if exist "!SIAP_ACTIVE!\perfil.txt" (
    set /p ACTUAL=<"!SIAP_ACTIVE!\perfil.txt"
)

REM --- Listar perfiles disponibles ---
echo.
echo === Perfiles SIAP disponibles ===
set N=0
for /d %%D in ("!SIAP_PARENT!\!SIAP_NAME!_*") do (
    set /a N+=1
    set "NAME=%%~nxD"
    set "NAME=!NAME:S.I.Ap_=!"
    set "PERFIL_!N!=!NAME!"
    echo   !N!. !NAME!
)
if !N! EQU 0 (
    echo  No hay perfiles disponibles.
    pause
    exit /b 1
)
if defined ACTUAL (
    echo.
    echo  ^>^> Perfil activo actualmente: [92m!ACTUAL![0m
)

REM --- Obtener target ---
set "TARGET=%~1"
if not "!TARGET!"=="" goto evaluar_target

echo.
set /p "OPT=Numero de perfil a activar (Enter abre el perfil actual): "
if "!OPT!"=="" (
    if defined ACTUAL (
        set "TARGET=!ACTUAL!"
        goto iniciar_siap
    ) else (
        echo  No hay perfil activo para abrir.
        pause
        exit /b 0
    )
)

for %%i in ("!OPT!") do set "TARGET=!PERFIL_%%~i!"

:evaluar_target
if "!TARGET!"=="" (
    echo  Opcion invalida.
    pause
    exit /b 1
)

set "TARGET_DIR=!SIAP_PARENT!\!SIAP_NAME!_!TARGET!"

REM --- Verificar que existe el target ---
if not exist "!TARGET_DIR!" (
    echo.
    echo  ERROR: No existe el perfil "!TARGET!"
    echo  Carpeta esperada: !TARGET_DIR!
    pause
    exit /b 1
)

REM --- Ya esta activo? ---
if /i "!ACTUAL!"=="!TARGET!" (
    echo.
    echo  El perfil "!TARGET!" ya esta activo.
    goto iniciar_siap
)

REM --- Si hay perfil activo, archivarlo ---
set "ARCHIVADO="
if exist "!SIAP_ACTIVE!" (
    if "!ACTUAL!"=="" (
        echo.
        echo  ATENCION: Hay una carpeta !SIAP_NAME! activa pero sin marcador perfil.txt
        echo  Crea un perfil.txt adentro con el nombre que corresponda.
        pause
        exit /b 1
    )
    echo  Guardando perfil activo "!ACTUAL!"...
    ren "!SIAP_ACTIVE!" "!SIAP_NAME!_!ACTUAL!"
    if errorlevel 1 (
        echo  ERROR al renombrar el perfil activo.
        pause
        exit /b 1
    )
    set "ARCHIVADO=1"
)

REM --- Activar target ---
echo  Activando "!TARGET!"...
ren "!TARGET_DIR!" "!SIAP_NAME!"
if errorlevel 1 (
    echo  ERROR al activar el perfil "!TARGET!".
    REM --- Rollback: restaurar el perfil que habiamos archivado ---
    if defined ARCHIVADO (
        echo  Revirtiendo: restaurando perfil "!ACTUAL!"...
        ren "!SIAP_PARENT!\!SIAP_NAME!_!ACTUAL!" "!SIAP_NAME!"
        if errorlevel 1 (
            echo  ATENCION: No se pudo revertir. Perfil archivado como "!SIAP_NAME!_!ACTUAL!".
        )
    )
    pause
    exit /b 1
)

REM --- Reescribir marcador ---
>"!SIAP_ACTIVE!\perfil.txt" echo !TARGET!
echo.
echo  ====================================
echo   Listo. Perfil activo: !TARGET!
echo  ====================================
echo.

:iniciar_siap
REM --- Iniciar SIAP automaticamente ---
if exist "!SIAP_EXE!" (
    echo  Iniciando SIAP...
    start "" "!SIAP_EXE!"
) else (
    echo  ADVERTENCIA: No se encontro el ejecutable original del SIAP.
    echo  Ruta buscada: !SIAP_EXE!
    echo  Debera iniciarlo manualmente.
    pause
)

endlocal