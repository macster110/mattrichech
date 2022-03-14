%plot the background noise for a gpl file

%% An example of how to read gpl files.
clear

gplfolder = '/Volumes/JamieBack_1/Tritech/river_sonar_data/20211227/';
fileList = dir(fullfile(gplfolder, '*.glf'));


% need to add the jar to the java path
p = mfilename('fullpath');
[filepath,~,~] = fileparts(p);

% javajarpath=[filepath '/cetsim_1_0.jar'];
%new version with snap prob det
javajarpath=[filepath '/tritechFile_01.jar'];

javaaddpath(javajarpath);

mfc = tritechgemini.fileio.MultiFileCatalog;

% pre allocate large arrays
backnoisemedian = zeros(2000*length(fileList), 1580);
backnoisemean = zeros(2000*length(fileList), 1580);


n=1;
for k=1:length(fileList)

    mfc.catalogFiles(fullfile(fileList(k).folder, fileList(k).name));

    nimages = mfc.getTotalRecords;

    % get the sonar ID - there can be more than one sonar
    sonarList = mfc.getSonarIDs();

    % minTime = mfc.getRecord(0).getRecordTime();

    rawimage = javaArray('tritechgemini.imagedata.GeminiImageRecordI',length(sonarList), 1);

    backgroundsub = javaArray('tritechgemini.detect.BackgroundSub', length(sonarList));

    for j=1:nimages %iterate through different times
        ind = j-1;
        disp(['Processing image ' num2str(j) ' of ' num2str(nimages) ' from file ' num2str(k) ' of ' num2str(length(fileList))])
        for i=1:length(sonarList) %iterate through different sonars
            %         cleanData = backgroundSub[i].removeBackground(cleanData, true);
    	    rawimage(i,1) = mfc.getSonarRecord(sonarList(i), ind);
            sonarimages(i).image = reshape(rawimage(i,1).getImageData, [], rawimage(i,1).getnRange);
            sonarimages(i).maxrange = rawimage(i,1).getMaxRange;
            sonarimages(i).nrange = rawimage(i,1).getnRange;
            sonarimages(i).nbeam = rawimage(i,1).getnBeam;
            sonarimages(i).bearingtable = rawimage(i,1).getBearingTable; %radians

            if (isempty(backgroundsub(i,1)))
                backgroundsub(i,1) = tritechgemini.detect.BackgroundSub;
            end
            % do the background subtraction in Java
            sonarimages(i).background = reshape(backgroundsub(i,1).removeBackground(rawimage(i,1).getImageData, true),  [], rawimage(i,1).getnRange);
        end

        backnoisemean(j,:) = median(sonarimages(i).background); % range bins
        backnoisemedian(j,:)= mean(sonarimages(i).background);
        n=n+1; 
    end
end

backnoisemean = backnoisemean(1:n-1, :); 
backnoisemedian = backnoisemedian(1:n-1, :); 

clf
hold on
ranges =  linspace(0, sonarimages(1).maxrange, sonarimages(1).nrange);
plot(ranges, mean(backnoisemean));
plot(ranges, mean(backnoisemedian));
xlabel('Range (m)')
ylabel('Noise (relative)')
legend('Mean of median' , 'Mean of mean')
set(gca, 'FontSize', 14);
hold off


