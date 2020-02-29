function saveCPR(CPR)
%%% save Channel 5 CPR file

%%%
%%%Yubin Zhang, 2011,11
%%%

names = fieldnames(CPR);
eval(['FileName = CPR.' names{1} ';']);
%fn = [FileName,'.cpr'];
fid = fopen(FileName,'w');
for i = 2:length(names)
    NStr = strrep(names{i},'_',' '); %remove space
    fprintf(fid,'%s\n',['[',NStr,']']);
    eval(['str = CPR.' names{i} ';']);
    namei = fieldnames(str);
    for j = 1:length(namei)
        %%getfiled works also stri = getfield(str,namei{j});
        eval(['stri = str.' namei{j} ';']);
        fprintf(fid,'%s\n',[namei{j},'=',stri]);
    end
end
fclose(fid);