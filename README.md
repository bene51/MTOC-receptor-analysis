# MTOC-receptor-analysis


## Motivation
Quantify how well the MTOC binds to the B-cell receptor. In the experiment, the ligand is attached to the glass. Hypothetically, the B-cell receptor binds to it, upon which the MTOC binds to the receptor, and the spindles grow symmetrically away from the glass. If this mechanism is disrupted, the spindles might not grow symmetrically, and the location of the MTOC might not co-localize well with the receptor.

For quantification, we check how well the MTOC is centered within the cell, by calculating the distance of the MTOC to the center of the cell outline. Furthermore, we calculate the weighted mean distance of the receptor signal to the MTOC.

Example dataset: [20240306\_405+406\_ko.tif](https://github.com/bene51/MTOC-receptor-analysis/releases/download/v0.1.0/20240306_405+406_ko.tif).


## Installation
Download [MTOC-receptor-analysis.ijm](https://github.com/bene51/MTOC-receptor-analysis/raw/refs/heads/main/MTOC-receptor-analysis.ijm) and and copy it to the `<Fiji.app>/macros/toolsets/` folder. Furthermore, download [Weighted\_Distance\_From\_Point-0.3.jar](https://github.com/bene51/MTOC-receptor-analysis/releases/download/v0.1.0/Weighted_Distance_From_Point-0.3.jar) (Git tag v0.3) to the `<Fiji.app>/plugins` folder. Restart Fiji.


## Usage
* Open Fiji and activate the 'MTOC-receptor-analysis' toolset by clicking on `>>` in Fiji's toolbar and select `MTOC-receptor-analysis`:
<img src="https://romulus.oice.uni-erlangen.de/slides/projects/2024-03-28-lweckwerth/v0.3/images/Screenshot-00.png" width="650" />

* Open the image you want to analyze. You might want to show each channel separately (`>Image>Color>Channels Tool...`, switch to `Color`).

* Check the image calibration, especially the pixel depth (`>Image>Properties`).

* Click on `P` (Preprocess) in the Fiji toolbar, to smooth the receptor channel (default is channel 3, sigma 1).

* Delete all entries in the ROI Manager (if there are any), or just close it.

* Double-click the `Pick Cell` tool and adjust the radius (for the outline, in microns).

* Press `F1` to select the `Pick Cell` tool.

* In the image, go to a plane that contains an MTOC <br>*Hint: Scrolling in a multi-channel image will change channels, if you want to scroll through z, keep the `ALT` key pressed.*

* Click on the MTOC. This will open orthogonal views of the MTOC's surrounding. Fine-tune the position of the MTOC along all three axes, then click OK:
![](https://romulus.oice.uni-erlangen.de/slides/projects/2024-03-28-lweckwerth/v0.3/images/Screenshot-01.png)

* Next, adjust the cell's outline by moving it (best drag it from its label) and resizing it (press `SHIFT` to keep it circular).
![](https://romulus.oice.uni-erlangen.de/slides/projects/2024-03-28-lweckwerth/v0.3/images/Screenshot-02.png)

* And adjust the cell's z position in the xz-view
![](https://romulus.oice.uni-erlangen.de/slides/projects/2024-03-28-lweckwerth/v0.3/images/Screenshot-03.png)

* Clicking OK will create a point (with 3D coordinates) at the MTOC's position and an outline (through the cell's center), both of which are also shown in the ROI Manager.
![](https://romulus.oice.uni-erlangen.de/slides/projects/2024-03-28-lweckwerth/v0.3/images/Screenshot-04.png)

* Press `F1` to select the `Pick Cell` tool again, and mark the next MTOC. Repeat this for all MTOCs in the image.

* Once done, click on the `Measure` icon in the toolbar. It will ask for the channel to be measured (the receptor channe), and for a threshold. Values below the threshold will be ignored for the measurement of the weighted distance between MTOC and receptor. The default value for theshold is 430, which works well for the example image, but in general this value should be adapted to the image at hand. Additionally, it asks for the number of planes to measure. The first plane is the start of the cell (i.e. the cell center minus the cell radius).

A table is created summarizing all measurements (see below):


![](https://romulus.oice.uni-erlangen.de/slides/projects/2024-03-28-lweckwerth/v0.3/images/Screenshot-05.png)

| Column | Description |
| ------ | ----------- |
| image  | The title of the analyzed image |
| roi    | The name of the ROI (identifying the cell within the image |
| MTOC x [pixel] | The MTOC center x coordinate, in pixels |
| MTOC y [pixel] | The MTOC center y coordinate, in pixels |
| MTOC z [pixel] | The MTOC center z coordinate, in pixels |
| outline center x [pixel] | The outline center x coordinate, in pixels |
| outline center y [pixel] | The outline center y coordinate, in pixels |
| outline center z [pixel] | The outline center z coordinate, in pixels |
| outline radius [pixel] | The outline radius, in pixels |
| MTOC x [microns] | The MTOC center x coordinate, in microns |
| MTOC y [microns] | The MTOC center y coordinate, in microns |
| MTOC z [microns] | The MTOC center z coordinate, in microns |
| outline center x [microns] | The outline center x coordinate, in microns |
| outline center y [microns] | The outline center y coordinate, in microns |
| outline center z [microns] | The outline center z coordinate, in microns |
| outline radius [microns] | The outline radius, in microns |
| receptor channel | The receptor channel, used for calculating 'weighted distance MTOC-receptor' |
| threshold | The threshold used for the measurement '
| weighted distance MTOC-receptor 2D[microns] | Sum of the 2D-distance of each pixel within the outline, weighted by its intensity, and normalized by the sum of their intensities. |
| weighted distance MTOC-receptor 3D[microns] | Sum of the 3D-distance of each pixel within the outline, weighted by its intensity, and normalized by the sum of their intensities. |
| distance MTOC to center of outline [microns] | The distance of the MTOC to the outline center |
| Angle to rotate MTOC to center | The angle needed to rotate the cell such the MTOC is laterally in the center of the cell |



