function save(obj,writeDir,writeName,varName)
% Saves the acquisition object. By default uses defaultDir as writeDir and 
% acqName as both writeName and varName
% 
% save(obj,writeDir,writeName,varName)
%
% writeDir is the directory to save the acq in
% writeName is the filename to save the acq as
% varName is the variable name the acq is represented by within the mat file

if ~exist('writeDir','var') || isempty(writeDir)
    writeDir = obj.defaultDir;
end

% computerName = getComputerName;
% switch computerName
%     case 'shin-pc'
%         temp = writeDir;
%         ind = strfind(temp,'SK');
%         writeDir = ['E:\Imaging\',temp(ind:end)];
%         %  writeDir = ['C:\Users\Shin\Documents\MATLAB\ShinDataAll\Imaging\',temp(ind:end)];
%         if ~exist(writeDir,'dir')
%             mkdir(writeDir)
%         end
%         obj.defaultDir = writeDir;
%     case 'harveyscope1'
%         temp = writeDir;
%         ind = strfind(temp,'SK');
%         writeDir = ['E:\Shin\',temp(ind:end)];
%         obj.defaultDir = writeDir;
% end

if ~exist('writeName','var') || isempty(writeName)
    writeName = obj.acqName;
end

if ~exist('varName','var') || isempty(varName)
    varName = obj.acqName;
end

% Make sure that varName is an allowed variable name:
if verLessThan('matlab', '8.3')
    varName = genvarname(varName); %#ok<DEPGENAM>
else
    varName = matlab.lang.makeValidName(varName);
end

eval([varName ' = obj;']),
save(fullfile(writeDir,writeName),varName)

end