function [targettrackdat] = annottrack2struct(gplfile, targettrack, varagin)
%ANNOTTRACK2STRUCT Extracts useful inoformation from a sonar images and a
%seal track. 
%    [SEALTRACKDAT] = ANNOTTRACK2STRUCT(SEALTRACK,GPLFILE) extracts images,
%    signal and noise information from a set of sonar images in which there
%    a target track has been annotated. GPLFILE is a path to the gplfile
%    that contains the animal track. SEALTRACK is a 3 column array (framel
%    x (m), y(m)) which holds the animal track. For each frame in which an
%    animal is presen a 2.5x2.5 meter image is extracted, along with the
%    signal levels 1m radius around the track and nouse levels, 1-5 meters
%    around the track. These are packaged into a struct TARGETTRACKDAT.
%    TARGETTRACKDAT.SONARINFO contains metadata on the filename, max range
%    etc. TARGETTRACKDAT.SEALTRACK contains the extracted data for each frame
%    in which an animal has been annotated - i.e. the length of
%    TARGETTRACKDAT.TARGETTRACK is equal to the length of TARGETTRACK input.
%
%    The fields for SEALTRACKDAT.SEALTRACK are
%%
% * FRAME - the frame number within the file
% * X - the x location of the animal on the sonar image in meters. 
% * Y - the y location of the animal on the sonar image in meters. 
% * MAXRANGE - the maximum range of thge sonar at the frame/ 
% * TARGETSS - a 2.5 by 2.5 meter (default) image of the animal 
% * XX - a 2.5 by 2.5 meter (default) surface of x values
% * YY - a 2.5 by 2.5 meter (default) surface of y values
% * NOISE - all data values at a distance between and 1 and 5 meters around
% the animal
% * TARGET - all values 1m radius around the target. 



sealradius = 1; %seal signal radius in meters
noiseradius = 3; %seal noise radius in meters
rectsize = 2.5;% size of the image for deep learning in meters

dd = dir(gplfile);

[mfc, regionDetector, rawimage] = sonardataj(gplfile);
sonarList = mfc.getSonarIDs();
[~,name,ext] = fileparts(gplfile); 

%Extract data on the seal track from the sonar images.
cartlocation = [];

noiseradius2=noiseradius^2;
sealradius2=sealradius^2;

for j=1:length(targettrack(:,1)) %iterate through different times

    for i=1:length(sonarList) %iterate through different sonars

        % I think the matlab frames are 1 indexed. the Java call
        % getSonarRecord needs 0 indexed. The correct indexing is used in
        % the annotate_seal_tracks function at line 62 where the index is
        % the frame number - 1. 
        rawimage(i,1) = mfc.getSonarRecord(sonarList(i), targettrack(j,1)-1);
        arawimage = int16(rawimage(i,1).getImageData); % 1D array of points that make up the image
        neg = find(arawimage < 0);
        arawimage(neg) = arawimage(neg) + 256;

        sonarimages(i).image = reshape(arawimage, [], rawimage(i,1).getnRange);
        sonarimages(i).maxrange = rawimage(i,1).getMaxRange;
        sonarimages(i).nrange = rawimage(i,1).getnRange;
        sonarimages(i).nbeam = rawimage(i,1).getnBeam;
        sonarimages(i).bearingtable = rawimage(i,1).getBearingTable; %radians


        disp(['Extracting seal data for ' num2str(j) ' of ' ...
            num2str(length(targettrack(:,1))) '   ' num2str(length(arawimage)) '  ' ....
            num2str(  sonarimages(i).nbeam)  '  '   num2str(sonarimages(i).nrange)])

        %run background subtractions and save the image
%         [sonarimages(i).background, denoisearr] = removenoise(rawimage(i,1), i);

        %run the detector and save the image
%         detectedregions = regionDetector.detectRegions(rawimage(i,1) , denoisearr, 70, 30, 8);

        %save a region of seal data. Let's save a circle around the seal.

        sealtrackstruct(i,j).imgindex = targettrack(j,1);
        sealtrackstruct(i,j).x = targettrack(j,2); % the location in x-y meters
        sealtrackstruct(i,j).y = targettrack(j,3);
        sealtrackstruct(i,j).maxrange = rawimage(i,1).getMaxRange;

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
        rectregion=[];
        xx=[];
        yy=[];
        for ii = 1:length(cartlocation(:,1))

            %marked out area for noise analysis should be a circle.
            dist = ((sealtrackstruct(i,j).x - cartlocation(ii,1))^2 + ...
                (sealtrackstruct(i,j).y - cartlocation(ii,2))^2);

            if dist<=sealradius2
                sealregion = [sealregion ii];
            end

            if dist<noiseradius2 && dist>sealradius2
                noiseregion = [noiseregion ii];
            end

            %also want a rectangular region to train deep learning
            %models
            if (abs(cartlocation(ii,1)-sealtrackstruct(i,j).x)<rectsize/2 ...
                    && abs(cartlocation(ii,2)-sealtrackstruct(i,j).y)<rectsize/2)
                rectregion = [rectregion ii];
                xx = [xx cartlocation(ii,1)];
                yy = [yy cartlocation(ii,2)];

            end
        end

        sealtrackstruct(i,j).seal = arawimage(sealregion);
        sealtrackstruct(i,j).noise = arawimage(noiseregion);
        sealrect = arawimage(rectregion);

        [XX,YY] = meshgrid((min(xx)+0.1):0.1:max(xx), (min(yy)+0.1):0.1:max(yy));
        targetXX = griddata(xx,yy, double(sealrect),XX,YY);


        sealtrackstruct(i,j).XX = XX;
        sealtrackstruct(i,j).YY = YY;
        sealtrackstruct(i,j).targetSS = targetXX;


        %write file header info if needed
        if (j==1)
            sealheader(i).file = [name,ext];
            sealheader(i).frames = [name,ext];
            sealheader(i).maxrange = sonarimages(i).maxrange;
        end
        
        rawimage(i,1).freeImageData();

    end

end


targettrackdat.sonarinfo = sealheader;
targettrackdat.targettrack = sealtrackstruct;

end

