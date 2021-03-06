%% Annotate a seal track from a file. 
% Relevent data are then extracted from file and saved as a MATLAB struct. 
% Result are saved to the same folder as the gpl file. 
clear
clear global

%Input needs to be a file and a list of frames in which the animal is
%present. 
% gplfile = '/Volumes/JamieBack_1/Tritech/river_sonar_data/20211212_seal/log_2021-12-12-000518.glf';
% frames = 200:257;
% 
% gplfile = '/Volumes/JamieBack_1/Tritech/seal_examples/Genesis/log_2021-12-09-223320.glf';
% frames = 847:925;
% 
% gplfile = '/Volumes/JamieBack_1/Tritech/seal_examples/Genesis/log_2021-12-09-051731.glf';
% frames = 879:909;
% 
% gplfile = '/Volumes/JamieBack_1/Tritech/seal_examples/Genesis/log_2021-12-10-200120.glf';
% frames = 579:754; 
% 
% gplfile = '/Volumes/JamieBack_1/Tritech/seal_examples/Genesis/log_2021-12-11-193123.glf';
% frames = 461:527;
% 
% gplfile = '/Volumes/JamieBack_1/Tritech/seal_examples/Genesis/log_2021-12-19-004852.glf';
% frames = 76:111; 

gplfile = '/Volumes/JamieBack_1/Tritech/seal_examples/Genesis/log_2021-12-19-164726.glf';
frames =  750:782; 

% gplfile = '/Volumes/JamieBack_1/Tritech/seal_examples/Genesis/log_2021-12-20-121345.glf';
% frames = 457:532;

% set to true to plot background subtraction
backgroundsub = true; 
%the number of frames to skip when annotating. Set to 1 to view all frames.
skipframe = 4; 

%grab info on the file
[filepath,name,ext] = fileparts(gplfile);

%load the sonar images
[mfc, regionDetector, rawimage] = sonardataj(gplfile);

% use a circle area of square area.
circarea = true;

% get the sonar ID - there can be more than one sonar
sonarList = mfc.getSonarIDs();
nimages = mfc.getTotalRecords;

% settings for the region detector.
thHigh = 70;
thLow = 30;
nConnect = 8;

% keep a record of zoomed limits
surfxlim=[]; 
surfylim=[]; 
%% Mark out a seal track
n=1;
for j=min(frames):skipframe:max(frames)%iterate through different times
    ind = j-1;


    for i=1:length(sonarList) %iterate through different sonars
        %         cleanData = backgroundSub[i].removeBackground(cleanData, true);

        rawimage(i,1) = mfc.getSonarRecord(sonarList(i), ind);
        arawimage = rawimage(i,1).getImageData; % 1D array of points that make up the image

        sonarimages(i).image = reshape(arawimage, [], rawimage(i,1).getnRange);
        sonarimages(i).maxrange = rawimage(i,1).getMaxRange;
        sonarimages(i).nrange = rawimage(i,1).getnRange;
        sonarimages(i).nbeam = rawimage(i,1).getnBeam;
        sonarimages(i).bearingtable = rawimage(i,1).getBearingTable; %radians

        %run background subtractions and save the image
        [sonarimages(i).background, denoisearr] = removenoise(rawimage(i,1), i);

        %run the detector and save the image
        detectedregions = regionDetector.detectRegions(rawimage(i,1) , denoisearr, 70, 30, 8);

    end

    zoffset = 0; 
    sonarimages(1).image=double(sonarimages(1).image)-zoffset; 
    disp(['Plotting image ' num2str(j) ' of ' num2str(nimages)])
    if (backgroundsub)
        % plot background subtracted image
        [h] = plotsonarimage(sonarimages(1), sonarimages(1).background);
        title(['Raw Image: frame: ' num2str(j)])
    else
        % plot the raw image
        [h] = plotsonarimage(sonarimages(1));
        title(['Background subtracted Image: frame: ' num2str(j)])
    end

    if (~isempty(surfxlim))
        xlim(surfxlim);
        ylim(surfylim);
    end

    caxis([0, 80]-zoffset)
    colormap default
    grid off

    h = drawcrosshair;
    if (~isempty(h.Position))
        sealtrack(n,1) = j; % the frame number.
        sealtrack(n,[2 3]) = h.Position;
        n=n+1;
    end

    drawnow;


    fig = gca; 
        % keep a record of the lims
    surfxlim = fig.XLim; 
    surfylim = fig.YLim; 
end


if (skipframe>1)
    %linear inteprolation of the track.
    sealtrackxv = interp1(sealtrack(:,1), sealtrack(:,2), frames); 
    sealtrackyv = interp1(sealtrack(:,1), sealtrack(:,3), frames); 
    
    sealtrackinterp = [frames' sealtrackxv' sealtrackyv']; 

else
    sealtrackinterp = sealtrack; 
end


%% extract the required data from the marked out seal using the sonar data. 
% % for testing
% load('2021-12-12-000518_sealtrack.mat')
% frames = 200:257;
[sealtrackdat] = annottrack2struct(gplfile, sealtrackinterp); 


%% Plot the data
f = figure(1);
clf
% do some potting of the tracks
hold on
for i=1:length(sealtrackdat.targettrack)
    surf(sealtrackdat.targettrack(i).YY, sealtrackdat.targettrack(i).XX, ...
        sealtrackdat.targettrack(i).targetSS, 'EdgeColor', 'none')
end
title(['Seal track ' name], 'Interpreter', 'none')
xlabel('y (m)')
ylabel('x (m)')
c= colorbar;
c.Label.String = 'Amplitude'; 
c.Label.FontSize = 14; 
set(gca, 'FontSize', 14)
caxis([0, 80])

% %%save the data
% save(fullfile(filepath, ['seal_track_', name '.mat']), 'sealtrackdat'); 
% saveas(gcf, fullfile(filepath, ['seal_track_' name '.png'])); 
