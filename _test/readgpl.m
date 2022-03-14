%% An example of how to read gpl files. 
clear

gplfile = '/Volumes/JamieBack_1/Tritech/river_sonar_data/20211227/log_2021-12-27-151909.glf'; 
%seal about halfway through this file. 

%frame 200-266
gplfile = '/Volumes/JamieBack_1/Tritech/river_sonar_data/20211212_seal/log_2021-12-12-000518.glf';
%gplfile = '/Volumes/JamieBack_1/Tritech/river_sonar_data/20211209_seal/log_2021-12-09-190821.glf';

[mfc, regionDetector, rawimage] = sonardataj(gplfile); 

% get the sonar ID - there can be more than one sonar 
sonarList = mfc.getSonarIDs();
nimages = mfc.getTotalRecords;

% settings for the region detector. 
thHigh = 70; 
thLow = 30;
nConnect = 8; 

for j=200:266 %iterate through different times
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
        
        %create a struct for the detected regions.
        if (~isempty(detectedregions))
            index=[];
            for k =0:detectedregions.size()-1
                indexj = detectedregions.get(k).getPointIndexes();
                for kk=0:indexj.size()-1
                    anindex = []; 
                    if (~isempty(indexj.get(kk)))
                        anindex=[anindex indexj.get(kk)];
                    end
                     detectedregiondm(k+1).index = anindex;

                     index = [index, anindex]; 
                end
            end
        end
        
        detectedimage = zeros(length(arawimage),1); 
        detectedimage(index) = arawimage(index); 

        sonarimages(i).detections = reshape(detectedimage, [], rawimage(i,1).getnRange); 
    end

    subplot(1,3,1)
    disp(['Plotting image ' num2str(j) ' of ' num2str(nimages)])
    [h] = plotsonarimage(sonarimages(1)); 
    caxis([0, 80])
    title('Raw Image')
    colormap inferno
    grid off

    subplot(1,3,2)
    [h] = plotsonarimage(sonarimages(1), sonarimages(1).background); 
    title('Background subtraction')
    caxis([0, 80])
        colormap inferno
    grid off

    subplot(1,3,3)
    [h] = plotsonarimage(sonarimages(1), sonarimages(1).detections); 
    title('Detections')
    caxis([0, 80])
    colormap inferno
    grid off

    drawnow; 

end



  




