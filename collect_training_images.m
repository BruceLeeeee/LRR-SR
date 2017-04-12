
% Creat training images by downscale or rotate testing image for using
% self-similarity method

clear;

p = pwd;
testingSet = 'Set14';  
testIMG = 'lenna';
pattern = '.bmp';
% flag=0; %  flag: 0-free  1-add noise  2-add blur

upScaling = 2;  %  SR factor

theta = [0 90 180 270];  %  rotate angle

%scale image for creating more training data
numScales = 0;
scaleFactor = 0.90;

inputDir = fullfile(p, testingSet, strcat(testIMG, pattern));
outputDir = fullfile(p, 'trainingIMG', [testingSet '_' testIMG]);
% if flag==1 
%     output_dir=[output_dir '_noise'];
% end
% if flag==2 
%     output_dir=[output_dir '_blur'];
% end

if ~exist(outputDir, 'dir')
    mkdir(outputDir);
end


origin = imread(inputDir);
inputIMG = imresize(origin, 1/upScaling, 'bicubic');
% %add noise
% if flag==1
%     inputIMG = imnoise(inputIMG,'gaussian',0,0.005);%%%%%%%%%%%
% end
% %add blur
% if flag==2
%     G = fspecial('gaussian', [11 11], 2);
%     inputIMG=imfilter(inputIMG,G,'same');%%%%%%%%%%%
% end


for i = 1:4
    %rotate
    rotateIMG = imrotate(inputIMG, theta(i));
    imwrite(rotateIMG, [outputDir '\' testIMG '_r' num2str(theta(i)) '' pattern]);
    
    %scale image for creating more training data
    for scale = 1:numScales
        sfactor = scaleFactor^scale;
        scaleIMG = imresize(rotateIMG, sfactor, 'bicubic');
        imwrite(scaleIMG,[outputDir '\' testIMG '_r' num2str(theta(i)) '_d' num2str(sfactor) '' pattern]);
    end
    
    %flip
    flipIMG = flip(rotateIMG,1);
    imwrite(flipIMG, [outputDir '\' testIMG '_r' num2str(theta(i)) '_f' pattern]);
    
    %scale image for creating more training data
    for scale = 1:numScales
        sfactor = scaleFactor^scale;
        scaleIMG = imresize(flipIMG, sfactor, 'bicubic');
        imwrite(scaleIMG,[outputDir '\' testIMG '_r' num2str(theta(i)) '_f' '_d' num2str(sfactor) '' pattern]);
    end

end

