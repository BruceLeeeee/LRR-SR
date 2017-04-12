
% Creat training images by downscale or rotate testing image for using
% self-similarity method

clear;

p=pwd;
testingSet='Set14';  
testIMG='lenna';
pattern='.bmp';
% flag=0; %  flag: 0-free  1-add noise  2-add blur

upscaling = 2;  %  SR factor

theta=[0 90 180 270];  %  rotate angle

%scale image for creating more training data
numscales=0;
scalefactor=0.90;

input_dir=fullfile(p,testingSet,strcat(testIMG,pattern));
output_dir=fullfile(p,'trainingIMG',[ testingSet '_' testIMG]);
% if flag==1 
%     output_dir=[output_dir '_noise'];
% end
% if flag==2 
%     output_dir=[output_dir '_blur'];
% end

if ~exist(output_dir,'dir')
    mkdir(output_dir);
end


origin=imread(input_dir);
inputIMG=imresize(origin,1/upscaling,'bicubic');
% %add noise
% if flag==1
%     inputIMG = imnoise(inputIMG,'gaussian',0,0.005);%%%%%%%%%%%
% end
% %add blur
% if flag==2
%     G = fspecial('gaussian', [11 11], 2);
%     inputIMG=imfilter(inputIMG,G,'same');%%%%%%%%%%%
% end


for i=1:4
    %rotate
    rotateIMG=imrotate(inputIMG,theta(i));
    imwrite(rotateIMG,[ output_dir '\' testIMG '_r' num2str(theta(i)) '' pattern]);
    
    %scale image for creating more training data
    for scale = 1:numscales
        sfactor = scalefactor^scale;
        scaleIMG = imresize(rotateIMG, sfactor, 'bicubic');
        imwrite(scaleIMG,[ output_dir '\' testIMG '_r' num2str(theta(i)) '_d' num2str(sfactor) '' pattern]);
    end
    
    %flip
    flipIMG=flip(rotateIMG,1);
    imwrite(flipIMG,[ output_dir '\' testIMG '_r' num2str(theta(i)) '_f' pattern]);
    
    %scale image for creating more training data
    for scale = 1:numscales
        sfactor = scalefactor^scale;
        scaleIMG = imresize(flipIMG, sfactor, 'bicubic');
        imwrite(scaleIMG,[ output_dir '\' testIMG '_r' num2str(theta(i)) '_f' '_d' num2str(sfactor) '' pattern]);
    end

end

