%Panel Number to calibrate
Panel=12;
%panel layout
ActivePanels=zeros(4,3);

%error check
%query(vobj_switch,'SYST:ERROR?')

%save file to folder
folderName='C:\Users\MetaImagerDuo\Documents\MetaImager Project\RF Switch Path Calibration\'  

%parameters
fsamples=101;
fstart=17.5;
fstop=26.5;
IFbandwidth=1000;
power=-10;
avg_factor=10;

%determine number Character
if mod(Panel,size(ActivePanels,1))==0
    numChar=size(ActivePanels,1);
else
    numChar=mod(Panel,size(ActivePanels,1));
end

%determine letter char
if mod(Panel,size(ActivePanels,1))==0
    lettChar=65+(Panel/size(ActivePanels,1))-1;
else
    lettChar=65+floor(Panel/size(ActivePanels,1));
end

%build filenames
filenameFragmentSave=[char(lettChar), num2str(numChar),'RFPathCal'];

%initialize cal data
cal=[];

RFpath=1; %any would work---we are not connected through panel switch for calibrating cables up to switch

%initialize VNA (N5245A) and Switching device (L4445A)
delete(instrfind) %delete any existing instrament objects 
vobj_switch = start_L4445A; %open switch communications
Init_L4445A(vobj_switch); %initialize switches/modules/etc close all switches

vobj_vna = agilent_N5245A_NA_startVISAObject_TCPIP;           %open vna communications
[buffersize, cal.f] = Initialize_N5245A_NoCalFile(vobj_vna, fsamples,fstart,fstop,IFbandwidth,power);

%turn path on
Activate_RFpath_L4445A(vobj_switch, Panel,RFpath);
%activate probe path
fprintf(vobj_switch,'ROUT:CLOS (@1271)')
query(vobj_switch,'*OPC?');

cal.t=zeros(fsamples,1);
for i=1:avg_factor
cal.t=transpose(Read_N5245A(vobj_vna,buffersize,'MeasS31'))+cal.t;
query(vobj_vna,'*OPC?');
end
cal.t = (cal.t)./avg_factor;

%save cal file
save([folderName,filenameFragmentSave],'cal');

test=transpose(Read_N5245A(vobj_vna,buffersize,'MeasS31'));
figure(21);
plot(cal.f,20*log10(abs(test)),cal.f,20*log10(abs(calcorr(test,cal,'through'))));