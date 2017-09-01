
The AVsitter2 scripts can be freely obtained from this GitHub repository and imported into Second Life or OpenSim manually by following the guide below.

If you would prefer a packaged version of the latest release, and to receive packaged [in-world updates](https://avsitter.github.io/updates.html) of future releases, visit the [SL Marketplace](https://marketplace.secondlife.com/stores/79645). Proceeds from marketplace sales are shared with open-source contributors and will help support continued development of AVsitter.


## Importing the AVsitter2 scripts into Second Life / OpenSim

1. Visit the [AVsitter project releases page](https://github.com/AVsitter/AVsitter/releases) and download the ```.zip``` file for the latest AVsitter2 release to your computer.

2. Unpack the file you downloaded to a folder where you plan on keeping your AVsitter distributions.

3. In your Second Life inventory, locate a suitable place and create a folder named AVsitter, where you'll save all the scripts and needed objects. 

4. For each ```.lslo``` file that you unpacked from the ```.zip``` file, create a new script in your Second Life inventory and rename it to match exactly the same name as the file you unpacked, but without the ```.lslo``` at the end of the name.

    For example, if the script you unpacked was called **[AV]sitA.lslo** then the script you create in Second Life should be named simply **[AV]sitA**. The name of the script is important! Do not add ```.lslo``` at the end of the name.

5. For each script you just created in Second Life:
    - Open the script in Second Life by double-clicking it.
    - Open the corresponding ```.lslo``` file on your computer with a plain text editor (e.g. Notepad).
    - Select All text in the file (CTRL-A) and Copy (CTRL-C).
    - In SL, replace the script's content with the text you've copied. You can do this by overwriting the text of the default script by Selecting All (CTRL-A) and pasting the code you've copied from your computer's text editor (CTRL-V).
    - Once you do this, hit **Save** to compile the script. If you get a script error, then you have not correctly replaced the entire script's contents with the content of the file on your computer.
    - No errors? Then proceed similarly with the rest of the scripts. 

    When you have finished this process you should have created one script for each ```.lslo``` file that was in the ```.zip``` file, copied the file's contents from your computer and saved it in the corresponding Second Life script.

6. There's still one thing to do to have the distribution working:

    - In Second Life, rez a box and name it **[AV]helper**.
 
    - Inside its contents, drop the **[AV]helper** script that, at this point, you must have created by following the above procedure.

After importing the AVsitter2 scripts into Second Life you are ready to follow the [AVsitter2 User Instructions](https://avsitter.github.io/avsitter2_home). Where the instructions mention the **[AV]helper** object, it refers to the object we've just created with the script inside.






