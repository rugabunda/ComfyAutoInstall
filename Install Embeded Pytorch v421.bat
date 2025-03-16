@echo off

echo.
echo   V4.2 Automatic Nightly 2.7/2.8 Pytorch , Triton and Sage 2 installation script 
echo This is NOT for an existing Portable build, it is for converting a new Portable to Nightly Pytorch 2.7 / 2.8
echo   It will install Pytorch 2.7 (Nightly) with Cuda 2.4 or Pytorch 2.8 (Nightly) with Cuda 2.6 or 2.8.
echo   NB If you want to use FastFP16 (extra ~10 percent), you will need Cuda 12.6 or 12.8 installed.
echo   NB Sage2 will work on its own with Pytorch 2.7 or 2.8 with Cudas 2.4, 2.6 or 2.8 .
echo.
pause

cd ComfyUI

@REM Path to ComfyUI's custom_nodes folder (relative to the script location)
set "CUSTOM_NODES=%custom_nodes"

@REM Check if custom_nodes folder exists(ie looking at the right folder level)
if not exist "%CUSTOM_NODES%" (
    echo Custom nodes folder not found at %CUSTOM_NODES%
	pause
    goto :start_comfy
)

@REM Check for any custom nodes excluding _pycache_, example_node.py.example, and websocket_image_save.py
set "found_custom_nodes=false"
for /f "delims=" %%i in ('dir /b "%CUSTOM_NODES%"') do (
    if /i not "%%i"=="__pycache__" (
        if /i not "%%i"=="example_node.py.example" (
            if /i not "%%i"=="websocket_image_save.py" (
                set "found_custom_nodes=true"
            )
        )
    )
)

@REM If any other files or node folders are found, exit
if "%found_custom_nodes%"=="true" (
    echo.
    echo Detected custom nodes in %CUSTOM_NODES%
    echo Exiting Install script - it is for new installs not existing ones.
	pause
    exit /b
)

:start_comfy

cd ..

@REM Checking for installled Cuda version and installing latest relevant Pytorch for it
@REM setlocal enabledelayedexpansion command in a batch script is used to enable delayed variable expansion, which allows you to use variables with their values updated at execution time rather than at parse time.
setlocal enabledelayedexpansion


@REM List installed CUDA versions
@REM Step 1: Get the CUDA version using nvcc --version
 for /f "tokens=5 delims= " %%A in ('nvcc --version ^| findstr /C:"release"') do (
    for /f "tokens=1 delims=," %%B in ("%%A") do set cuda_version=%%B
)

@REM Stp 2: Extract major version
for /f "tokens=1 delims=." %%a in ("%cuda_version%") do set cuda_major=%%a

@REM Step 3: Extract minor version
for /f "tokens=2 delims=." %%b in ("%cuda_version%") do set cuda_minor=%%b
set cuda_version=!cuda_major!.!cuda_minor!
echo.
echo Detected CUDA Version: %cuda_version%
echo.

@REM Step 4: Remove the dot from CUDA version (convert 12.8 → 128)
set "CLEAN_CUDA=%cuda_version:.=%"

pause

@REM Install Pytorch with system Cuda
cd update
..\python_embeded\python.exe -s -m pip uninstall torch torchvision torchaudio
..\python_embeded\python.exe -s -m pip install --pre torch torchvision torchaudio --index-url https://download.pytorch.org/whl/nightly/cu%CLEAN_CUDA%
..\python_embeded\python.exe -s -m pip install "setuptools == 70.2.0"
echo.
echo Installed older version of Setuptools, as some permutations of installs with
echo  newer Setuptools will stop installation of Sage (setuptools v70.2.0 installed)
echo.
pause

@REM --------------------------------------------------------------------------------------------------
@REM Step 1: Define the path for the new Update file
set "new_batch_file1=update_comfyui_and_python_dependencies.bat"

@REM Step 2: Create the new Comfy startup batch file
(
echo call update_comfyui.bat nopause
echo ..\python_embeded\python.exe -s -m pip install --upgrade --pre torch torchvision torchaudio --extra-index-url https://download.pytorch.org/whl/nightly/cu%CLEAN_CUDA% -r ../ComfyUI/requirements.txt pygit2
) > "%new_batch_file1%"

@REM Step 3: Check if the new batch file was created successfully
if exist "%new_batch_file1%" (
    echo The file %new_batch_file1% has been created successfully.
) else (
    echo Failed to create the file %new_batch_file1%.
)

@REM Install Triton
@REM Ask which version of Triton to install
echo.
echo Choose which version of Triton to install (Nightly might help Nvidia 50xx gpus) :
echo [1] Nightly
echo [2] Stable 
set /p triton_choice="Enter your choice (1/2): "

if "%triton_choice%"=="1" (
    echo Installing latest Nightly Triton version...
    ..\python_embeded\python.exe -s -m pip install -U --pre triton-windows
) else if "%triton_choice%"=="2" (
    echo Installing latest Stable Triton version...
    ..\python_embeded\python.exe -s -m pip install triton-windows
) else (
    echo Invalid choice. Skipping Triton installation.
)

pause

@REM Set variables to Download Include and Libs folders 
cd ..
set "URL=https://github.com/woct0rdho/triton-windows/releases/download/v3.0.0-windows.post1/python_3.12.7_include_libs.zip"
set "ZIP_FILE=python_libs.zip"
set "DEST_FOLDER=python_embeded"

@REM Download 
echo Downloading file...
curl -L "%URL%" -o "%ZIP_FILE%"

@REM Extract using tar
echo Extracting file...
tar -xf "%ZIP_FILE%" -C "%DEST_FOLDER%"

@REM Delete ZIP file after extraction
echo Cleaning up...
del "%ZIP_FILE%"

@REM Install SageAttention
echo Choose which version of SageAttention to install:
@REM echo SageAttention v1 (compatible with python>=3.9, torch>=2.3.0, triton>=2.3.0)
@REM echo SageAttention v2 (compatible with python>=3.9 , torch>=2.3.0 , triton>=3.0.0, CUDA:>=12.8 for Blackwell, >=12.4 for fp8 support on Ada, >=12.3 for fp8 support on Hopper, >=12.0 for Ampere)
echo.
echo [1] SageAttention v1
echo [2] SageAttention v2
set /p choice="Enter your choice (1 or 2): "

if "%choice%"=="1" (
    echo Installing SageAttention v1...
    cd venv
    pip install sageattention==1.0.6
    cd ..
    echo Successfully installed SageAttention v1.
    echo.
    pause
) else if "%choice%"=="2" (
    echo Installing SageAttention v2...
    cd venv
    git clone https://github.com/thu-ml/SageAttention
    cd SageAttention
    set MAX_JOBS=4
    pip install .
    cd ..
    rmdir /s /q SageAttention
    echo Successfully installed SageAttention v2 and cleaned up.
    echo.
    pause
) else (
    echo Invalid choice. Installation aborted.
    pause
    exit /b
)


@REM --------------------------------------------------------------------------------------------------
@REM Define the path for the new Startup script for Pytorch 12.7
set "new_batch_file=run_comfyui_fp16fast_sage.bat"

@REM Step 2: Create the new Comfy startup batch file
(
echo .\python_embeded\python.exe -s ComfyUI\main.py --use-sage-attention --windows-standalone-build --fast fp16_accumulation
echo pause
) > "%new_batch_file%"

@REM Step 3: Check if the new batch file was created successfully
if exist "%new_batch_file%" (
    echo The file %new_batch_file% has been created successfully.
) else (
    echo Failed to create the file %new_batch_file%.
)

@REM --------------------------------------------------------------------------------------------------
@REM Installing Comfy Manager rather than faffing around 
echo.
echo Installing Comfy Manager
cd ComfyUI\custom_nodes
git clone https://github.com/ltdrdata/ComfyUI-Manager.git
echo Successfully cloned ComfyUI-Manager
echo.
echo Copy across your extra_model_paths.yaml file and start ComfyUI.


@REM Update the Install - via Update ComfyUI amd Python Dependencies script
cd ..
cd ..
cd update
..\python_embeded\python.exe .\update.py ..\ComfyUI\
if exist update_new.py (
  move /y update_new.py update.py
  echo Running updater again since it got updated.
  ..\python_embeded\python.exe .\update.py ..\ComfyUI\ --skip_self_update
)
if "%~1"=="" pause

echo.
echo Comfy and Python requirements updated 
pause

endlocal

exit /b