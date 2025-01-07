# Picnic in the Oblivion
This is a remake of the original mobile java game S.T.A.L.K.E.R. Mobile 3D ([phone trailer](https://www.youtube.com/watch?v=UcOBQ29YEO4)) 2007 year developed by QPlaze.

All rights for assets - QPlaze, GSC, Nomoc!

![image](https://github.com/Lekksii/picnic-in-the-oblivion/assets/64277255/fccefe6d-dfe4-4700-9f5c-d03761f644d6)

> [!TIP]
> DOWNLOAD: [Itch.io](https://alex1197.itch.io/pito)

## Project is using Godot 4.2.1
###  How to start:
1. Clone this repository
2. Download [Godot](https://godotengine.org/)
3. Import project into godot
4. Open project

## How to export to Windows *.exe file.
1. In godot editor press Editor -> Manage Export Templates...
   
![image](https://github.com/Lekksii/picnic-in-the-oblivion/assets/64277255/c9dd2609-434c-44da-9e0e-df1eac7f2be4)

2. Download available version of templates
   
![image](https://github.com/Lekksii/picnic-in-the-oblivion/assets/64277255/86bce201-2f4c-4a44-b7bf-74ef19400732)

3. After downloading go to Project -> Export...
   
![image](https://github.com/Lekksii/picnic-in-the-oblivion/assets/64277255/d0eeffc1-111a-4f41-ae9a-38024d0b2364)

4. Add new export template and select Windows
   
![image](https://github.com/Lekksii/picnic-in-the-oblivion/assets/64277255/e8425f88-c21e-4024-bcc9-55a8340bc3aa)

5. Set the Name, select the path of saving *.exe and toggle "Runnable"
    
![image](https://github.com/Lekksii/picnic-in-the-oblivion/assets/64277255/9c93f6f8-2d21-4f5b-af9d-8842a30ce75a)

6. Keep this settings:

Options tab:

![image](https://github.com/Lekksii/picnic-in-the-oblivion/assets/64277255/4c25489d-02c9-4b8f-bab3-dd6f99d5e93c)

Resources tab:
   - select export mode to "Export selected resources"
   - select assets/models/
   - select assets/object_editor/
   - select assets/textures/
   - select assets/ui/
   - select engine_objects/
   - select ingame_materials/
   - select scripts/
   - select shaders/
   - select themes/
   - select level_editor/
   - select bug_trap.tscn
   - select console.gd
   - select default_bus_layout.tres
   - select game.tscn
   - select Icon.png
   - select IconBug.png
   - select panel.tscn
     
*Keep in mind, that new resources what has been created in res:// root folder, must be checked for export too.*
*Also, if you add new assets resources and used them as preview in the editor (like UI elements made, they use textures, fonts) you must check them for export too, game will look after export in the assets/ folder and replace them to files inside assets, so it can be modded.*

Features tab:
   - add in custom field: standalone

When all done - press **Export Project** at the bottom of window.

7. Copy **assets/** folder from the source code folder into exported game build folder near *picnic.exe*.

### Documentation:
1. [Assets description](https://picnic-in-the-oblivion.gitbook.io/assets/)
2. [Source code scripts](https://picnic-in-the-oblivion.gitbook.io/source-code-scripts/)
3. [Level Editor tutorials](https://picnic-in-the-oblivion.gitbook.io/level-editor)
   
>[!WARNING]
>Documentation isn't ready! There might be some time before it will be completed.
