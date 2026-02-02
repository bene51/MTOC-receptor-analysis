var radius = 3; // in microns
var channelToMeasure = 3;
var threshold = 430;
var gaussSigma = 1;
var nMeasurementPlanes = 8;

macro "Preprocess Action Tool - C000T5e14P" {
    Dialog.create("Preprocessing");
    Dialog.addNumber("Channel", channelToMeasure);
    Dialog.addNumber("Sigma", gaussSigma);
    Dialog.show();
    
    channel = Dialog.getNumber();
    gaussSigma = Dialog.getNumber();
    
    call("wdfp.Otsu.gauss", channel, gaussSigma);
    updateDisplay();
}

macro "Pick Cell Tool - Cf00V7733C0a0O00ee" {
   var orgIndex = roiManager("count") / 2;
   getPixelSize(unit, pixelWidth, pixelHeight);
   var radiusPix = radius / pixelWidth;
   roiManager("show all with labels");

   roiManager("UseNames", "true");
   getCursorLoc(x, y, z, flags);

   Stack.getPosition(channel, slice, frame);

   xOffs = x - 2 * radiusPix;
   yOffs = y - 2 * radiusPix;
   makeRectangle(x - 2 * radiusPix, y - 2 * radiusPix, 4 * radiusPix, 4 * radiusPix);
   run("Duplicate...", "title=inset duplicate");
   insetID = getImageID();

   dx = xOffs; if(xOffs < 0) dx = 0;
   dy = yOffs; if(yOffs < 0) dy = 0;

   x -= dx;
   y -= dy;

   // start orthogonal views and let the user fine-tune the MTOC position
   Stack.startOrthoViews();
   waitForUser("Fine-adjust the orthogonal cross-point on the MTOC\nThen click OK.");
   Stack.getOrthoViews(MTOCx, MTOCy, MTOCz);
   getVoxelSize(pw, ph, pd, units);
   MTOCrwx = MTOCx * pw;
   MTOCrwy = MTOCy * ph;
   MTOCrwz = MTOCz * pd;
   Stack.stopOrthoViews();
   
   
   // let the user fine-tune the outline's position and radius, laterally
   setTool("oval");
   makeOval(x-radiusPix, y-radiusPix, radiusPix*2, radiusPix*2);
   waitForUser("Fine-adjust the cell's outline center and radius");
   Roi.getBounds(ox, oy, ow, oh);
   outlineCx = ox + ow / 2;
   outlineCy = oy + oh / 2;

   // let the user fine-tune the outline's position along z. For that,
   // start orthogonal views, duplicate YZ and stop orthogonal views
   Stack.startOrthoViews();
   wait(150);
   Stack.getOrthoViewsIDs(XY, YZ, XZ);
   selectImage(YZ);
   getLocationAndSize(wx, wy, wwidth, wheight);
   run("Duplicate...", "title=yz");
   yzID = getImageID();
   Stack.stopOrthoViews();
   selectImage(XY);
   close();
   wait(150);
   selectImage(yzID);
   setLocation(wx, wy, wwidth, wheight);
   run("Remove Overlay");
   makeOval(MTOCrwz / pw - radiusPix, outlineCy - radiusPix, 2 * radiusPix, 2 * radiusPix);
   waitForUser("Fine-adjust the cell's outline center along the z-axis");
   Roi.getBounds(ox, oy, ow, oh);
   outlineCy = oy + oh / 2;
   outlineCz = pw * (ox + ow / 2) / pd;

   selectImage(yzID);
   close();
   
   Stack.setPosition(channel, MTOCz, frame);
   makePoint(MTOCx + dx, MTOCy + dy);
   Roi.setPosition(channel, MTOCz, frame);
   Roi.setName("mtoc" + (orgIndex + 1));
   roiManager("add");

   Stack.setPosition(channel, outlineCz, frame);
   makeOval(outlineCx + dx - radiusPix, outlineCy + dy - radiusPix, 2 * radiusPix, 2 * radiusPix);
   Roi.setPosition(channel, outlineCz, frame);
   Roi.setName("outline" + (orgIndex + 1));
   roiManager("add");
   
   Roi.remove;
   setTool("Pick Cell Tool");
}

macro "Measure Action Tool - C000T5e14M" {
    getVoxelSize(vw, vh, vd, vunit);
    if(vd == 1) {
        Dialog.create("Warning");
        Dialog.addMessage("Voxel depth is 1. Did you forget to change it?");
        Dialog.show();
    }
    Dialog.create("Pick Cell Tool Options");
    Dialog.addNumber("Channel to measure", channelToMeasure);
    Dialog.addNumber("Threshold", threshold);
    Dialog.addNumber("No of planes to measure", nMeasurementPlanes);
    Dialog.show();
     
    channelToMeasure = Dialog.getNumber();
    threshold = Dialog.getNumber();
    nMeasurementPlanes = Dialog.getNumber();
    
    N = roiManager("count") / 2;
    
    if(!isOpen("leonie-table"))
        Table.create("leonie-table");
	
    for(i = 0; i < N; i++) {
        roiManager("select", 2 * i); // the point
        Roi.getCoordinates(xpoints, ypoints);
        x = round(xpoints[0]);
        y = round(ypoints[0]);
        Roi.getPosition(unused, slice, frame);
        z = slice - 1;
        roiName = Roi.getName();
        
        roiManager("select", 2 * i + 1); // the outline
        Roi.getBounds(ox, oy, ow, oh);
        Roi.getPosition(unused, slice, frame);
        outlineX = ox + ow / 2;
        outlineY = oy + oh / 2;
        outlineR = ow / 2;
        outlineZ = slice - 1;
        
        
        radiusZ = round(outlineR * vw / vd);
        
        z0 = outlineZ - radiusZ;
        if(z0 < 0)
            z0 = 0;
        z1 = z0 + nMeasurementPlanes;
IJ.log("measure from " + (z0+1) + " to " + (z1+1));
        
        Stack.setChannel(channelToMeasure);
        weightedDistance2D = call("wdfp.Weighted_Distance_From_Point.calculate", x, y, z, threshold, z0, z1, "true"); // ignoreZ
        weightedDistance3D = call("wdfp.Weighted_Distance_From_Point.calculate", x, y, z, threshold, z0, z1, "false"); // don't ignoreZ


        
        getVoxelSize(pw, ph, pd, unit);
        dx = pw * (x - outlineX);
        dy = ph * (y - outlineY);
        distanceCenterOutlineToMTOC = sqrt(dx * dx + dy * dy);

        xRW = x * pw;
        yRW = y * ph;
        zRW = z * pd;

        outlineX_RW = outlineX * pw;
        outlineY_RW = outlineY * ph;
        outlineZ_RW = outlineZ * pd;
        outlineR_RW = outlineR * pw;
        
        row = Table.size("leonie-table");
        Table.set("image", row, getTitle(), "leonie-table");
        Table.set("roi", row, roiName, "leonie-table");
        Table.set("MTOC x [pixel]", row, x, "leonie-table");
        Table.set("MTOC y [pixel]", row, y, "leonie-table");
        Table.set("MTOC z [pixel]", row, z, "leonie-table");
        Table.set("outline center x [pixel]", row, outlineX, "leonie-table");
        Table.set("outline center y [pixel]", row, outlineY, "leonie-table");
        Table.set("outline center z [pixel]", row, outlineZ, "leonie-table");
        Table.set("outline radius [pixel]", row, outlineR, "leonie-table");
        Table.set("MTOC x [" + unit + "]", row, xRW, "leonie-table");
        Table.set("MTOC y [" + unit + "]", row, yRW, "leonie-table");
        Table.set("MTOC z [" + unit + "]", row, zRW, "leonie-table");
        Table.set("outline center x [" + unit + "]", row, outlineX_RW, "leonie-table");
        Table.set("outline center y [" + unit + "]", row, outlineY_RW, "leonie-table");
        Table.set("outline center z [" + unit + "]", row, outlineZ_RW, "leonie-table");
        Table.set("outline radius [" + unit + "]", row, outlineR_RW, "leonie-table");
        Table.set("receptor channel", row, channelToMeasure, "leonie-table");
        Table.set("threshold", row, threshold, "leonie-table");
        Table.set("weighted distance MTOC-receptor 2D[" + unit + "]", row, weightedDistance2D, "leonie-table");
        Table.set("weighted distance MTOC-receptor 3D[" + unit + "]", row, weightedDistance3D, "leonie-table");
        Table.set("distance MTOC to center of outline [" + unit + "]", row, distanceCenterOutlineToMTOC, "leonie-table");



        mTocToCenterX = outlineX_RW - xRW;
        mTocToCenterY = outlineY_RW - yRW;
        mTocToCenterZ = outlineZ_RW - zRW;

        // find the angle that rotates the cell such that the mtoc is in the center
        //               dot(u,v)
        // angle = acos(---------)
        //              |u| * |v|
        // u = mTocToCenter
        // v = [0, 0, 1]
        // dot(u, v) = mTocToCenterZ
        // angle = acos[ mTocToCenterZ / len(mTocToCenter) ]
        angle = acos(mTocToCenterZ / (sqrt(mTocToCenterX * mTocToCenterX + mTocToCenterY * mTocToCenterY + mTocToCenterZ * mTocToCenterZ)));
        angle = angle * 180 / PI;

        Table.set("Angle to rotate MTOC to center", row, angle, "leonie-table");

    }
}

macro "Select Pick Cell Tool [f1]" {
    setTool("Pick Cell Tool");
}

macro "Pick Cell Tool Options" {
    Dialog.create("Pick Cell Tool Options");
    Dialog.addNumber("Radius", radius);
    Dialog.show();
    
    radius = Dialog.getNumber();
}
