% collect training samples, each sample is a patch which has been verorized as a column 
% 
% input: 
%        conf:          confiuration contains some global parameters 
%        ohires:        original high resolution training images
%        numscalse:     specify the number of images created by downscale a training image(create more sample)
%        scalefactor:   downscale factor 
% output:
%        lores_ft:      low resolution feature samples 
%        lores_ft_pca:  reduce lores_ft's dimension by pca
%        hires:         high resolution sample cooresponding to it's low resolution version
%        hires_ft:      high resolution feature samples cooresponding to it's low resolution version

function [lores_ft, hires, hires_ft] = collect_samples(conf, ohires, numscales, scalefactor)

lores_ft = [];
% lores_ft_pca = [];
hires = [];
hires_ft = [];

for scale = 1:numscales
    sfactor = scalefactor^(scale-1);
    chires = resize(ohires, sfactor, 'bicubic');
    
    chires = modcrop(chires, conf.scale); % crop a bit (to simplify scaling issues)
    % Scale down images
    clores = resize(chires, 1/conf.scale, conf.interpolate_kernel);
    midres = resize(clores, conf.upsample_factor, conf.interpolate_kernel);
    features = collect(conf, midres, conf.upsample_factor, conf.filters);
    clear midres

    interpolated = resize(clores, conf.scale, conf.interpolate_kernel);
    clear clores
    patches = cell(size(chires));
    for i = 1:numel(patches) % Remove low frequencies
        patches{i} = chires{i} - interpolated{i};
    end
    clear chires interpolated

    hires = [hires collect(conf, patches, conf.scale, {})];
    hires_ft = [hires_ft collect(conf, patches, conf.scale, conf.filters)]; 
    lores_ft = [lores_ft features];
%     lores_ft_pca = [lores_ft_pca conf.V_pca' * features];
end