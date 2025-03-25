@echo off
setlocal enabledelayedexpansion

:: Get date in UK format (dd-MM-yyyy)
for /f "tokens=1-3 delims=/ " %%a in ('echo %date%') do set "UK_DATE=%%c-%%b"

:: Remove leading space from time to avoid misalignment
set "cleanTime=%time: =0%"

:: Extract hour and minute (without seconds or milliseconds)
for /f "tokens=1,2 delims=:." %%a in ("%cleanTime%") do (
    set "hour24=%%a"
    set "minute=%%b"
)

:: Ensure two-digit hour and minute
if !hour24! lss 10 set hour24=0!hour24!
if !minute! lss 10 set minute=0!minute!

:: Format the time in 24-hour format
set "UK_TIME=!hour24!-!minute!"

:: Define output log file with date and time
set "LOGFILE=output_log_!UK_DATE!_!UK_TIME!.txt"

:: Clear previous log (optional)
:: if exist %LOGFILE% del %LOGFILE%



:: Run commands and append their outputs to the log file
for %%i in ("%cd%") do set "folderPath=%%~fi"

:: Write the current directory path to a text file
echo Run from:  >> %LOGFILE% 
echo !folderPath! >> %LOGFILE%
echo. >> %LOGFILE%

echo.
echo GPU Model and VRam: >> %LOGFILE% 
nvidia-smi --query-gpu=name,memory.total --format=csv,noheader >> %LOGFILE% 
echo. >> %LOGFILE%

echo iGPU Model: GPU 1 >> %LOGFILE% 
echo VRAM        Driver Version   iGPU >> %LOGFILE% 
wmic path win32_VideoController get Name, AdapterRAM, DriverVersion | findstr /I "Intel AMD" >> %LOGFILE%
echo. >> %LOGFILE%

echo Processor: >> %LOGFILE%
wmic cpu get Name | findstr /V "Name" >> %LOGFILE%
echo. >> %LOGFILE%

echo Memory Info: >> %LOGFILE%
systeminfo | findstr /C:"Total Physical Memory" /C:"Available Physical Memory" >> %LOGFILE%
echo. >> %LOGFILE%

echo Basic System Information: >> %LOGFILE%
systeminfo | findstr /B /C:"OS Name" /C:"OS Version" >> %LOGFILE%
echo. >> %LOGFILE%

echo Pip Cache Info: >> %LOGFILE%
for /f "tokens=1,* delims=:" %%A in ('pip cache info') do (
    set "line=%%A"
    echo !line! | findstr /I "Package index page cache" >nul && set "cache_size=%%B"
)
(
    echo Package Index Cache Size: !cache_size!
) >> %LOGFILE%
echo. >> %LOGFILE%
   
echo System CUDA Version >> %LOGFILE%
for /f "tokens=2 delims= " %%A in ('nvcc --version ^| findstr /C:"Build"') do (
    for /f "tokens=2 delims=_" %%B in ("%%A") do (
        for /f "tokens=1,2 delims=." %%C in ("%%B") do (
            echo Cuda %%C.%%D >> %LOGFILE%
        )
    )
)
echo. >> %LOGFILE%

echo CUDA Variables set to Variable Names: >> %LOGFILE%
for /f "tokens=1,* delims==" %%A in ('set') do (
    echo %%A | findstr /I "cuda" >nul && echo %%A=%%B  >> %LOGFILE% 2>&1
)
echo. >> %LOGFILE%

echo CUDA Environment Variables: System and User >> %LOGFILE%
for %%A in ("%PATH:;=" "%") do (
    echo %%A | findstr /I "cuda" >nul && (
        set "var=%%~A"
        echo !var! >> %LOGFILE%
    )
)
echo. >> %LOGFILE%



echo. >> %LOGFILE%
echo Microsoft Visual Studio Build Tools Environment Variables: >> %LOGFILE%

:: Check for Visual Studio installation using vswhere
for /f "tokens=*" %%A in ('"C:\Program Files (x86)\Microsoft Visual Studio\Installer\vswhere.exe" -latest -prerelease -all -products * -requires Microsoft.VisualStudio.Workload.VCTools -property installationPath') do (
    set "VS_INSTALL_PATH=%%A"
)

:: If VS_INSTALL_PATH is found, extract key environment variables
if defined VS_INSTALL_PATH (
    echo VSINSTALLDIR=!VS_INSTALL_PATH! >> %LOGFILE%
    echo VCToolsInstallDir=!VS_INSTALL_PATH!\VC\Tools\MSVC >> %LOGFILE%
    echo MSBuildSDKsPath=!VS_INSTALL_PATH!\MSBuild\Current\Bin >> %LOGFILE%
)

:: Check system and user variables manually
for /f "tokens=1,* delims==" %%A in ('set') do (
    echo %%A | findstr /I "VS VC VCTools MSBuild VisualStudio WindowsSDK BuildTools" >nul && (
        echo %%A=%%B >> %LOGFILE%
    )
)


@REM Get the PATH environment variable
set "path_dirs=%PATH%"

@REM Initialize a flag to indicate if cl.exe is found
set "found_cl=0"

@REM Iterate through each directory in the PATH
for %%D in ("%path_dirs:;=" "%") do (
    @REM Remove surrounding quotes from %%D (if present)
    set "clean_path=%%~D"

    @REM Check if cl.exe exists in the current directory
    if exist "!clean_path!\cl.exe" (
        set "found_cl=1"
        echo MSVC Compiler cl.exe Path=!clean_path! >> %LOGFILE%
        goto :end_check
    )
)
@REM If cl.exe was not found, print a message
if %found_cl% equ 0 (
    echo cl.exe is NOT found in the PATH - recheck your Paths. >> %LOGFILE%
	pause
)
:end_check
echo. >> %LOGFILE%
echo. >> %LOGFILE%


echo System Python Version >> %LOGFILE%
python --version >> %LOGFILE% 2>&1
echo. >> %LOGFILE%

:: Log header
echo. >> %LOGFILE%
echo Python Environment Variables and Paths: >> %LOGFILE%
echo. >> %LOGFILE%

:: Check system and user environment variables for Python-related paths
for /f "tokens=1,* delims==" %%A in ('set') do (
    echo %%A | findstr /I "python py" >nul && (
        echo %%A=%%B >> %LOGFILE%
    )
)

:: Locate Python executables in the system PATH
echo. >> %LOGFILE%
echo Searching for Python Executables in PATH: >> %LOGFILE%
for %%A in (python.exe python3.exe py.exe) do (
    for %%B in (%%~$PATH:A) do (
        echo %%A found at: %%B >> %LOGFILE%
    )
)

:: Check common Python installation directories
echo. >> %LOGFILE%
echo Checking Common Python Install Paths: >> %LOGFILE%
for %%D in (
    "%LOCALAPPDATA%\Programs\Python"
    "%PROGRAMFILES%\Python*"
    "%PROGRAMFILES(x86)%\Python*"
    "%USERPROFILE%\AppData\Local\Programs\Python"
    "C:\Python*"
) do (
    if exist %%D (
        echo Found: %%D >> %LOGFILE%
    )
)

echo. >> %LOGFILE%


:: Check if the python_embeded folder exists
if not exist ".\python_embeded\" (
    goto :venv
)

echo Embedded Python Version >> %LOGFILE%
.\python_embeded\python.exe --version >> %LOGFILE% 2>&1
echo. >> %LOGFILE%

echo Embedded Torch Version >> %LOGFILE%
.\python_embeded\python.exe -c "import torch; print(torch.__version__)" >> %LOGFILE% 2>&1
echo. >> %LOGFILE%

echo Embedded Install Details >> %LOGFILE%
cd "python_embeded\Lib\site-packages" && pip list >> "..\..\..\%LOGFILE%" 2>&1

exit
:: Continue execution at :venv
:venv


:: Check if the .venv folder exists in Desktop install
if not exist ".venv" (
    echo Embedded Python folder not found. Jumping to venv... >> %LOGFILE%
    goto :venv2
)

call .venv\Scripts\activate.bat
echo Venv Activated

echo Venv Python Version >> %LOGFILE%
.\.venv\Scripts\python.exe --version >> %LOGFILE% 2>&1
echo. >> %LOGFILE%

echo Venv Torch and Cuda Version >> %LOGFILE%
.\.venv\Scripts\python.exe -c "import torch; print(torch.__version__)" >> %LOGFILE% 2>&1
echo. >> %LOGFILE%

echo Venv Install Details >> %LOGFILE%
cd .\.venv\Lib\site-packages 
pip list >> "..\..\..\%LOGFILE%"

Deactivate

exit
:: Continue execution at :venv
:venv2


call ComfyUI\venv\Scripts\activate.bat
echo Venv Activated

echo Venv Python Version >> %LOGFILE%
.\ComfyUI\venv\Scripts\python.exe --version >> %LOGFILE% 2>&1
echo. >> %LOGFILE%

echo Venv Torch and Cuda Version >> %LOGFILE%
.\ComfyUI\venv\Scripts\python.exe -c "import torch; print(torch.__version__)" >> %LOGFILE% 2>&1
echo. >> %LOGFILE%

echo Venv Install Details >> %LOGFILE%
cd "ComfyUI\venv\Lib\site-packages" && pip list >> "..\..\..\..\%LOGFILE%"

Deactivate



:: Show completion message
echo Log saved to %LOGFILE%
endlocal
pause