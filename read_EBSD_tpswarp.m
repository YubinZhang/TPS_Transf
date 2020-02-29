function [Data,Header,CPR] = read_EBSD_tpswarp(FileName)
%To read EBSD data files
%Check data format from file extension name
%Then read EBSD data according to data format
%ORI(3,3,Header(2)) is the matrix of orientation of all data
%
%Date: Feb 3rd, 2006
%Author: G.L. Wu
%Version: 1.0.0
%Ranking: ****


[CHK,Data,Header,CPR]=HKL5read(FileName);
if CHK == 0
    Header(12) = 1; % angles are in radians
end

if CHK == 0
    disp(sprintf('Total number of data: %d', Header(2)));
    if Header(1) == 1
        disp(sprintf('Cell size: %d X %d', Header(3),Header(4)));
        disp(sprintf('Step size: %.2f',Header(5)));
    end
    if Header(12)==1
        disp('Euler angles are in radians');
    else
        disp('Euler angles are in degrees');
    end
    Count = 0;
    for i = 1:Header(2)
        if Data(i,1) == 0 % bad point
            Count = Count+1;
        end
    end
    Header(11) = 100.*(1-Count./Header(2)); % index rate
    disp(sprintf('Index rate: %.2f%%',Header(11)));
else
    Data = [];
    Header = [];
    CPR = [];
end
%End of program!