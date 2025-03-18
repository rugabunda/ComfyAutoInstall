@echo off
setlocal

echo.
echo   V4.2 Automatic Cloned Comfy Install with Pytorch , Triton and Sage 2 installation script 
echo This is for making a new cloned ComfyUI and installing Pytorch (Stable 2.6 and Nightly 2.7 or 2.8)
echo   It will install Pytorch 2.7 (Nightly) with Cuda 2.4 or Pytorch 2.8 (Nightly) with Cuda 2.6 or 2.8.
echo   NB If you want to use FastFP16 (extra ~10 percent), you will need Cuda 12.6 or 12.8 installed.
echo   NB Sage2 will work on its own with Pytorch 2.7 or 2.8 with Cudas 2.4, 2.6 or 2.8 .
echo.

echo Checking if Visual Studio Build Tools (cl.exe) is in PATH.

@REM Get the PATH environment variable
set "path_dirs=%PATH%"

@REM Initialize a flag to indicate if cl.exe is found
set "found_cl=0"

@REM Iterate through each directory in the PATH
for %%D in ("%path_dirs:;=" "%") do (
    @REM Check if cl.exe exists in the current directory
    if exist "%%D\cl.exe" (
        set "found_cl=1"
        echo cl.exe is found in the PATH at: %%D
        goto :end_check
    )
)

@REM If cl.exe was not found, print a message
if %found_cl% equ 0 (
    echo cl.exe is NOT found in the PATH - recheck your Paths.
	pause
	exit /b 1
)

:end_check


endlocal

echo CL.exe check passed successfully.
echo.
echo Next step: Install Comfy and a Venv for it

@REM ------------------------------------------------------------------------------------------------
@REM Installing ComfyUI and a Venv within it
echo Installing ComfyUI, installing a Venv within it - choose your Python for it

git clone https://github.com/comfyanonymous/ComfyUI
cd ComfyUI
setlocal enabledelayedexpansion

echo.
echo From Comfy github page: "Python 3.13 is supported but using 3.12 is recommended because some custom nodes and their dependencies might not support it yet."
echo.

@REM Step 1: Locate Python installations
set "PYTHON_DIR=C:\Users\%USERNAME%\AppData\Local\Programs\Python"
if not exist "%PYTHON_DIR%" (
    echo No Python installations found in %PYTHON_DIR%.
    exit /b
)

echo Scanning available Python installations...

@REM Step 2: Find installed Python versions
set INDEX=0
for /d %%D in ("%PYTHON_DIR%\Python*") do (
    set /a INDEX+=1
    set "PYTHON_PATHS[!INDEX!]=%%D\python.exe"
    set "PYTHON_BASE[!INDEX!]=%%D"
    echo !INDEX!. %%D
)

if "%INDEX%"=="0" (
    echo No Python installations found.
    exit /b
)

@REM Step 3: Prompt user to select a Python version
set /p CHOICE=Enter the number of the Python version to use for venv: 

if not defined PYTHON_PATHS[%CHOICE%] (
    echo Invalid selection.
    exit /b
)

set "SELECTED_PYTHON=!PYTHON_PATHS[%CHOICE%]!"
set "SELECTED_BASE=!PYTHON_BASE[%CHOICE%]!"

@REM Step 4: Create a new virtual environment
set VENV_NAME=venv


echo Creating virtual environment "%VENV_NAME%" using %SELECTED_PYTHON%...
%SELECTED_PYTHON% -m venv %VENV_NAME%

if not exist "%VENV_NAME%" (
    echo Failed to create virtual environment.
    exit /b
)

@REM Step 5: Copy Include and Libs folders to the Venv (Triton)
echo Copying Include and Libs folders from %SELECTED_BASE% to %VENV_NAME%...
xcopy /E /I /Y "%SELECTED_BASE%\Include" "%VENV_NAME%\Include"
xcopy /E /I /Y "%SELECTED_BASE%\libs" "%VENV_NAME%\libs"

xcopy /E /I /Y "%SELECTED_BASE%\vcruntime140.dll" "%VENV_NAME%\Scripts\"
xcopy /E /I /Y "%SELECTED_BASE%\vcruntime140_1.dll" "%VENV_NAME%\Scripts\"

echo Virtual environment "%VENV_NAME%" created successfully!
echo Include, libs folders and VCRuntime DLL's copied.

call venv\Scripts\activate.bat
if errorlevel 1 (
    echo Failed to activate virtual environment.
 	pause
    exit /b 1
)

python -m pip install --upgrade pip

echo.
echo Venv Activated and Checked
echo Next step: Install PyTorch
echo.
pause



@REM -------------------------------------------------------------------------------------------------
@REM Installing packages for the Venv and requirements for SageAttention including Pytorch
setlocal enabledelayedexpansion


@REM -------------------------------------------------------------------------------------------------

@REM Checking for installled Cuda version and installing latest relevant Pytorch for it
@REM setlocal enabledelayedexpansion command in a batch script is used to enable delayed variable expansion, which allows you to use variables with their values updated at execution time rather than at parse time.
setlocal enabledelayedexpansion

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


@REM Step 4: Remove the dot from CUDA version (convert v12.8 → 128)
set "CLEAN_CUDA=%cuda_version:.=%"


@REM Step 5: Set PyTorch URLs
set "STABLE_URL=https://download.pytorch.org/whl/cu%CLEAN_CUDA%"
set "NIGHTLY_URL=https://download.pytorch.org/whl/nightly/cu%CLEAN_CUDA%"

@REM Step 6: Ask User for Stable or Nightly Build
echo.
echo Choose Stable for Pytorch 2.6 or Nightly for Pytorch 2.7 or 2.8
echo  It will install Pytorch 2.7 (Nightly) with Cuda 2.4 or Pytorch 2.8 (Nightly) with Cuda 2.6 or 2.8.
echo  NB If you want to use FastFP16 (Pytorch 2.7+), you will need Cuda 12.6 or 12.8 installed.
echo  NB Sage2 will work on its own with Pytorch 2.7 or 2.8 with Cudas 2.4, 2.6 or 2.8 .
echo.
echo Choose PyTorch build:
echo [1] Stable
echo [2] Nightly
set /p CHOICE="Enter choice (1 or 2): "

if "%CHOICE%"=="1" (
    set "PYTORCH_BUILD=Stable"
    set "PYTORCH_URL=%STABLE_URL%"
) else if "%CHOICE%"=="2" (
    set "PYTORCH_BUILD=Nightly"
    set "PYTORCH_URL=%NIGHTLY_URL%"
) else (
    echo Invalid choice. Defaulting to Stable.
    set "PYTORCH_BUILD=Stable"
    set "PYTORCH_URL=%STABLE_URL%"
)

@REM Step 7: Install PyTorch
echo.
echo Installing PyTorch %PYTORCH_BUILD% with CUDA %cuda_version%...
echo.

if "%PYTORCH_BUILD%"=="Stable" (
    pip install torch torchvision torchaudio --index-url %PYTORCH_URL%
) else (
    pip install --pre torch torchvision torchaudio --index-url %PYTORCH_URL%
)

echo PyTorch %PYTORCH_BUILD% installation complete.


@REM Step 8: Verify installation
echo.
echo Verifying PyTorch installation...
echo.

python -c "import torch; print(f'PyTorch Version: {torch.__version__}, CUDA Available: {torch.cuda.is_available()}, CUDA Version: {torch.version.cuda}')" 
if !errorlevel! NEQ 0 (
    echo.
    echo PyTorch installation failed. Please check for errors above line 168.
    pause
    exit /b
)

echo PyTorch installation complete and checked
echo Next Step: Install the rest of the requirements
pause



@REM Step 9: Install the rest of the requirements for the Venv, Triton and SageAttention

pip install -r requirements.txt
pip install onnxruntime-gpu
pip install wheel
pip install setuptools
pip install packaging
pip install ninja
pip install "accelerate >= 1.1.1"
pip install "diffusers >= 0.31.0"
pip install "transformers >= 4.39.3"
pip install "setuptools == 70.2.0"
python -m ensurepip --upgrade
@REM python -m pip install --upgrade setuptools


echo.
echo Successfully installed Requirements
echo Next step : Install Triton
echo.
pause

@REM --------------------------------------------------------------------------------------------------
@REM Install Triton Wheel for Triton & install
setlocal enabledelayedexpansion

@REM Ask which version of Triton to install
echo.
echo Choose which version of Triton to install (Nightly might help Nvidia 50xx gpus) :
echo [1] Nightly
echo [2] Stable 
set /p triton_choice="Enter your choice (1/2): "

if "%triton_choice%"=="1" (
    echo Installing latest Nightly Triton version...
    pip install -U --pre triton-windows
) else if "%triton_choice%"=="2" (
    echo Installing latest Stable Triton version...
    pip install triton-windows
) else (
    echo Invalid choice. Skipping Triton installation.
)

pause

@REM Step 12: Deleting Tritons cached files as these can make it fault
setlocal

set "TRITON_CACHE=C:\Users\%USERNAME%\.triton\cache"
set "TORCHINDUCTOR_CACHE=C:\Users\%USERNAME%\AppData\Local\Temp\torchinductor_%USERNAME%\triton"

if exist "%TRITON_CACHE%" (
    echo Deleting .triton cache...
    rmdir /s /q "%TRITON_CACHE%" 2>nul
    mkdir "%TRITON_CACHE%"
    echo .Triton cache cleared.
) else (
    echo .Triton cache folder not found.
)

if exist "%TORCHINDUCTOR_CACHE%" (
    echo Deleting torchinductor cache...
    rmdir /s /q "%TORCHINDUCTOR_CACHE%" 2>nul
    mkdir "%TORCHINDUCTOR_CACHE%"
    echo Torchinductor cache cleared.
) else (
    echo Torchinductor cache folder not found.
)

echo.
echo Successfully installed Triton and caches cleared
echo Next step: Install SageAttention
echo.
pause

@REM --------------------------------------------------------------------------------------------------
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
@REM Make a start bat file for Comfy - fp16fast and sage
setlocal

@REM cd .. to get to ComfyUI folder and install scripts
cd ..
cd ..

@REM Step 1: Define the path for the new batch file
set "new_batch_file=run_comfyui_fp16fast_sage.bat"

@REM Step 2: Create the new Comfy startup batch file
(
echo @echo off
echo cd ComfyUI
echo call venv\Scripts\activate.bat
echo echo Venv Activated
echo .\venv\Scripts\python.exe -s main.py --windows-standalone-build --use-sage-attention --fast fp16_accumulation
echo pause
) > "%new_batch_file%"

@REM Step 3: Check if the new batch file was created successfully
if exist "%new_batch_file%" (
    echo The file %new_batch_file% has been created successfully.
) else (
    echo Failed to create the file %new_batch_file%.
)

@REM --------------------------------------------------------------------------------------------------
@REM Step 1: Define the path for the new batch file non fp16Fast
set "new_batch_file1=run_comfyui_sage.bat"

@REM Step 2: Create the new Comfy startup batch file
(
echo @echo off
echo cd ComfyUI
echo call venv\Scripts\activate.bat
echo echo Venv Activated
echo .\venv\Scripts\python.exe -s main.py --windows-standalone-build --use-sage-attention --fast
echo pause
) > "%new_batch_file1%"

@REM Step 3: Check if the new batch file was created successfully
if exist "%new_batch_file1%" (
    echo The file %new_batch_file1% has been created successfully.
) else (
    echo Failed to create the file %new_batch_file1%.
)

@REM --------------------------------------------------------------------------------------------------
@REM Create a batch file to auto open a CMD window and activate the Venv
@REM Step 1: Define the path for the new batch file
set "new_batch_file2=Activate_Venv.bat"

@REM Step 2: Create the new batch file with the specified content
(
echo @echo off
echo cd ComfyUI\venv
echo call .\Scripts\activate.bat
echo echo Venv Activated
echo cmd.exe /k
) > "%new_batch_file2%"

@REM Step 3: Check if the new batch file was created successfully
if exist "%new_batch_file2%" (
    echo The file %new_batch_file2% has been created successfully.
) else (
    echo Failed to create the file %new_batch_file2%.
)

@REM --------------------------------------------------------------------------------------------------
@REM Create a batch file to update Comfy via git pull
@REM Step 1: Define the path for the new batch file
set "new_batch_file3=Update_Comfy.bat"

@REM Step 2: Create the new batch file with the specified content
(
echo @echo off
echo cd ComfyUI
echo git pull
echo pause
) > "%new_batch_file3%"

@REM Step 3: Check if the new batch file was created successfully
if exist "%new_batch_file3%" (
    echo The file %new_batch_file3% has been created successfully.
) else (
    echo Failed to create the file %new_batch_file3%.
)

echo.
echo Four bat files saved to install folder 
echo   1. ComfyUI start with Sage and fp16Fast
echo   2. ComfyUI start with Sage 
echo   3. Activate the venv for manual input 
echo   4. Update via git pull
echo. 
echo Next Step: Install Comfy Manager
pause

@REM --------------------------------------------------------------------------------------------------
@REM Installing Comfy Manager rather than faffing around 

cd ComfyUI\custom_nodes

git clone https://github.com/ltdrdata/ComfyUI-Manager.git

echo Successfully cloned ComfyUI-Manager


echo.
echo Copy across your extra_model_paths.yaml file and start ComfyUI.
echo.
endlocal
pause
exit /b 1
