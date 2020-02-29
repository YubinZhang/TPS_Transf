function [CHK,Data,Header,CPR] = HKL5read(FileName)
%To open HKL Channel 4&5 CPR and CRC files
%If success CHK returns 0, elsewise CHK returns error code
%CPR file is a TXT file containing project information
%The information is saved to a structure 'CPR'
%CRC file is a binary file containing all experiment data.
%All the data are stored into a matrix 'Data'
%The data stored in the matrix 'Data' is in the format of
%Data(:,[Phase, X, Y, E1, E2, E3, MAD, BC, BS, Bands, Error, RI])
%In HKL Channel version 5:
%For automatic scan mode, the data format is:
%ID	FieldName	Type	Bytes	Description	   
%   Phase	    UInt8	1	    Which phase the data was indexed with. 0=no solution, 1=first phase.   
%3  Euler1	    Single	4	    Euler 1 in radians. Single precision floating point.	   
%4  Euler2	    Single	4	    Euler 2 in radians. Single precision floating point.	   
%5  Euler3	    Single	4	    Euler 3 in radians. Single precision floating point.	   
%6  MAD	        Single	4	    Misfit: Mean Angular Deviation?. Single precision floating point.	   
%7  BC      	UInt8	1	    Band contrast. Unsigned integer, 1 byte, 0-255. 	   
%8  BS      	UInt8	1	    Band slope. Unsigned integer, 1 byte, 0-255.	   
%10 Bands	    UInt8	1	    Number of bands used for indexing. Unsigned integer, 1 byte, 0-255.	   
%11 Error   	UInt8	1	    If Phase=0 this tells the reason. Unsigned integer, 1 byte, 0-255.	   
%12 RI      	Single	4	    If using O-lock this is the misfit value. Single precision floating point.	   
%Total 25 bytes for each data point
%
%For individual scan mode, the data format is:
%ID	FieldName	Type	Bytes	Description	   
%   Phase       UInt8	1	    Which phase the data was indexed with. 0=no solution, 1=first phase.	   
%1	XPos        Single	4       Position of X in microns where 0 is center. Single precision floating point.
%2	YPos        Single	4       Position of Y in microns where 0 is center. Single precision floating point.
%3  Euler1	    Single	4	    Euler 1 in radians. Single precision floating point.	   
%4  Euler2	    Single	4	    Euler 2 in radians. Single precision floating point.	   
%5  Euler3	    Single	4	    Euler 3 in radians. Single precision floating point.	   
%6  MAD	        Single	4	    Misfit: Mean Angular Deviation?. Single precision floating point.	   
%7  BC      	UInt8	1	    Band contrast. Unsigned integer, 1 byte, 0-255. 	   
%8  BS      	UInt8	1	    Band slope. Unsigned integer, 1 byte, 0-255.	   
%10 Bands	    UInt8	1	    Number of bands used for indexing. Unsigned integer, 1 byte, 0-255.	   
%11 Error   	UInt8	1	    If Phase=0 this tells the reason. Unsigned integer, 1 byte, 0-255.	   
%12 RI      	Single	4	    If using O-lock this is the misfit value. Single precision floating point.	   
%Total 33 bytes for each data point
%
%Data: Feb 10th, 2006
%Author: G.L. Wu
%Version: 1.0.0

%To open CPR file
[fid_cpr, errormsg]=fopen(FileName,'r');
if fid_cpr == -1 %Error reading
    CHK = 1;
    Data = [];
    Header = [];
    CPR = [];
    disp(errormsg);
    return
end
CPR = readCPR(FileName);
fclose(fid_cpr);

%Header information
Header = zeros(1,12);
if int8(0.6) %difference of command int8 between Matlab versions
    Header(10) = int8(str2double(CPR.General.Version)-0.5); %Get channel version
else
    Header(10) = int8(str2double(CPR.General.Version));
end
disp(['Channel version ',CPR.General.Version]);
disp(['JobMode ',CPR.General.JobMode]);
if strcmp(CPR.General.JobMode,'RegularGrid')
    Header(1)=1; %grid scan mode
    Header(3)=str2double(CPR.Job.xCells); %xcell
    Header(4)=str2double(CPR.Job.yCells); %ycell
    Header(5)=str2double(CPR.Job.GridDistX); %xstep
    Header(6)=str2double(CPR.Job.GridDistY); %ystep
    if isfield(CPR.Job,'NoOfPoints')
        Header(2)=str2double(CPR.Job.NoOfPoints); %num of data point
    else
        Header(2)=Header(3).*Header(4);
    end
elseif strcmp(CPR.General.JobMode,'Operator')
    Header(1)=2; %interactive scan mode
end
Header(7)=str2double(CPR.Acquisition_Surface.Euler1);
Header(8)=str2double(CPR.Acquisition_Surface.Euler2);
Header(9)=str2double(CPR.Acquisition_Surface.Euler3);
if isempty(CPR.General.Notes) %Import from text file
    disp(CPR.General.Notes);
end
if isfield(CPR.General,'Modified') %Modified CPR file, i.e. SaveAs
    disp('Modified CPR file');
end
NoCol = str2double(CPR.Fields.Count);
FldID = zeros(1,NoCol+1);
skip = zeros(1,NoCol+1);
TotalByte = 4*(NoCol-4)+5; %add Phsae, 1 byte
skip(1) = 1; %Phase
for i = 1:NoCol
    %FldID = 0; %Phase
    FldID(i+1) = str2double(eval(['CPR.Fields.Field',num2str(i)]));
    if FldID(i+1)>=7 && FldID(i+1)<=11
        skip(i+1) = 1;
    else
        skip(i+1) = 4;
    end
end
skip = TotalByte-skip;

%To open CRC file
[fid_crc, errormsg]=fopen([FileName(1:length(FileName)-4),'.crc'],'rb');
if fid_crc == -1 %Error reading
    CHK = 1;
    Data = [];
    disp(errormsg);
    return
else
    CHK = 0; %Success
end

%Read Channel CPR files
if Header(1)==1 %grid scan
    Data = zeros(Header(2),NoCol+3); %add Phase, X, Y
    seek = 1;
    [Data_vec,IP]=fread(fid_crc,inf,'uint8',skip(1)); %Get Phase
    frewind(fid_crc);
    fseek(fid_crc,seek,'bof');
    if IP~=Header(2)
        disp('Data set is incomplete!');
        CHK = 3;
    end
    Data(1:IP,1) = Data_vec;
    for i = 2:NoCol+1
        if FldID(i)>=7 && FldID(i)<=11
            precision = 'uint8';
            seek = seek+1;
        else
            precision = 'single';
            seek = seek+4;
        end
        Data_vec = fread(fid_crc,IP,precision,skip(i));
        frewind(fid_crc);
        fseek(fid_crc,seek,'bof');
        if FldID(i)<10
            Data(1:IP,FldID(i)+1)=Data_vec;
        else
            Data(1:IP,FldID(i))=Data_vec;
        end
    end

    %Handle X, Y
    X = zeros(Header(2),1);
    Y = zeros(Header(2),1);
    x = [0:Header(3)-1]'.*Header(5);
    y = ones(Header(3),1);
    for i = 1:Header(4) %yCell
        Cnt1 = 1+(i-1).*Header(3);
        Cnt2 = i.*Header(3);
        X(Cnt1:Cnt2) = x;
        Y(Cnt1:Cnt2) = y.*(i-1).*Header(6);
    end
    Data(:,2) = X;
    Data(:,3) = Y;
elseif Header(1)==2 %interactive scan mode
    seek = 1;
    [Data_vec,IP]=fread(fid_crc,inf,'uint8',skip(1));
    frewind(fid_crc);
    fseek(fid_crc,seek,'bof');
    if NoCol >= 10
        Data = zeros(IP,NoCol+1); %add Phase
    else
        Data = zeros(IP,NoCol+3); %add Phase, X, Y
    end
    Header(2)=IP;
    Data(:,1)=Data_vec;
    for i = 2:NoCol+1
        if FldID(i)>=7 && FldID(i)<=11
            precision = 'uint8';
            seek = seek+1;
        else
            precision = 'single';
            seek = seek+4;
        end
        Data_vec = fread(fid_crc,IP,precision,skip(i));
        frewind(fid_crc);
        fseek(fid_crc,seek,'bof');
        if FldID(i)<10
            Data(:,FldID(i)+1)=Data_vec;
        else
            Data(:,FldID(i))=Data_vec;
        end
    end
    
    %Handle X, Y
    i = 1;
    CHK = 1;
    while CHK
        i = i+1;
        if Data(1,2)~=Data(i,2)
            Header(5)=Data(i,2)-Data(1,2); %xstep
            CHK = 0; %Exit loop
        end
        if i == Header(2)
            Header(5) = 0; %Line scan
            CHK = 0; %End of data
        end
    end
    i = 1;
    CHK = 1;
    while CHK
        i = i+1;
        if Data(1,3)~=Data(i,3)
            Header(6)=Data(i,3)-Data(1,3); %ystep
            CHK = 0; %Exit loop
        end
        if i == Header(2)
            Header(6) = 0;
            CHK = 0;
        end
    end
    if Header(5) ~= 0 %xcell
        min_x = min(Data(:,2));
        max_x = max(Data(:,2));
        Header(3)=(max_x-min_x)/Header(5)+1;
        Header(3)=double(int32(Header(3)));
    else
        Header(3) = 1; %Line scan
    end
    if Header(6) ~= 0 %ycell
        max_y = max(Data(:,3));
        min_y = min(Data(:,3));
        Header(4)=(max_y-min_y)/Header(6)+1;
        Header(4)=double(int32(Header(4)));
    else
        Header(4) = 1; %Line scan
    end
    if Header(2)==Header(3)*Header(4)
        disp('Grid scan data');
        Header(1) = 1;
    end
else
    disp('Unknown data format!');
    CHK = 2;
    Data = [];
end
fclose(fid_crc);
%End of program!!!