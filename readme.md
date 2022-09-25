# Renderer

Project we use internally to quickly render tilted maps. Forked version of RoRenderV3 (https://devforum.roblox.com/t/minimap-render-rorenderv3/965827), heavily edited.

Ignoring character on client has been entirely removed therefore character spawning shall be disabled for the tool to work properly. Before starting with render you should also make sure no game script are run and all invisible parts are removed.

This tool will automatically split the rendered part of map into plots (each `PPS * Grid` px wide). That has been made to generate images which will fit Roblox's 1024x1024 decal resolution.

This script does not use electron app. Instead it will listen for streamed data and automatically store image in file when finished.

# Usage

1) Configuring map

You should set rendered part of map by placing two parts (they may be rotated, but make sure they both have same rotation). Front on the parts will point the top of the render. The script will then calculate center CFrame by 
```lua
Part1.CFrame:Lerp(Part2.CFrame, 0.5)
```
and determine how many plots it should render. Plot centered on that point will always have id of `ceil(AllPlots / 2)`.

As mentioned previously, you should also get rid of any invisible parts and scripts. Our internal script for that is included (`Prepare.server.lua`).

2) Inject the Renderer

Inject the Renderer to the game using rojo.

3) Configuring server

Enter the server folder and run `npm install` to install all nodejs dependencies. You may configure port, output directory and file extension in the `index.js` script. Use `npm run` to run the server script.
