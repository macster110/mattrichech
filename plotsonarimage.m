function [s] = plotsonarimage(sonarimages, image )
%PLOTSONARIMAGE Plot the sonar image 

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

end

