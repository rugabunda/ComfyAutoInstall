The 2x version4 scripts are for 

1. Converting an empty/new Comfy Portable install to one with Triton 2 and Sage 2 within it to make videos as quickly as possible
2. Making a brand new cloned version of Comfy, making a venv within and install Triton 2 and Sage 2

   As the scripts are run, checks are made (done my best to idiot proof them)
   As they progress, they will give you choices - Python to install, Pytorch stable or Nightly, Triton version, Sage Attention version.
   As each part installs, it will delete the folder it used to give a clean install.
   At the end of each script, it will make bat files to run and update the install

NB: Please read through the scripts on the Github links to ensure you are happy before using it. I take no responsibility as to its use or misuse. Secondly, these use Nightly builds - the versions change and with it the possibility that they break, please don't ask me to fix what I can't. If you are outside of the recommended settings/software, then you're on your own.
To repeat this, these are nightly builds, they might break and the whole install is setup for nightlies ie don't use it for everything
Performance: Tests with a Portable upgraded to Pytorch 2.8, Cuda 12.8, 35steps with Wan Blockswap on (20), pic render size 848x464, videos are interpolated as well: 
1. SDPA :  19m 28s @ 33.40 s/it
2. SageAttn2 :  12m 30s @ 21.44 s/it
3. SageAttn2 + FP16Fast :  10m 37s @ 18.22 s/it
4. SageAttn2 + FP16Fast + Torch Compile (Inductor, Max Autotune No CudaGraphs) :  8m 45s @ 15.03 s/it
5. SageAttn2 + FP16Fast + Teacache + Torch Compile (Inductor, Max Autotune No CudaGraphs) : 6m 53s @ 11.83 s/it
   
MSi 4090 with 64GB ram on Windows 11
The above are not a commentary on Quality of output at any speed
The torch compile first run is slow as it carries out test, it only gets quicker

**Recommended Software / Settings**
On the Cloned version - choose Nightly to get the new Pytorch (not much point otherwise)

Cuda 12.6 or 12.8 with the Nightly Pytorch 2.7/8 , Cuda 12.4 works but no FP16Fast

Python 3.12.x

Triton (Stable)

SageAttention2

Prerequisites - note recommended above

I previously posted scripts to install SageAttention for Comfy portable and to make a new Clone version. Read them for the pre-requisites.

https://www.reddit.com/r/StableDiffusion/comments/1iyt7d7/automatic_installation_of_triton_and/

https://www.reddit.com/r/StableDiffusion/comments/1j0enkx/automatic_installation_of_triton_and/

You will need the pre-requisites ...

MSVC installed and Pathed,

Cuda Pathed

Python 3.12.x (no idea if other versions work)

Pics for Paths : https://github.com/Grey3016/ComfyAutoInstall/blob/main/README.md

**Important Notes on Pytorch 2.7 and 2.8**
The new v2.7/2.8 Pytorch brings another ~10% speed increase to the table with FP16Fast
Pytorch 2.7 and 2.8 give you FP16Fast - but you need Cuda 2.6 or 2.8, if you use lower then it doesn't work.
Using Cuda 12.6 or Cuda 12.8 will install a nightly Pytorch 2.8
Using Cuda 12.4 will install a nightly Pytorch 2.7 (can still use SageAttention 2 though)

**Instructions for Portable Version - use a new empty, freshly unzipped portable version . Choice of Triton and SageAttention versions, can also be used on the Nightly Comfy for the 5000 series :**
Download Script & Save as Bat :
Download the lastest Comfy Portable (currently v0.3.26) : https://github.com/comfyanonymous/ComfyUI
Save the script (linked aboce) as a bat file and place it in the same folder as the run_gpu bat file
Start via the new run_comfyui_fp16fast_cage.bat  file - double click (not CMD)
Let it update itself and fully fetch the ComfyRegistry data
Close it down
Restart it
Manually update it and its Pythons dependencies from that bat file in the Update folder
Note: it changes the Update script to pull from the Nightly versions
Note: I can't guarantee it works with a a 5000 series card, as I don't have one

**Instructions to make a new Cloned Comfy with Venv and choice of Python, Triton and SageAttention versions.**
Download Script & Save as Bat :
Save the script linked as a bat file and place it in the folder where you wish to install it
Start via the new run_comfyui_fp16fast_cage.bat  file - double click (not CMD)
Let it update itself and fully fetch the ComfyRegistry data
Close it down
Restart it
Manually update it from that Update bat file

**Why Won't It Work ?**
The scripts were built from manually carrying out the steps - reasons that it'll go tits up on the Sage compiling stage -
Winging it
Not following instructions / prerequsities / Paths
Cuda in the install does not match your Pathed Cuda, Sage Compile will fault
SetupTools version is too high (I've set it to v70.2, it should be ok up to v75.8.2)
Version updates - this stopped the last scripts from working if you updated, I can't stop this and I can't keep supporting it in that way. I will refer to this when it happens and this isn't read.
No idea about 5000 series - use the Comfy Nightly 

**Where do they download from ?**
Triton wheel for Windows > https://github.com/woct0rdho/triton-windows
SageAttention > https://github.com/thu-ml/SageAttention
Torch > https://pytorch.org/get-started/locally/
Libraries for Triton > https://github.com/woct0rdho/triton-windows/releases/download/v3.0.0-windows.post1/python_3.12.7_include_libs.zip These files are usually located in Python folders but this is for portable install.

Below : Location of FP16Fast

![image](https://github.com/user-attachments/assets/7c198e64-739f-4023-9eff-f74bd27eccda)

Below : Cuda 12.8 variables

![image](https://github.com/user-attachments/assets/69bf0c72-20cc-4c78-8671-7f81c701f205)

Below : Cuda and MSVC Paths 

![image](https://github.com/user-attachments/assets/6f024a4a-1db0-4f29-9bc6-2ba6eeb5ad11)

Below : Cuda version and location settings

![image](https://github.com/user-attachments/assets/b26e1c7a-991a-4bc1-9d7f-b3114d0badca)

Below : Path set for CL.exe (Compiler in MSVC) , not needed to link the exe but I prefer it this way (see it in the list in the above pic)

![image](https://github.com/user-attachments/assets/ad071e43-9d4d-40f7-ab4f-d9c2620e0d66)

