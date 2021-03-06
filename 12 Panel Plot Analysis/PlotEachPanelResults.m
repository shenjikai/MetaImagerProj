%reconstruct image from each panel of 1-12 panel array given measurement

%parse data. each chunck of H matrix-> 101 freqs X 6 switches= 606 measurement modes per panel
freqs=101;
RF_pathPerPanel=6;
regularization=.0008;
tolerance=1e-5;

%saved scene object to look at
sn=1;
%saved obj
on=1;

% rf data
H = scene_data(sn).H;
g = scene_data(sn).obj_saved(on).measurement;
Z = scene_data(sn).Z;
Az = scene_data(sn).Az;
El = scene_data(sn).El;


%specific slice to image
upsample=1;
slice=3;


% %plot all panels at once
% 
tic
%     fprintf('%s','SVD calculation...')
    %S = svd(Hbasis,'econ');  %move up and out
    opts.tol=1e-3;
    S = svds(H,1,'L',opts)
    while ~any(S) %PREVENTS svds from returning a null vector... not sure why it does this yet
         opts.tol=opts.tol*1e-1
         S = svds(H,1,'L',opts);
    end
    renorm = (max(S)*(1+1e-5))

    Hp = H./renorm;
    gp = g./renorm;
    lam=1e-4 % hardcoded value for ill conditioned matrices --- should be updated as more info is gained about measurement matrices
    %lam = min(S)/max(S)
toc 
Phi = @(x) TVnorm_RI(x,size(El,1),size(Az,2),length(Z));
Psi = @(x,tau) mycalltoTVnewMatrix_RI(x,tau,10,size(El,1),size(Az,2),length(Z));

[obj obj_debias objfunc] = TwIST(gp,Hp,regularization,'lambda',lam,'ToleranceA',tolerance,'Verbose',0,'Phi',Phi,'Psi',Psi,'Monotone',0,'StopCriterion',1);

figure(32)
semilogy(abs(objfunc(2:end)-objfunc(1:(end-1))))
xlabel('twist iteration')
ylabel('magnitude of objective function change')
drawnow

%reshape obj
obj = abs(obj);
nz = length(Z);
nel = size(El,1);
naz = size(Az,2);
nae = nel*naz;
obj3D = zeros(nel,naz,nz);
for zn=1:nz
    objd = obj((1:nae)+nae*(zn-1));
    obj3D(:,:,zn) = reshape(objd,nel,naz);
end

figure(33)
imagesc(tan(Az(1,:))*Z(slice),tan(El(:,1))*Z(slice),upsample_image(obj3D(:,:,slice),upsample));
axis equal
axis tight
axis xy
title('Reconstruction of All Panels at Once');
xlabel('X (m)');
ylabel('Y (m)');
drawnow;


%size of H matrix
Num_Panels=(size(scene_data(sn).H,1)/(freqs*RF_pathPerPanel))
Num_figs=Num_Panels/4;

%kinect scene data
if isfield(scene_data(sn),'rgb')
    %sn = 1;
    rgb = scene_data(sn).rgb;
    xyz = scene_data(sn).xyz;
    azimuth_min = scene_data(sn).Az_extent(1);
    azimuth_max = scene_data(sn).Az_extent(2);
    elevation_min = -scene_data(sn).El_extent(1);
    elevation_max = -scene_data(sn).El_extent(2);
    z_min = scene_data(sn).Z_extent(1);
    z_max = scene_data(sn).Z_extent(2);
    objs = scene_data(sn).objs;
else
    fprintf('%s\n%s\n','Sorry, there''s no Kinect data in this dataset :(.','We can still look at the RF data though.')
end


%figure to plot subfigures into
figure(36)





sumPlot=[];

for i=1:12
    %% scene reconstruction
  Hpanel_i=H(1+freqs*RF_pathPerPanel*(i-1):freqs*RF_pathPerPanel*i,:);
 gpanel_i=g(1+freqs*RF_pathPerPanel*(i-1):freqs*RF_pathPerPanel*i,:);

S = svd(Hpanel_i,'econ');  
Hp = Hpanel_i./(max(S));
gpanel_i = gpanel_i./(max(S));

lam = min(S)/max(S);
Phi = @(x) TVnorm_RI(x,size(El,1),size(Az,2),length(Z));
Psi = @(x,tau) mycalltoTVnewMatrix_RI(x,tau,10,size(El,1),size(Az,2),length(Z));

%l-1 norm minimization
%[obj obj_debias objfunc] = TwIST(g,Hp,regularization,'lambda',lam,'Initialization',0,'MaxiterA',2000,'StopCriterion',1,'ToleranceA',tolerance,'Verbose',0);
%TV minimization
[obj obj_debias objfunc] = TwIST(gpanel_i,Hp,regularization,'lambda',lam,'ToleranceA',tolerance,'Verbose',0,'Phi',Phi,'Psi',Psi,'Monotone',0,'StopCriterion',1);

figure(32)
semilogy(abs(objfunc(2:end)-objfunc(1:(end-1))))
xlabel('twist iteration')
ylabel('magnitude of objective function change')
drawnow

%% reshape reconstructed image vector into 3D scene, plot
obj = abs(obj);
nz = length(Z);
nel = size(El,1);
naz = size(Az,2);
nae = nel*naz;
obj3D = zeros(nel,naz,nz);
for zn=1:nz
    objd = obj((1:nae)+nae*(zn-1));
    obj3D(:,:,zn) = reshape(objd,nel,naz);
end

switch i
    case 1
        plotpos=10;
        plotPanLable='A1';
    case 2
        plotpos=7;
        plotPanLable='A2';
    case 3
        plotpos=4;
        plotPanLable='A3';
    case 4
        plotpos=1;
        plotPanLable='A4';
    case 5
        plotpos=11;
        plotPanLable='B1';
    case 6
        plotpos=8;
        plotPanLable='B2';
    case 7
        plotpos=5;
        plotPanLable='B3';
    case 8
        plotpos=2;
        plotPanLable='B4';
    case 9
        plotpos=12;
        plotPanLable='C1';
    case 10
        plotpos=9;
        plotPanLable='C2';
    case 11
        plotpos=6;
        plotPanLable='C3';
    case 12
        plotpos=3;
        plotPanLable='C4';
end

figure(35)
subplot(4,Num_figs,plotpos);
imagesc(tan(Az(1,:))*Z(slice),tan(El(:,1))*Z(slice),upsample_image(obj3D(:,:,slice),upsample));
axis equal
axis tight
axis xy
title(plotPanLable);
xlabel('X (m)');
ylabel('Y (m)');
%suptitle('Individual Panel Reconstructions')
% set(gcf,'NextPlot','add');
% axes;
% htitle=title('Individual Panel Reconstructions');
% set(gca,'Visible', 'off');
% set(htitle,'Visible', 'on');
%plot_range_slices(obj3D,Az,El,Z,3)
figure(34)
% set(gcf,'NextPlot','add')
% hold on;
if i==1
    sumPlot=upsample_image(obj3D(:,:,slice),upsample)./Num_Panels;
elseif i~1
    sumPlot=sumPlot+upsample_image(obj3D(:,:,slice),upsample)./Num_Panels;
end
imagesc(tan(Az(1,:))*Z(slice),tan(El(:,1))*Z(slice),sumPlot);
axis equal
axis tight
axis xy
title('Sum of Individual Panel Reconstructions')
xlabel('X (m)');
ylabel('Y (m)');
end

