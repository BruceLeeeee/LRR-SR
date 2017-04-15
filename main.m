
clear;  
    
p = pwd;
addpath(fullfile(p, '/methods'));  % the SR methods

test_dir = 'testingIMG'; % Directory with testing images
train_dir = 'trainingIMG/Set14_lenna'; % Directory with training images
result_dir = 'result'; 
pattern = '*.bmp'; % Pattern to process

method = 'LLE'; % SR method
upscaling = 2; % % the magnification factor x2, x3, x4...
conf.scale = upscaling; % scale-up factor
conf.level = 1; % # of scale-ups to perform
conf.window = [3 3]; % low-res. window size
conf.border = [1 1]; % border of the image (to ignore)
conf.upsample_factor = upscaling; % upsample low-res. into mid-res
O = zeros(1, conf.upsample_factor-1);
G = [1 O -1]; % Gradient
L = [1 O -2 O 1]/2; % Laplacian
conf.filters = {G, G.', L, L.'}; % 2D versions
conf.interpolate_kernel = 'bicubic';
conf.overlap = conf.window - [1 1]; % full overlap scheme (for better reconstruction) 
conf.filenames = glob(test_dir, pattern); % testing image Cell array
k_nn = 8; % number of nearest neighbour for each test patch

if exist('phires.mat', 'file') && exist('plores_ft.mat', 'file')
    load('plores_ft');
    load('phires');
else
    [plores_ft,phires,phires_ft] = collect_samples(conf, load_images(...            
    glob(train_dir, pattern)), 1, 1); 
   save('plores_ft.mat','plores_ft');
%    save('plores_ft_pca.mat','plores_ft_pca');
   save('phires.mat','phires');
   save('phires_ft.mat','phires_ft');
end

reslut_name = {'Original', 'Bicubic', method};

res =[];
for i = 1:numel(conf.filenames)
    f = conf.filenames{i};
    [p, n, x] = fileparts(f);
    [img, imgCB, imgCR] = load_images({f}); 

    sz = size(img{1});

    fprintf('%d/%d\t"%s" [%d x %d]\n', i, numel(conf.filenames), f, sz(1), sz(2));

    img = modcrop(img, conf.scale);
    imgCB = modcrop(imgCB, conf.scale);
    imgCR = modcrop(imgCR, conf.scale);

    low = resize(img, 1/conf.scale, conf.interpolate_kernel);
    if ~isempty(imgCB{1})
        lowCB = resize(imgCB, 1/conf.scale, conf.interpolate_kernel);
        lowCR = resize(imgCR, 1/conf.scale, conf.interpolate_kernel);
    end

    interpolated = resize(low, conf.scale^conf.level, conf.interpolate_kernel);
    if ~isempty(imgCB{1})
        interpolatedCB = resize(lowCB, conf.scale, conf.interpolate_kernel);    
        interpolatedCR = resize(lowCR, conf.scale, conf.interpolate_kernel);    
    end
    
    res{1} = interpolated;
    
    if (strcmp(method,'SR_LLE') == 1)
        res{2} = SR_LLE(conf, low, k_nn);
    elseif (strcmp(method,'SR_LRR') == 1)
        res{2} = SR_LRR(conf, low, k_nn);
    elseif (strcmp(method,'SR_LRR_ML') == 1)
        res{2} = SR_LRR_ML(conf, low, k_nn);
    else
        fprintf('Undefined method, using bicubic');
        res{2} = interpolated;
    end
    
    result = cat(3, img{1}, interpolated{1}, res{2}{1});
    
    result = shave(uint8(result * 255), conf.border * conf.scale);
    if ~isempty(imgCB{1})
        resultCB = interpolatedCB{1};
        resultCR = interpolatedCR{1};           
        resultCB = shave(uint8(resultCB * 255), conf.border * conf.scale);
        resultCR = shave(uint8(resultCR * 255), conf.border * conf.scale);
    end
    
    
    for j = 1:3            
        imwrite(result(:, :, j), fullfile(result_dir, [n sprintf('[%d-%s]', j, reslut_name{j}) x]));
        if ~isempty(imgCB{1})
            rgbImg = cat(3,result(:,:,j),resultCB,resultCR);
            rgbImg = ycbcr2rgb(rgbImg);
        else
            rgbImg = cat(3,result(:,:,j),result(:,:,j),result(:,:,j));
        end
        imwrite(rgbImg, fullfile(result_dir, [n '_RGB' sprintf('[%d-%s]', j, reslut_name{j}) x]));
    end
end