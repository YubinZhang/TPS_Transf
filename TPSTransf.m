function TPSTransf(FileName,outDim,lambda,input_points,base_points)
% Thin Plate Spline transformation for EBSD map specified by FileName(with
% .cpr), based on the control points of input_points and base_points, from
% input_image and base_image, respectively. Input_image are the correct
% (EBSD/ECC)image, while base_image are the one that needs to be
% corrected. 
%
%
% outDim = dimension of outupt EBSD map, [rowsM, colsN];
% lambda = regulization parameter: 0 means exact; Inf means affine
%          transformation
% input_points = Nx2 array of coordinates from input image, [rows0, cols0]
% base_points = Nx2 array of coordinates from base image, [rows, cols]
%
% example:
% load CP.mat
% scale = 0.2/(10/107);
% outdim = [650,650];
% input_points(:,1) = input_points(:,1)-450;% to crop the ECC image to a reasonable size
% input_points(:,2) = input_points(:,2)-10;
% TPSTransf('320_5min_2.cpr',outdim, 0,input_points(:,[2,1])/scale,base_points(:,[2,1]))
%
% Reference:
% Y.B. Zhang, A. Elbrønd,F.X. Lin, (2014) “A method to correct spatial 
% distortion in EBSD maps”, Materials Characterization, 96: 158-165.
%
% YuBin Zhang, 2013. 12. 12
% This program is modefied based on the program by Fitzgerald J
% Archibald Date: 07-Apr-09
%

% read EBSD map
[OD,Head,CPR] = read_EBSD_tpswarp(FileName);
img = reshape_EBSD_Data(Head,OD);

% Initialization
NPs = size(input_points,1); % number of landmark points

imgH = size(img,1); % height
imgW = size(img,2); % width

outH = outDim(1);%rows
outW = outDim(2);%cols

% landmark in input
Xp = input_points(:,1)';
Yp = input_points(:,2)';

% landmark in output (homologous)
Xs = base_points(:,1)';
Ys = base_points(:,2)';

% Compute thin-plate spline mapping [W|a1 ax ay] using landmarks
[wL]=computeWl(Xp, Yp, NPs,lambda);
wY = [Xs(:) Ys(:); zeros(3,2)]; % Y = ( V| 0 0 0)'   where V = [G] where G is landmark homologous (nx2) ; Y is col vector of length (n+3)
wW = wL\wY; % (W|a1 ax ay)' = inv(L)*Y

% Thin-plate spline mapping (Map all points in the plane)
% f(x,y) = a1 + ax * x + ay * y + SUM(wi * U(|Pi-(x,y)|)) for i = 1 to n
[Xw, Yw]=tpsMap(wW, outH, outW, Xp, Yp, NPs);

% input grid for warping
[X,Y] = meshgrid(1:outH,1:outW); % HxW
%interp.method = 'none';% make it as input later....

%% initialization
color = size(img,3);
imgwr = zeros(outH,outW,color); % output image

%% Round warping coordinates
% rounding warped coordinates
Xwi = round(Xw);
Ywi = round(Yw);

% Bound warped coordinates to image frame
indx = [find(Xwi<1);find(Xwi>imgH)];
indy = [find(Ywi<1);find(Ywi>imgW)];
ind = [indx;indy];
Xwi(ind) =  [];
Ywi(ind) = [];
X(ind) = [];
Y(ind) = [];

% Convert 2D coordinates into 1D indices
fip = sub2ind([outH,outW],X,Y); % warped coordinates
fiw = sub2ind([imgH,imgW],Xwi,Ywi); % input

temp2 = zeros(outH,outW);
for colIx = 1:color
    temp = img(:,:,colIx);
    temp2(fip) = temp(fiw);
    imgwr(:,:,colIx) = temp2;
end

% Save file as cpr
CPR.FileName = [CPR.FileName(1:end-4),'_tps.cpr'];
CPR.Job.xCells = num2str(outW);
CPR.Job.yCells = num2str(outH);
CPR.Job.NoOfPoints = num2str(outH*outW);%important for TPS case, where input map size ~= output map size
saveCPR(CPR);
saveCRC(imgwr,CPR);
%imshow(showEBSD(imgwr,'IPF'));
return


function [wL]=computeWl(xp, yp, np,lambda)
rXp = repmat(xp(:),1,np); % 1xNp to NpxNp
rYp = repmat(yp(:),1,np); % 1xNp to NpxNp

wR = sqrt((rXp-rXp').^2 + (rYp-rYp').^2); % compute r(i,j)

wK = radialBasis(wR); % compute [K] with elements U(r)=r^2 * log (r^2)
%%%Modified by Yubin Zhang, 2013.11.07, taken regulation into account
mean_wR=mean(wR(:));
lambda=(mean_wR^2)*lambda;
wK = wK + lambda*eye(np);
%%%end
wP = [ones(np,1) xp(:) yp(:)]; % [P] = [1 xp' yp'] where (xp',yp') are n landmark points (nx2)
wL = [wK wP;wP' zeros(3,3)]; % [L] = [[K P];[P' 0]]

return

function [Xw, Yw]=tpsMap(wW, imgH, imgW, xp, yp, np)

[X,Y] = meshgrid(1:imgH,1:imgW); % HxW
X=X(:)'; % convert to 1D array by reading columnwise (NWs=H*W)
Y=Y(:)'; % convert to 1D array (NWs)
NWs = length(X); % total number of points in the plane

% all points in plane
rX = repmat(X,np,1); % Np x NWs
rY = repmat(Y,np,1); % Np x NWs

% landmark points
rxp = repmat(xp(:),1,NWs); % 1xNp to Np x NWs
ryp = repmat(yp(:),1,NWs); % 1xNp to Np x NWs

% Mapping Algebra
wR = sqrt((rxp-rX).^2 + (ryp-rY).^2); % distance measure r(i,j)=|Pi-(x,y)|

wK = radialBasis(wR); % compute [K] with elements U(r)=r^2 * log (r^2)
wP = [ones(NWs,1) X(:) Y(:)]'; % [P] = [1 x' y'] where (x',y') are n landmark points (nx2)
wL = [wK;wP]'; % [L] = [[K P];[P' 0]]

Xw  = wL*wW(:,1); % [Pw] = [L]*[W]
Yw  = wL*wW(:,2); % [Pw] = [L]*[W]

return

function [ko]=radialBasis(ri)

r1i = ri;
r1i(ri==0)=realmin; % Avoid log(0)=inf
ko = 2*(ri.^2).*log(r1i);

return