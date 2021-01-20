function [names] = PSR_subjects(folder,extension,displaynow,nchar)

%% check input
if ~exist('extension','var') || isempty(extension)
    extension = '.mat';
end

if ~exist('displaynow','var') || isempty(displaynow)
    displaynow = false;
end

if ~exist('nchar','var') || isempty(nchar)
    nchar = 12;
end

%% read from folder
if ~strcmp(extension,'isdir')
    % get filenames
	files = dir(fullfile(char(folder), strcat('*', char(extension))));
	filenames = cat(1,files.name);

    % print subject names
    names = cell(size(filenames,1),1);
    for k = 1:size(filenames,1)
        if displaynow
            fprintf('%s\n',filenames(k,1:nchar));
        end
        names(k) = {filenames(k,1:nchar)};
    end

else
    % get foldernames
    content = dir(folder);
    content = content(arrayfun(@(k) length(content(k).name), 1:length(content))>2);

    % in case of folders, other than for each subject, we'll use a very
    % quick-dirty work around: all subject folders start with date in 20th
    % century, i.e. first two elements are always "19" for subject. We'll
    % just assume that no other folders have the same property, and if so
    % we'll risk the error...
    select = arrayfun(@(k) strcmp(content(k).name(1:2),'19'), 1:length(content));
    content = content(select);
    dirnames = cat(1,content.name);

    % print subject names
    names = cell(size(dirnames,1),1);
    for k = 1:size(dirnames,1)
        if displaynow
            fprintf('%s\n',dirnames(k,1:nchar));
        end
        names(k) = {dirnames(k,1:nchar)};
    end

end

end
