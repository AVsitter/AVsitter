
The AVsitter2 scripts can be freely obtained from this GitHub repository and imported into Second Life or OpenSim manually by following the guide below.

If you would prefer a packaged version of the latest release, and to receive packaged [in-world updates](https://avsitter.github.io/updates.html) of future releases, visit the [SL Marketplace](https://marketplace.secondlife.com/stores/79645). Proceeds from marketplace sales are shared with open-source contributors and will help support continued development of AVsitter.


## Importing the AVsitter2 scripts into Second Life / OpenSim

Quick summary: Download the scripts from the [releases page](https://github.com/AVsitter/AVsitter/releases); name them in the viewer the same as in the zip file but without extension, saving all of them with Mono enabled; create an [AV]helper *object*, put the [AV]helperscript *script* inside and take it; create an AVpos notecard, add something to it and save it.

Step-by-step guide:

1. Visit the [AVsitter project releases page](https://github.com/AVsitter/AVsitter/releases) and download the `.zip` file for the latest AVsitter2 release to your computer.

2. Unpack the file you downloaded to a folder where you plan on keeping your AVsitter distributions. The file for Second Life contains `.lslo` and `.lsl` scripts; the file for OpenSim contains `.oss` scripts.

3. In your viewer's inventory, locate a suitable place and create a folder named AVsitter (plus the version name), where you'll save all the scripts and needed objects.

4. For each `.lslo` or `.lsl` (or `.oss` for OpenSim) file that you unpacked from the `.zip` file, create a new script in your viewer's inventory and rename it to match exactly the same name as the file you unpacked, but removing the `.lslo` or `.lsl` or `.oss` at the end of the name.

    For example, if the script you unpacked was called **[AV]sitA.lslo** then the script you create in your viewer should be named simply **[AV]sitA**. The name of the script is important! Do not add `.lslo` at the end of the name. Ensure the letter case also matches.

5. If you are using Firestorm or you are in OpenSim, skip to step 6. If you are using another viewer in Second Life:

    - Create a box.
    - While holding the Ctrl key, drop all scripts you have created in the previous step, from your inventory to the box.

      This is necessary because the scripts must be saved with the Mono checkbox enabled. The official viewer currently saves them with Mono disabled if saving in inventory, and other third-party viewers may do the same. Firestorm saves by default with Mono enabled, so if you're using Firestorm you don't need this step.

      The Ctrl key ensures that the scripts will NOT be running when dropped in that prim; that will allow you to save them without any side effects.

    - Edit the prim and go to the contents tab. Follow the instructions in the next step using the scripts in the contents of the prim, not in your inventory.

6. For each script you just created in Second Life or OpenSim:
    - Open the script in Second Life or OpenSim by double-clicking it.
    - Open the corresponding `.lslo`/`.lsl`/`.oss` file on your computer with a plain text editor (e.g. Notepad).
    - Select All text in the file (CTRL-A) and Copy (CTRL-C).
    - In the viewer, replace the script's content with the text you've copied. You can do this by overwriting the text of the default script by Selecting All (CTRL-A) and pasting the code you've copied from your computer's text editor (CTRL-V).
    - If you are not using FS and you are not in OpenSim, it means you followed step 5 above. Ensure that the Mono checkbox is checked, and check it if not.
    - Hit **Save** to compile the script. If all goes well, it should say "Compile Successful" and "Save Complete". If you get a script error, then either you have not correctly replaced the entire script's contents with the content of the file on your computer, or you are compiling with Mono disabled.
    - No errors? Then proceed similarly with the rest of the scripts.
    - If you followed step 5 above, copy all the scripts back to your inventory and delete the old ones.

    When you have finished this process, you should have created one script for each `.lslo` or `.lsl` file that was in the `.zip` file (or `.oss` for OpenSim), copied the file's contents from your computer and saved it in the corresponding Second Life or OpenSim script.

7. Prepare an **[AV]helper** object.

    - In Second Life or OpenSim, rez a box and name it **[AV]helper**.
    - Inside its contents, drop the **[AV]helperscript** script that, at this point, you must have created by following the above procedure.
    - Take the **[AV]helper** object to your inventory.

8. There's still one thing to do to have the distribution working:

    - Create a notecard in your inventory and name it **AVpos**.
    - Open it and write this text in it: `This notecard is empty` (any text that is not an AVpos command will work instead of that, even a space).
    - *Save* it. This step is very important. Notecards that have never been saved after being created will cause problems.
    - Use that notecard as an empty notecard when following the user instructions below.

After importing the AVsitter2 scripts into Second Life or OpenSim, you are ready to follow the [AVsitter2 User Instructions](https://avsitter.github.io/avsitter2_home). Where the instructions mention the **[AV]helper** object, it refers to the object we've just created with the **[AV]helperscript** script inside.
