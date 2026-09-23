%% extractMineRoute.m
% VERSION: v4 (single CSV)
% Extracts the EXACT haul route from MathWorks' "Create Route Planner for
% Offroad Navigation Using Digital Elevation Data" example (Bingham Canyon
% copper mine, USGS lidar) at true mine scale, with per-point road features.
%
% SETUP (nothing to download manually):
%   1) In the Command Window run:
%      openExample('offroad_autonomy/CreateRoutePlannerForOffroadNavigationUsingElevationDataExample')
%      -> copies the example + Helpers/ to a local folder and cd's into it
%   2) Put this file in that folder and run it. The point cloud downloads
%      automatically on first run.
%
% OUTPUTS (./mineRoute): route_points.csv (all features, one row per point),
%                        route.yaml, mineRoute.mat (incl. summary tables) + figures
% Coordinates are the example's local map frame (m), same frame as its start/goal.

clear; close all; clc

%% ---------- USER PARAMETERS ----------
useExampleRoute = true;               % true = example's exact start/goal; false = click on map
exampleStart = [286.5 423.5];
exampleGoal  = [795.5 430.5];
res          = 1;                     % DEM cells per meter (example uses 1)
flatGradePct = 2;                     % |grade| below this = flat
minSegLen    = 30;                    % merge grade blips shorter than this (m)
geomWin      = 51;                    % centerline smoothing window (m) - removes pixel stair-steps
gradeLen     = 30;                    % grade measured as rise over this chord length (m)
radiusChord  = 30;                    % curve radius from circle through points this far apart (m)
straightR    = 1000;                  % radius above this = straight (reported as Inf)
curveR       = 150;                   % sustained radius below this = a curve (m)
minCurveLen  = 15;                    % shortest curve to report (m)
switchbackDeg = 120;                  % heading change that counts as a switchback...
switchbackWin = 120;                  % ...within this distance (m)
crossOffset  = 3;                     % m each side of centerline for cross-slope
outDir = "mineRoute";

%% ---------- 0. Checks ----------
for f = ["navGraph","plannerAStar","bwskel","pcshow"]
    assert(~isempty(which(f)),"Missing %s: need R2024a+ with Navigation, Image Processing, CV and Lidar toolboxes.",f);
end
assert(isfolder("Helpers"),"Run from the openExample folder so Helpers/ exists.");
addpath(genpath("Helpers"))
if ~isfolder(outDir), mkdir(outDir); end

%% ---------- 1. Terrain -> road network (identical to the example) ----------
data = matlab.internal.examples.downloadSupportFile("nav","data/pitMineClean.mat");
load(data,"cleanPC")
[dzdx,dzdy,dem] = exampleHelperPc2Grad(cleanPC,res);

slopeMax = deg2rad(15);
imSlope  = atan2(abs(dzdx),1/res) < slopeMax & atan2(abs(dzdy),1/res) < slopeMax;
imNarrow = imopen(imSlope,strel("disk",4));
imHoles  = ~imfill(~imNarrow,"holes");
B = bwboundaries(imHoles);
[val,idx] = sort(cellfun(@(b)size(b,1),B));
seedPts = zeros(0,2);
for i = 1:numel(val)
    if val(i) >= 20, break; end
    seedPts(end+1,:) = B{idx(i)}(1,:); %#ok<AGROW>
end
if isempty(seedPts), tmp = imHoles; else, tmp = imfill(imHoles,seedPts,4); end
imFilled = ~imdilate(bwmorph(~tmp,"bridge"),ones(3));   % true = traversable
rawSkel  = bwskel(imFilled,MinBranchLength=75);
pathList = exampleHelperSkel2Edges(rawSkel);

binMap = binaryOccupancyMap(~imSlope,res);
assert(isequal(binMap.GridSize,size(dem)),"DEM and map sizes differ.");
localPathList = pathList;
for i = 1:numel(pathList)
    localPathList(i).Path = grid2local(binMap,pathList(i).Path);
end
[nodes,edges,e2p,cached] = exampleHelperPath2GraphData(localPathList,25);
edgeCosts  = exampleHelperDefaultEdgeCost(cached,e2p);
stateTable = table(nodes,VariableNames="StateVector");
linkTable  = table(edges,edgeCosts,e2p(:),VariableNames=["EndStates","Weight","Edge2PathIdx"]);
planner    = plannerAStar(navGraph(stateTable,linkTable));

%% ---------- 2. Plan the route ----------
figure(Name="Road network");
hIm = show(binMap); hold on
cmap = colormap("spring");
exampleHelperOverlayPathImage(hIm,pathList,cmap(randi(size(cmap,1),numel(pathList)),:),Radius=2)
if useExampleRoute
    startPt = exampleStart; goalPt = exampleGoal;
else
    title("Click START (load), then GOAL (dump)")
    [px,py] = ginput(2); startPt = [px(1) py(1)]; goalPt = [px(2) py(2)];
end
[~,iS] = min(vecnorm(nodes(:,1:2)-startPt,2,2));
[~,iG] = min(vecnorm(nodes(:,1:2)-goalPt,2,2));
[~,info] = plan(planner,iS,iG);
assert(info.IsPathFound,"No path found between start and goal.");
ids  = info.PathStateIDs(:);
lnk  = findlink(planner.Graph,[ids(1:end-1) ids(2:end)]);
segs = {cached(planner.Graph.Links.Edge2PathIdx(lnk)).Path};
P = stitchSegments(segs,nodes(iS,1:2));      % native ~1 m centerline points
plot(P(:,1),P(:,2),"c",LineWidth=3)
plot(P(1,1),P(1,2),"ro",P(end,1),P(end,2),"gs",MarkerSize=10,LineWidth=2)
title("Extracted route (red = start/load, green = goal/dump)")

%% ---------- 3. Per-point features ----------
% Resample the pixel path to uniform 1 m spacing, then smooth out stair-steps
s0 = [0; cumsum(vecnorm(diff(P),2,2))];
s  = (0:1:s0(end))'; if s(end) < s0(end), s(end+1) = s0(end); end
P  = interp1(s0,P,s);
n  = numel(s);
Ps = smoothdata(P,1,"sgolay",geomWin);              % smooth centerline (keeps curve shape)
Ps([1 end],:) = P([1 end],:);                       % pin exact start/goal
Ps = interp1([0; cumsum(vecnorm(diff(Ps),2,2))],Ps,linspace(0,sum(vecnorm(diff(Ps),2,2)),n)');
s  = [0; cumsum(vecnorm(diff(Ps),2,2))];            % distance along smoothed road

nR = size(dem,1);
zAt = @(xy) interp2(dem, xy(:,1)*res+0.5, nR - xy(:,2)*res + 0.5, "linear");  % bilinear DEM lookup
zRaw = zAt(Ps);
zS   = smoothdata(zRaw,"movmean",gradeLen,"SamplePoints",s);

% Grade = rise over a gradeLen chord centered on each point
iF = min((1:n)'+round(gradeLen/2),n); iB = max((1:n)'-round(gradeLen/2),1);
gradePct = 100*(zRaw(iF)-zRaw(iB))./(s(iF)-s(iB));

% Heading from a short chord; radius from circle through points +/- radiusChord/2
k  = max(1,round(radiusChord/2));
iF = min((1:n)'+k,n); iB = max((1:n)'-k,1);
hdg = atan2(Ps(iF,2)-Ps(iB,2), Ps(iF,1)-Ps(iB,1));
hU  = unwrap(hdg);
A = Ps(iB,:); Bm = Ps; C = Ps(iF,:);
a = vecnorm(Bm-C,2,2); b = vecnorm(A-C,2,2); c = vecnorm(A-Bm,2,2);
area2 = abs((Bm(:,1)-A(:,1)).*(C(:,2)-A(:,2)) - (Bm(:,2)-A(:,2)).*(C(:,1)-A(:,1)));
radius = a.*b.*c./(2*area2);                        % circumradius (m)
radius(~isfinite(radius)) = straightR;
radius([1:k, n-k+1:n]) = straightR;                 % ends: chord collapses, not a real curve
radius = movmedian(min(radius,straightR),radiusChord+1);  % kill single-point wobble spikes
radius(radius >= straightR) = Inf;

hF = interp1(s,hU,min(s+switchbackWin/2,s(end)));
hB = interp1(s,hU,max(s-switchbackWin/2,0));
turnDeg = rad2deg(abs(hF-hB));
isSB = turnDeg > switchbackDeg;

nrm = [-sin(hdg) cos(hdg)];                         % left-pointing normal
crossPct = 100*(zAt(Ps+crossOffset*nrm) - zAt(Ps-crossOffset*nrm))/(2*crossOffset); % + = left side higher

ij = max(min(local2grid(binMap,Ps),size(dem)),1);
halfW = bwdist(~imFilled)/res;
widthM = 2*halfW(sub2ind(size(dem),ij(:,1),ij(:,2)));  % traversable width (m)

segVal = sign(gradePct).*(abs(gradePct) >= flatGradePct);   % -1 down, 0 flat, +1 up
segVal = mergeShortRuns(segVal,s,minSegLen);
names  = ["down","flat","up"];
segType = reshape(names(segVal+2),[],1);

%% ---------- 4. Tables ----------
Pts = table(s,Ps(:,1),Ps(:,2),zRaw,zS,gradePct,crossPct,hdg,radius,widthM,segType,isSB, ...
    VariableNames=["s_m","x","y","z_raw","z_smooth","grade_pct","cross_slope_pct", ...
                   "heading_rad","curve_radius_m","width_m","segment","switchback"]);

R = runsWithValue(segVal); nSeg = size(R,1);
Seg = table('Size',[nSeg 12],'VariableTypes',["double","string",repmat("double",1,10)], ...
    'VariableNames',["id","type","s_start","s_end","length_m","z_start","z_end","rise_m", ...
                     "avg_grade_pct","max_abs_grade_pct","min_width_m","median_width_m"]);
for k = 1:nSeg
    b = R(k,1); e = R(k,2); L = s(e)-s(b);
    Seg(k,:) = {k, names(R(k,3)+2), s(b), s(e), L, zS(b), zS(e), zS(e)-zS(b), ...
        100*(zS(e)-zS(b))/max(L,eps), max(abs(gradePct(b:e))), min(widthM(b:e)), median(widthM(b:e))};
end

Rs = runsWithValue(double(isSB)); Rs = Rs(Rs(:,3)==1,:); nSB = size(Rs,1);
SB = table('Size',[nSB 8],'VariableTypes',repmat("double",1,8), ...
    'VariableNames',["id","s_start","s_end","x_apex","y_apex","turn_deg","min_radius_m","median_radius_m"]);
for k = 1:nSB
    b = Rs(k,1); e = Rs(k,2); [~,a] = min(radius(b:e)); a = a+b-1;
    SB(k,:) = {k, s(b), s(e), Ps(a,1), Ps(a,2), max(turnDeg(b:e)), radius(a), median(radius(b:e))};
end

Rc = runsWithValue(double(radius < curveR)); Rc = Rc(Rc(:,3)==1,:);
Rc = Rc(s(Rc(:,2))-s(Rc(:,1)) >= minCurveLen,:); nC = size(Rc,1);
Curves = table('Size',[nC 9],'VariableTypes',["double","string",repmat("double",1,7)], ...
    'VariableNames',["id","direction","s_start","s_end","length_m","median_radius_m","min_radius_m","turn_deg","switchback"]);
for k = 1:nC
    b = Rc(k,1); e = Rc(k,2); dh = hU(e)-hU(b);
    dirStr = "left"; if dh < 0, dirStr = "right"; end
    Curves(k,:) = {k, dirStr, s(b), s(e), s(e)-s(b), median(radius(b:e)), min(radius(b:e)), rad2deg(abs(dh)), any(isSB(b:e))};
end

% Tag every point with the segment / curve / switchback it belongs to (0 = none)
segId = zeros(n,1); curveId = zeros(n,1); sbId = zeros(n,1);
for k = 1:nSeg, segId(R(k,1):R(k,2)) = k; end
for k = 1:nC,   curveId(Rc(k,1):Rc(k,2)) = k; end
for k = 1:nSB,  sbId(Rs(k,1):Rs(k,2)) = k; end
Pts = addvars(Pts,segId,curveId,sbId,After="segment", ...
    NewVariableNames=["segment_id","curve_id","switchback_id"]);

%% ---------- 5. Cycle (haul + return) and export ----------
ret = flipud(Pts);
ret.s_m = s(end)-ret.s_m;
ret.heading_rad = angle(exp(1i*(ret.heading_rad+pi)));
ret.grade_pct = -ret.grade_pct;
ret.cross_slope_pct = -ret.cross_slope_pct;
up = ret.segment=="up"; dn = ret.segment=="down";
ret.segment(up) = "down"; ret.segment(dn) = "up";
Pts = addvars(Pts,repmat("haul",height(Pts),1),Before=1,NewVariableNames="leg");
ret = addvars(ret,repmat("return",height(ret),1),Before=1,NewVariableNames="leg");
Cycle = [Pts; ret];

writetable(Cycle,fullfile(outDir,"route_points.csv"));
writeYaml(fullfile(outDir,"route.yaml"),Pts,ret);
save(fullfile(outDir,"mineRoute.mat"),"Cycle","Seg","SB","Curves","P","dem","res","startPt","goalPt");

%% ---------- 6. Plots ----------
figure(Name="Route profile"); tiledlayout(4,1,TileSpacing="compact")
nexttile; plot(s,zRaw,Color=[.7 .7 .7]); hold on; plot(s,zS,"k",LineWidth=1.5)
for k = find(Seg.type~="flat")', xregion(Seg.s_start(k),Seg.s_end(k),FaceColor=[1 .8 .3]); end
ylabel("Elev (m)"); title("Profile (shaded = ramps)"); legend("raw","smoothed")
nexttile; plot(s,gradePct,LineWidth=1.2); hold on; plot(s,crossPct,LineWidth=1)
yline([-flatGradePct flatGradePct],"--"); ylabel("%"); legend("grade","cross-slope")
nexttile; plot(s,widthM,LineWidth=1.2); ylabel("Width (m)")
nexttile; rp = min(radius,straightR); plot(s,rp,LineWidth=1.2); hold on
plot(s(isSB),rp(isSB),"m.",MarkerSize=10); ylim([0 straightR*1.05])
ylabel("Radius (m)"); xlabel("Distance along route (m)"); title("Curve radius (top = straight, magenta = switchback)")

figure(Name="3D route");
[nRr,nCc] = size(dem);
[X,Y] = meshgrid(((1:nCc)-0.5)/res, (nRr-(1:nRr)'+0.5)/res);
surf(X,Y,dem,EdgeColor="none",FaceAlpha=0.85); hold on; colormap(gca,"parula")
plot3(Ps(:,1),Ps(:,2),zRaw+3,"r",LineWidth=2.5)
axis equal; view(-30,50); title("Route on DEM"); xlabel("x (m)"); ylabel("y (m)"); zlabel("z (m)")

%% ---------- 7. Summary ----------
fprintf("\n=== Extracted route ===\n")
fprintf("Length %.0f m | elevation %.1f -> %.1f m (net %+.1f m)\n",s(end),zS(1),zS(end),zS(end)-zS(1))
fprintf("Grade: max up %.1f%%, max down %.1f%% | width median %.1f m (min %.1f m)\n", ...
    max(gradePct),min(gradePct),median(widthM),min(widthM))
fprintf("Segments: %d (%d ramps) | curves: %d | switchbacks: %d\n",nSeg,sum(Seg.type~="flat"),nC,nSB)
if nSB > 0
    fprintf("Switchback median radii (m): %s\n",strjoin(string(round(SB.median_radius_m))',", "))
end
fprintf("Tightest curve (median radius): %.0f m\n",min([Curves.median_radius_m; Inf]))
fprintf("Files in %s/\n",outDir)

%% ---------- Local functions ----------
function P = stitchSegments(segs,startPt)
% Concatenate cached edge paths, flipping any stored in the opposite direction.
P = segs{1}(:,1:2);
if numel(segs) > 1
    S2 = segs{2}(:,1:2);
    if min(vecnorm(S2([1 end],:)-P(1,:),2,2)) < min(vecnorm(S2([1 end],:)-P(end,:),2,2))
        P = flipud(P);
    end
elseif norm(P(end,:)-startPt) < norm(P(1,:)-startPt)
    P = flipud(P);
end
for k = 2:numel(segs)
    S = segs{k}(:,1:2);
    if norm(S(end,:)-P(end,:)) < norm(S(1,:)-P(end,:)), S = flipud(S); end
    P = [P; S]; %#ok<AGROW>
end
P = P([true; vecnorm(diff(P),2,2) > 1e-6],:);
end

function R = runsWithValue(v)
% [start end value] for each run of equal values.
v = v(:); brk = [1; find(diff(v)~=0)+1];
R = [brk [brk(2:end)-1; numel(v)] v(brk)];
end

function v = mergeShortRuns(v,s,minLen)
% Absorb runs shorter than minLen (m) into the preceding run.
changed = true;
while changed
    changed = false; R = runsWithValue(v);
    for k = 1:size(R,1)
        if s(R(k,2))-s(R(k,1)) < minLen && size(R,1) > 1
            nb = R(max(k-1,1)+(k==1),3);          % previous run, or next if first
            v(R(k,1):R(k,2)) = nb; changed = true; break
        end
    end
end
end

function writeYaml(fn,haul,ret)
fid = fopen(fn,"w"); c = onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid,"# Exact haul cycle, Bingham Canyon DEM (MathWorks example), mine scale, meters\nframe_id: map\n");
legs = {haul,ret}; nm = ["haul","return"];
for L = 1:2
    T = legs{L}; fprintf(fid,"%s:\n",nm(L));
    for i = 1:height(T)
        h = T.heading_rad(i);
        fprintf(fid,"  - {x: %.2f, y: %.2f, z: %.2f, qz: %.4f, qw: %.4f, grade_pct: %.2f, cross_pct: %.2f, width: %.1f, seg: %s, switchback: %d}\n", ...
            T.x(i),T.y(i),T.z_smooth(i),sin(h/2),cos(h/2),T.grade_pct(i),T.cross_slope_pct(i),T.width_m(i),T.segment(i),T.switchback(i));
    end
end
end