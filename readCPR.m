function CPR = readCPR(filename)
%To read Channel CPR file
%Save all data to a structure CPR
%
%Data: Feb 3rd, 2006
%Author:
%Version: 1.0.0

RawText = textread(filename,'%s','delimiter','\n'); %Get all text
RawText = strrep(RawText,' ','_'); %remove space

ParamSt=strmatch('[',RawText); %find the positions of '['
IP = length(ParamSt); %Total num of '['
ParamSt(end+1) = length(RawText)+1; %add one more

CPR.FileName = filename; %filename

for i= 1:IP %get contents of each item

    str_temp = char(RawText(ParamSt(i))); % get the headings of each item
    ParamEnd(i)=findstr(']',str_temp); %find the position of ']'
    strs(i) = {str_temp(2:ParamEnd(i)-1)}; % get the content of heading

    Header = ['CPR.' char(strs(i))]; %construct data heading
    
    for j = 1:ParamSt(i+1)-ParamSt(i)-1 %go through each item
        
        str_temp = char(RawText(ParamSt(i)+j)); 
        
        if ~isempty(str_temp) %valid strings, not empty lines
            
            EquPos(j) = findstr('=',str_temp);
            
            PVpair(ParamSt(i)+j,1) = {str_temp(1:EquPos(j)-1)};
            PVpair(ParamSt(i)+j,2) = {str_temp(EquPos(j)+1:end)};
            
            StruStr=[Header,'.',char(PVpair(ParamSt(i)+j,1)),'=''' char(PVpair(ParamSt(i)+j,2)) ''';'];
            eval(StruStr)
        
        end

    end
    
    clear EquPos
    
end
%End of program!