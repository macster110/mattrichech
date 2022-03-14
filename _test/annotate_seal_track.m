%% An example of how to read gpl files and then annotate a seal track
clear

gplfile = '/Volumes/JamieBack_1/Tritech/river_sonar_data/20211227/log_2021-12-27-151909.glf';
%seal about halfway through this file.

%frame 200-266
gplfile = '/Volumes/JamieBack_1/Tritech/river_sonar_data/20211212_seal/log_2021-12-12-000518.glf';
%gplfile = '/Volumes/JamieBack_1/Tritech/river_sonar_data/20211209_seal/log_2021-12-09-190821.glf';
% gplfile = '/Volumes/JamieBack_1/Tritech/seal_examples/Genesis/log_2021-12-08-021942.glf';

[filepath,name,ext] = fileparts(gplfile); 

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

% either laod track or make one use the annotation tools.
load('2021-12-12-000518_sealtrack.mat')

% % Mark out a seal track
% n=1;
% for j=1:nimages %iterate through different times
%     ind = j-1;
% 
% 
%     for i=1:length(sonarList) %iterate through different sonars
%         %         cleanData = backgroundSub[i].removeBackground(cleanData, true);
% 
%         rawimage(i,1) = mfc.getSonarRecord(sonarList(i), ind);
%         arawimage = rawimage(i,1).getImageData; % 1D array of points that make up the image
% 
%         sonarimages(i).image = reshape(arawimage, [], rawimage(i,1).getnRange);
%         sonarimages(i).maxrange = rawimage(i,1).getMaxRange;
%         sonarimages(i).nrange = rawimage(i,1).getnRange;
%         sonarimages(i).nbeam = rawimage(i,1).getnBeam;
%         sonarimages(i).bearingtable = rawimage(i,1).getBearingTable; %radians
% 
%         %run background subtractions and save the image
%         [sonarimages(i).background, denoisearr] = removenoise(rawimage(i,1), i);
% 
%         %run the detector and save the image
%         detectedregions = regionDetector.detectRegions(rawimage(i,1) , denoisearr, 70, 30, 8);
% 
%     end
% 
%     disp(['Plotting image ' num2str(j) ' of ' num2str(nimages)])
%     [h] = plotsonarimage(sonarimages(1));
%     caxis([0, 80])
%     title('Raw Image')
%     colormap inferno
%     grid off
% 
%     h = drawcrosshair;
%     if (~isempty(h.Position))
%         sealtrack(n,1) = j; % the frame number.
%         sealtrack(n,[2 3]) = h.Position;
%         n=n+1;
%     end
%     %     subplot(1,3,2)
%     %     [h] = plotsonarimage(sonarimages(1), sonarimages(1).background);
%     %     title('Backgeround subtraction')
%     %     caxis([0, 80])
%     %         colormap inferno
%     %     grid off
% 
% 
%     drawnow;
% 
% end



%% Extract data on the seal track from the sonar images.
sealradius = 4; %meters
noiseradius = 5; %meters
n=1;
cartlocation = [];
sealtrackimage=[];
for j=1:length(sealtrack(:,1)) %iterate through different times
    ind = j-1;


    for i=1:length(sonarList) %iterate through different sonars

        rawimage(i,1) = mfc.getSonarRecord(sonarList(i), sealtrack(j,1));
        arawimage = rawimage(i,1).getImageData; % 1D array of points that make up the image

        sonarimages(i).image = reshape(arawimage, [], rawimage(i,1).getnRange);
        sonarimages(i).maxrange = rawimage(i,1).getMaxRange;
        sonarimages(i).nrange = rawimage(i,1).getnRange;
        sonarimages(i).nbeam = rawimage(i,1).getnBeam;
        sonarimages(i).bearingtable = rawimage(i,1).getBearingTable; %radians


        disp(['Extracting seal data for ' num2str(j) ' of ' ...
            num2str(length(sealtrack(:,1))) '   ' num2str(length(arawimage)) '  ' ....
            num2str(  sonarimages(i).nbeam)  '  '   num2str(sonarimages(i).nrange)])

        %run background subtractions and save the image
        [sonarimages(i).background, denoisearr] = removenoise(rawimage(i,1), i);

        %run the detector and save the image
        detectedregions = regionDetector.detectRegions(rawimage(i,1) , denoisearr, 70, 30, 8);

        %save a region of seal data. Let's save a circle around the seal.

        sealtrackstruct(i,j).imgindex = sealtrack(j,1);
        sealtrackstruct(i,j).x = sealtrack(j,2); % the location in x-y meters
        sealtrackstruct(i,j).y = sealtrack(j,3);
        sealtrackstruct(i,j).rawimage = arawimage;
        sealtrackstruct(i,j).maxrange = rawimage(i,1).getMaxRange;
        sealtrackstruct(i,j).nrange = rawimage(i,1).getnRange;
        sealtrackstruct(i,j).nbeam = rawimage(i,1).getnBeam;
        sealtrackstruct(i,j).bearingtable = rawimage(i,1).getBearingTable; %radians


        %create a lookuptable of the cartesian beam positions
        %TODO - assumes both sonars are the same...
        if (isempty(cartlocation))
            %
            cartlocation = zeros(length(arawimage), 2);
            %now find the index points for the seal region.
            %we take the seal points and figure out which indices are within XZ
            %radius meters.
            ranges =  linspace(0, sonarimages(i).maxrange, sonarimages(i).nrange);
            beams = sonarimages(i).bearingtable;

            [rangesm, beamsm] = meshgrid(ranges,beams); 

            beamsflat = reshape(beamsm, length(arawimage),1); 
            rangesflat = reshape(rangesm, length(arawimage),1); 

            % the arawimage are concatonated beams i.e. [beam1 beam2 beam3 ...]
            % etc.
            for ii= 1:length(arawimage)
%                 arangeind = mod(ii, sonarimages(i).nrange)+1;
%                 beamind = ceil(ii/sonarimages(i).nrange);

%                 [x,y] = pol2cart(beams(beamind),  ranges(arangeind));
                [x,y] = pol2cart(beamsflat(ii),  rangesflat(ii));

                cartlocation(ii,:) = [x y];
            end
        end

        sealregion = [];
        noiseregion = [];
        for ii = 1:length(cartlocation(:,1))

                %marked out area should be a circle. 
                dist = sqrt((sealtrackstruct(i,j).x - cartlocation(ii,1))^2 + ...
                    (sealtrackstruct(i,j).y - cartlocation(ii,2))^2);
    
                if dist<=sealradius
                    sealregion = [sealregion ii];
                end
    
                if dist<noiseradius && dist>sealradius
                    noiseregion = [noiseregion ii];
                end
          
        end

        sealtrackstruct(i,j).sealregionind = sealregion;
        sealtrackstruct(i,j).noiseregionind = noiseregion;

        sealtrackstruct(i,j).seal = arawimage(sealregion);
        sealtrackstruct(i,j).noise = arawimage(noiseregion);

        sealimage = zeros(length(arawimage), 1); 

        sealimage(sealregion) = arawimage(sealregion);

%         [s] = plotsonarimage(sonarimages(i), reshape(sealimage,  [],rawimage(i,1).getnRange)); 

%         scatter(cartlocation(sealregion,1), cartlocation(sealregion,2))
%         colormap inferno

        % add the seal data to a single image so we can plot a seal track.

    end
    %     subplot(1,3,2)
    %     [h] = plotsonarimage(sonarimages(1), sonarimages(1).background);
    %     title('Backgeround subtraction')
    %     caxis([0, 80])
    %         colormap inferno
    %     grid off
    %drawnow;

end


%% Plots of the seal detections
figure(1)

beamq=[];
rangeq=[];

%images are different sizes so need to inteprolate them and then add
%together.
for i=1:length(sealtrackstruct)
    ranges =  linspace(0, sealtrackstruct(i).maxrange, sealtrackstruct(i).nrange);
    beams = sealtrackstruct(i).bearingtable;

    %image of zeros with just the seal deteciton added.
    sealtrackimage = zeros(length(sealtrackstruct(i).rawimage),1);

    sealtrackimage(sealtrackstruct(i).sealregionind) = sealtrackstruct(i).rawimage(sealtrackstruct(i).sealregionind);

    seatrackimage2 =  reshape(sealtrackimage, [], sealtrackstruct(i).nrange);

    [beamsm,rangesm] = meshgrid(beams,ranges);


    if (isempty(beamq))
        beamq = beamsm; 
        rangeq = rangesm; 
        sealtrackcomp = zeros(length(beamsm(1,:)), length(beamsm(:,1)));
    end

    if (sum(size(beamq)) ~= sum(size(beamsm)))
        sealtrackq = interp2(beamsm,rangesm,seatrackimage2', beamq, rangeq);
    else
        sealtrackq = seatrackimage2';
    end

    %TODO - not great because overlapping bits are added to each other...
    sealtrackcomp=sealtrackq'+sealtrackcomp;

end


[XX, YY] = pol2cart(beamq, rangeq); 
s = surf(XX,YY,sealtrackcomp','edgecolor','interp');
xlabel('x (m)')
ylabel('y (m)')
view([-90, 90])
axis equal
xlim([0,55])
ylim([-45,45])
caxis([100, 330])
colormap default

figure(2)
%% plot the noise versus with range?
edges = 0:2:80; 
for j=1:length(sealtrack(:,1)) %iterate through different times

    sealsig = sealtrackstruct(j).seal; 
    noisesig = sealtrackstruct(j).noise;

    sealsignal(j,1) = max(sealsig); % peak
    noisesignal(j,1) = max(noisesig); % peak


    sealsignal(j,2) = mean(sealsig); % mean
    noisesignal(j,2) = mean(noisesig); % mean

    sealsignal(j,3) = std(double(sealsig))*2; % std
    noisesignal(j,3) = std(double(noisesig))*2; % std

    [sealsigsurf(j,:),edges] = histcounts(sealsig,edges); 
    [noisesigsurf(j,:),edges] = histcounts(noisesig,edges); 

end

% surface data for noise histograms. 
[X,Y] = meshgrid(1:length(sealtrack(:,1)), edges(1:end-1));

cols = getdefaultcols; 
clf
hold on 

time  = 1:length(sealtrack(:,1)); 

h1 = plot(time, sealsignal(:,1));
h2 = plot(time, noisesignal(:,1));

%seal
sealupper = sealsignal(:,2) - sealsignal(:,3); 
sealower = sealsignal(:,2) + sealsignal(:,3);

ciplot(sealupper,sealower,  time, cols(1,:));
hc1  = plot(time, sealupper, 'Color', cols(1,:), 'LineStyle', '--');
plot(time, sealower, 'Color', cols(1,:), 'LineStyle', '--')

%noise 
noiseupper = noisesignal(:,2) - noisesignal(:,3); 
noiselower = noisesignal(:,2) + noisesignal(:,3);

ciplot(noiseupper, noiselower,  1:length(sealtrack(:,1)), cols(2,:));
hc2 = plot(time, noiseupper, 'Color', cols(2,:), 'LineStyle', '--');
plot(time, noiselower, 'Color', cols(2,:), 'LineStyle', '--')

legend([h1, h2, hc1, hc2], {'Peak seal', 'Peak noise', 'CI seal', 'CI noise'})
xlabel('Time (frames)')
ylabel('Amplitude (no idea of units)')
set(gca, 'FontSize', 14)


% hold on
% s1 = surf(X,Y,sealsigsurf','FaceAlpha',0.5, 'EdgeColor', 'none');
% colormap autumn
% 
% s2 = surf(X,Y,noisesigsurf','FaceAlpha',0.5, 'EdgeColor', 'none');
% colormap autumn

% subplot(1,3,3)
% [h] = plotsonarimage(sonarimages(1), sealtrackimage);
% title('Seal Track')
% caxis([0, 80])
% colormap inferno
% grid off





