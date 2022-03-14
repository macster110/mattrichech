function [mfc, regionDetector, rawimage] = sonardataj(gplfile)
%SONARDATAJ Loads java code and opens a GPL file
%   Detailed explanation goes here
%% An example of how to read gpl files. 

persistent javajarpath

if isempty(javajarpath)

    % need to add the jar to the java path
    p = mfilename('fullpath');
    [filepath,~,~] = fileparts(p);

    % javajarpath=[filepath '/cetsim_1_0.jar'];
    %new version with snap prob det
    javajarpath=[filepath '/tritechFile_01.jar'];

    javaaddpath(javajarpath);

end

mfc = tritechgemini.fileio.MultiFileCatalog;
mfc.catalogFiles(gplfile);

% nimages = mfc.getTotalRecords;

% get the sonar ID - there can be more than one sonar 
sonarList = mfc.getSonarIDs();

% minTime = mfc.getRecord(0).getRecordTime();

% holds the raw image for each sonar. 
rawimage = javaArray('tritechgemini.imagedata.GeminiImageRecordI',length(sonarList), 1);

%cvreate backgeround subtraction classes which allow the background
%subteactions to take place over multiple images. 
backgroundsub = javaArray('tritechgemini.detect.BackgroundSub', length(sonarList));

% create arraylists to hold all the detected regions
% detectedregions = javaArray('java.util.ArrayList', length(sonarList));

%create the regio  detector for showing regions. 
regionDetector =   tritechgemini.detect.RegionDetector;



end

