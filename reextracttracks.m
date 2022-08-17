% go through the log files that were annotated by Rob, Ian, Rosie, etc.
% using thecode written by Jamie and re-extract the clips and stats on
% levels, etc. 
logFolder = 'E:\RobRiver\annotated_tracks';
detDatabase = 'E:\RobRiver\RiverSonarProcess_Selection.sqlite3'
% addpath 'C:\Users\dg50\OneDrive - University of St Andrews\MATLAB\MatCode\Tritech\mattrichech-main'
addpath 'C:\Users\dg50\source\repos\mattrichech'
tritechjar = 'C:\Users\dg50\OneDrive - University of St Andrews\MATLAB\MatCode\Tritech\mattrichech-main\tritechFile_02.jar'
glfFolder = 'J:\WithTracks\';
glfFolder = 'J:\Genesis'
glfFiles = dirsub(glfFolder, '*.glf');
secsPerDay = 3600*24;
oneSec = 1./secsPerDay;


logFiles = dirsub(logFolder, '*.mat');

minInd = zeros(1,numel(logFiles));
maxInd = zeros(1,numel(logFiles));
nRec = zeros(1,numel(logFiles));
for i = 1:numel(logFiles)
    figure(1)
    clf
    fprintf('Processing track %d of %d. \n', i, numel(logFiles));
    
    clear sealtrackdat newsealtrackdat
    load(logFiles(i).name)
    if (exist('newsealtrackdat'))
       fprintf('File %d - %s has already been processed.\n', i, logFiles(i).name);
        continue;
    end
        
    [ld logName] = fileparts(logFiles(i).name);
    %     origName = origName(12:32);
    glfName = [logName(12:32) '.glf'];
    glfPath = findBinaryFile(glfFolder, '*.glf', glfName);
    if (i == 1)
     glflog = loadglfxfile(glfPath, tritechjar);
    end
    
    track = sealtrackdat.targettrack;
    imageInd = [track.imgindex];
    x = [track.x];
    y = [track.y];
    trackdata = [imageInd', x', y'];
    newsealtrackdat = annottrack2struct(glfPath, trackdata);
    
    save(logFiles(i).name, 'sealtrackdat', 'newsealtrackdat');
    %     glfxname = fullfile(ld, [logName(12:end) '.glfx'])
    %         dd = dir(glfxname);
%     %         isFile = numel(dd) == 1
%     glflog = loadglfxfile(glfPath, tritechjar);
%     glflog.getNumRecords();
%     
%     startTime = millisToDateNum(glflog.getFirstRecordTime());
%     endTime = millisToDateNum(glflog.getLastRecordTime());
%     %% the annotated track is in a structure called sealtrackdat.targettrack
%     track = sealtrackdat.targettrack;
%     imageInd = [track.imgindex];
%     %imageInd seems to be one indexed - makes sense from the code and there
%     %are lots of min(imateInd) == 1 and none == 0. 
%     minInd(i) = min(imageInd);
%     maxInd(i) = max(imageInd);
%     nRec(i) = glflog.getNumRecords();
%     for t = 1:numel(track)
%         imageRec = glflog.getFullRecord(imageInd(t)-1);
%         imageData = int16(imageRec.getImageData());
%         % deal with negative data. 
%         neg = find(imageData < 0);
%         imageData(neg) = imageData(neg)+256;
%         nBearing = imageRec.getnBeam();
%         nRange = imageRec.getnRange();
%         break
%     end
    
    
    
%     break;
end