function Data_new = reshape_EBSD_Data(Header,Data,opt,Tform)
%reshpe the EBSD data file from mn x 11(12) to m x n x 11(12)


% example:
% FileName = 'test.cpr';
% [OD,Head,CPR] = read_EBSD_tpswarp(FileName);
% ODnew = reshape_EBSP_Data(Head,OD);

%%% Yubin Zhang, 2012.11

x = Header(4);
y = Header(3);
if nargin >2
    z = size(Data,3);
    if strcmp(opt,'Flip') || strcmp(opt,'flip')%for flip: 1, horizontal; 2, vertical
        if Tform == 1
            Data_new = Data(end:-1:1,1:end,:);
        elseif Tform == 2
            Data_new = Data(1:end,end:-1:1,:);
        end
    elseif strcmp(opt,'T') || strcmp(opt,'t')% for transpose:
        Data_new = zeros(y,x,z);
        for i = 1:z
            temp = Data(:,:,i);
            Data_new(:,:,i) = temp';
        end
    end
else
    z = size(Data,2);
    Data_new = zeros(x,y,z);
    for i = 1:z
        temp = Data(:,i);
        Data_new(:,:,i)= reshape(temp,y,x)';
    end
end

