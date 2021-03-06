%before calling this function, initilize the Kinect context with:
% [colorVid depthVid] = initializeKinect;

% Get RGB and DEPTH image via Kinect
%% Create context with xml file

%close all
function [Az_extent, El_extent, Z_extent, objs, xyz, rgb] = niImage_getImage_multiobjects_RangeConstraints_fun(colorVid, depthVid)


%% define room boundaries in Metaimager coordinate system (meters)
room_ymin = -0.75;
room_ymax = 1.5;
room_xmax = 0.9;
room_xmin = -0.9;
room_zmax = 2.0;
room_zmin = 0;

%% define Kinect position and orientation in Metaimager coordinate system
%position of kinect (meters)
px = 0.05;
py = 1.22+0.08;
pz = 0.04-0.085;
%kinect optical axis vector (zk vector). We assume that the Kinect is level (xk.y=0)
%An easy way to do this is to measure the position of a point at the center
%of the Kinect field of view and subtract the kinect position vector
zkx = 0.0501-px;
zky = 0.36-py;
zkz = 1.00-pz;

%% calculate kinect orientation unit vectors in metaimager corrdinate system
m = sqrt(zkx^2+zky^2+zkz^2);
zkx = zkx/m;
zky = zky/m;
zkz = zkz/m;
%calculate xk from xk.y=0 and |xk|=1 and assuming xky=0
rt = (zkz/zkx);
xkx = rt^2/(1+rt^2);
xky = 0;
xkz = xkx/rt;
%calculate yk
yk = cross([zkx,zky,zkz],[xkx;xky;xkz]);
ykx = yk(1);
yky = yk(2);
ykz = yk(3);

%% collect a new image from the kinect
%option.adjust_view_point = true;
%mxNiUpdateContext(context,option);
%[rgb, depth] = mxNiImage(context,option);
%rgb = flipdim(rgb,2);
%xyz = double(mxNiConvertProjectiveToRealWorld(context, depth));
%xyz = xyz./1E3; %convert to meters
flushdata(colorVid,'all')
[rgb, depth, xyz] = aquireKinect(colorVid, depthVid);

%transform kinect coordinates to those of the RF coordinate system
xyz = flipdim(xyz,2);

x = xyz(:,:,1);
y = xyz(:,:,2);
z = xyz(:,:,3);
xyz(:,:,1) =  x*xkx + y*ykx + z*zkx;                                                                                                                                                                                                    xyz(:,:,1);
xyz(:,:,2) =  x*xky + y*yky + z*zky; 
xyz(:,:,3) =  x*xkz + y*ykz + z*zkz; 
xyz(:,:,1) = xyz(:,:,1) + px;
xyz(:,:,2) = xyz(:,:,2) + py;
xyz(:,:,3) = xyz(:,:,3) + pz;

%Convert missing data to NaN
xyz(xyz == 0) = NaN;

XYZ = xyz;

%% find walls. walls are object 1
objs = (XYZ(:,:,1)<room_xmin) |...
       (XYZ(:,:,1)>room_xmax) |...
       (XYZ(:,:,2)<room_ymin) |...
       (XYZ(:,:,2)>room_ymax) |...
       (XYZ(:,:,3)>room_zmax) |...
       (XYZ(:,:,3)<room_zmin);
XYZ(repmat(objs,[1,1,3])) = NaN;

%% find objects separated by Z
Z = XYZ(:, :, 3);

%find the number of Z distances greater than corresponding threshold
thresh = room_zmin:150E-3:room_zmax; % the step size here (meters) determines the range-object sensitivity. too small will creat many objects;large will not recognize objects by range.
gt = zeros(1,length(thresh));
for tn=1:length(thresh)
    gt(tn) = sum(sum(Z>=thresh(tn)));
end

%whenever the change in gt goes to zero we have left an object
thresh_prev = thresh(1);
in_obj = false;
for tn=2:length(thresh)
    if (gt(tn)-gt(tn-1))==0 && in_obj
        in_obj = false;
        objs = cat(3,objs, Z>=thresh_prev & Z<=thresh(tn) );
        thresh_prev = thresh(tn);
    elseif (gt(tn)-gt(tn-1))~=0 && ~in_obj
        in_obj = true;
    end
end
%gotta get that last object if we havent left it by the last range threshold...
if in_obj
    objs = cat(3,objs, Z>=thresh_prev & Z<=thresh(end) );
end

%% find objects seperated by x and y

%check for x-separation
objsnew = objs;
for n=1:size(objs,3)
   s = sum(objs(:,:,n),1);
   in_obj = false;
   ind = [];
   objn = 1;
   for nx=2:640 %make a list of object start and stop x indices
       if s(nx)~=0 && ~in_obj
           ind(objn,1) = nx;
           in_obj = true;
       elseif s(nx)==0 && in_obj
           ind(objn,2) = nx-1;
           in_obj = false;
           objn = objn+1;
       end
   end
   %if we found separate objects, identify them
   for objn=2:size(ind,1)
       onew = zeros(480,640);
       onew(:,ind(objn,1):ind(objn,2)) = objs(:,ind(objn,1):ind(objn,2),n);
       oold = objsnew(:,:,n);
       oold(onew==1) = 0;
       objsnew(:,:,n) = oold;
       objsnew = cat(3,objsnew,onew);
   end
end
objs = objsnew;

%check for y-separation
objsnew = objs;
for n=1:size(objs,3)
   s = sum(objs(:,:,n),2);
   in_obj = false;
   ind = [];
   objn = 1;
   for ny=2:480 %make a list of object start and stop x indices
       if s(ny)~=0 && ~in_obj
           ind(objn,1) = ny;
           in_obj = true;
       elseif s(ny)==0 && in_obj
           ind(objn,2) = ny-1;
           in_obj = false;
           objn = objn+1;
       end
   end
   %if we found separate objects, identify them
   for objn=2:size(ind,1)
       onew = zeros(480,640);
       onew(ind(objn,1):ind(objn,2),:) = objs(ind(objn,1):ind(objn,2),:,n);
       oold = objsnew(:,:,n);
       oold(onew==1) = 0;
       objsnew(:,:,n) = oold;
       objsnew = cat(3,objsnew,onew);
   end
end
objs = objsnew;

%% calculate object extents
Nobj = size(objs,3);
Z_extent = zeros(Nobj,2);
Az_extent = zeros(Nobj,2);
El_extent = zeros(Nobj,2);

%objs(objs==0) = NaN;
X = XYZ(:,:,1);
Y = XYZ(:,:,2);
for n=1:Nobj
    obj = objs(:,:,n)==1;
    z = Z(obj);
    Z_extent(n,:) = [min(min(z)) max(max(z))];
    Az = atan(X(obj)./z);
    Az_extent(n,:) = -[max(max(Az)) min(min(Az))];
    El = atan(Y(obj)./z);
    El_extent(n,:) = [min(min(El)) max(max(El))];
end

objs = objs==1;

%% plotting
% imagesc(Z)
% figure;
% objall = zeros(size(Z));
% for n=1:size(objs,3)
%     objall = objall+objs(:,:,n)*n;
% end
% imagesc(objall)
% 
% subplot(2,3,1)
% imagesc(xyzk(:,:,1));axis equal
% subplot(2,3,2)
% imagesc(xyzk(:,:,2));axis equal
% subplot(2,3,3)
% imagesc(xyzk(:,:,3));axis equal
% 
% subplot(2,3,4)
% imagesc(xyz(:,:,1));axis equal
% subplot(2,3,5)
% imagesc(xyz(:,:,2));axis equal
% subplot(2,3,6)
% imagesc(xyz(:,:,3));axis equal
% 
% for n=1:Nobj
%     figure
%     obj = objs(:,:,n)==1; 
%     xyzo = xyz;
%     xyzo(~cat(3,cat(3,obj,obj),obj)) = NaN;
%     subplot(1,3,1)
%     imagesc(xyzo(:,:,1));axis equal
%     subplot(1,3,2)
%     imagesc(xyzo(:,:,2));axis equal
%     subplot(1,3,3)
%     imagesc(xyzo(:,:,3));axis equal
% end
% 
% figure
% rgb2 = rgb;
% rgb2(repmat(abs(xyz(:,:,2))<0.005,[1,1,3]))=0;
% rgb2(240,320,1)=0;rgb2(240,320,2)=255;rgb2(240,320,3)=0;image(rgb2);
% imagesc(rgb2)
