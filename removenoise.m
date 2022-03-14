function [denoiseimage, denoisearray] = removenoise(image, sonarid)
%REMOVENOISE Removes noise from a sonar image using background subtraction
%   Detailed explanation goes here

persistent backgroundsub;

if isempty(backgroundsub)
    backgroundsub = javaArray('tritechgemini.detect.BackgroundSub', 4);
end

if (isempty(backgroundsub(sonarid,1)))
    backgroundsub(sonarid,1) = tritechgemini.detect.BackgroundSub;
end

% do the background subtraction in Java

denoisearray = backgroundsub(sonarid,1).removeBackground(image.getImageData, true);
denoiseimage = reshape(denoisearray,  [], image.getnRange);

end

