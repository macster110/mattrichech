function [s] = plotsonarimage(sonarimages, image)
%PLOTSONARIMAGE Plot the sonar image

gridranges = [20, 40, 60];
gridangles = deg2rad([-60, -30, 0, +30, +60]);

gridColor = [0.3,0.3,0.3]; % rgb colour of the gridlines.

ranges =  linspace(0, sonarimages(1).maxrange, sonarimages(1).nrange);
beams = sonarimages(1).bearingtable;

if nargin<2
    image = sonarimages(1).image;
end

[beamsm,rangesm] = meshgrid(beams,ranges);

[XX,YY] = pol2cart(beamsm,rangesm);

% really important to use edgecolour here because otherwise only surface
% sections of more than one pixel are shown when the plot is view at 0,90.
% Whether this is a feature or bug in MATLAB, who knows.
s = surf(XX,YY,image','edgecolor','interp');
xlabel('x (m)')
ylabel('y (m)')
view([-90, 90])
axis equal
xlim([0,55])
ylim([-45,45])

maxheight = double(max(max(image))+1);

%% plot the grid angles
hold on

for i=1:length(gridangles)
    [polarX, polarY] = pol2cart([gridangles(i); gridangles(i)],[0; sonarimages(1).maxrange]);
    plot3(polarX, polarY, maxheight*ones(length(polarX))', 'Color', gridColor)
end

for i=1:length(gridranges)
    if (gridranges(i)<sonarimages(1).maxrange)
        [polarX, polarY] = pol2cart(beams,  gridranges(i)*ones(length(beams)));
        plot3(polarX, polarY, maxheight*ones(length(polarX))', 'Color', gridColor)
    end
end

