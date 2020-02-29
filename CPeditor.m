function  CPeditor(opt,opt2)
% opt = 'EBSD' or 'ECC'; opt2 = 'Create' or 'Edit'

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%To get file name
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
disp ('Input EBSD map that needs to be corrected:');
[FileName,Index]=input_file;
if Index == 0
    return
end

[OD,Head,~] = read_EBSD_tpswarp(FileName);
OD = reshape_EBSP_Data(Head,OD);

BaseImg = showEBSD(OD,'IPF');
clear OD;

if strcmp(opt,'ECC') || strcmp(opt,'ecc')
    disp ('Input ECC image: ');
    [InputImgStr, Pathname] = uigetfile({'*.tif';'*.bmp';'*.jpg';'*.*'},'Input base image');
    InputImg = imread([Pathname InputImgStr]);
    
elseif strcmp(opt,'EBSD') || strcmp(opt,'ebsd')
    fprintf ('\nInput the correct EBSD map:\n');
    [FileName2,Index]=input_file;
    if Index == 0
        return
    end    
    [OD2,Head2,~] = read_EBSD_tpswarp(FileName2);
    OD2 = reshape_EBSP_Data(Head2,OD2);
    InputImg = showEBSD(OD2,'IPF');
    clear OD2;
end

if strcmp(opt2,'Create') || strcmp(opt2,'create')
    [input_points, base_points]= cpselect(InputImg,BaseImg,'wait', true);
    default = 'yes';
    SaveChk = questdlg('Save control points to mat file?',...
        'Save control points','yes','no',default);
    if strcmp(SaveChk, 'yes')
        FileName = input('\nFile name(.mat)...','s');
        save(FileName,'input_points','base_points');
    end
    
elseif strcmp(opt2,'Edit') || strcmp(opt2,'edit')
    fprintf ('\nInput control points file:\n');
    [matfile, Pathname2] = uigetfile({'*.mat';'*.*'},'Load .mat file:');
    eval(['load ' Pathname2 matfile]);
    NameField = whos;
    for i = 1:size(NameField)
        input_str = strncmp(NameField(i).name,'input_points',12);
        if input_str == 1
            eval(['input_points = ' NameField(i).name ';']);
        end
        base_str = strncmp(NameField(i).name,'base_points',11);
        if base_str == 1
            eval(['base_points = ' NameField(i).name ';']);
        end
    end
    cpselect(InputImg,BaseImg,input_points,base_points); 
end



