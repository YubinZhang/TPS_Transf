function saveCRC(Data,CPR)
%%%save chennal 5 CRC file
%%%1.phase(uint8) 2-4 eulerangles(single) 5 mad(single) 6 BC (uint8)
%%%7 BS(uint8) 8 bands (uint8) 9 error(uint8) 10 ri(single)(imported data
%%%has no 10)


%%%
%%% Yubin Zhang, 2011,11
%%%

names = fieldnames(CPR);
eval(['FileName = CPR.' names{1}]);
fn = [FileName(1:end-4),'.crc'];
fid = fopen(fn,'wb');
%Write Channel CPR files
s = size(Data);
if size(s,2)==2
    if size(Data,2)== 12
        for j = 1:s(1)
        %if Header(1)==1 %grid scan
            fwrite(fid,Data(j,1),'uint8');
            fwrite(fid,Data(j,4:7),'single');
            fwrite(fid,Data(j,8:11),'uint8');
            fwrite(fid,Data(j,12),'single');
        end
    elseif size(Data,2)==11
        for j = 1:s(1)
        %if Header(1)==1 %grid scan
            fwrite(fid,Data(j,1),'uint8');
            fwrite(fid,Data(j,4:7),'single');
            fwrite(fid,Data(j,8:11),'uint8');
            %fwrite(fid,Data(j,12),'single');
        end
    end
elseif s(3)==11
    for i = 1:s(1)
        for j = 1:s(2)
        %if Header(1)==1 %grid scan
            fwrite(fid,Data(i,j,1),'uint8');
            fwrite(fid,Data(i,j,4:7),'single');
            fwrite(fid,Data(i,j,8:11),'uint8');

        end
    end
elseif s(3) ==12
   for i = 1:s(1)
        for j = 1:s(2)
        %if Header(1)==1 %grid scan
            fwrite(fid,Data(i,j,1),'uint8');
            fwrite(fid,Data(i,j,4:7),'single');
            fwrite(fid,Data(i,j,8:11),'uint8');
            fwrite(fid,Data(i,j,12),'single');
        end
    end
end
fclose(fid);
