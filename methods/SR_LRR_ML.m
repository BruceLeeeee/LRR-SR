function [imgs, midres] = SR_LRR_ML(conf, imgs, NN)

    load('plores_ft');
    load('phires');
    load('phires_ft')

    %ML
%     D = pdist2_large(phires_ft', phires_ft', 'euclidean');
    D=[];
    [eigvector] = MetricImitation(plores_ft', phires_ft', D, NN, 'Eigenmaps');
    plores = (plores' * eigvector)'; %preject trainning sample 
    clear D;
    
% Super-Resolution Iteration
    fprintf('SR_LRR_ML');
    midres = resize(imgs, conf.upsample_factor, conf.interpolate_kernel);

    for i = 1:numel(midres)
        features = collect(conf, {midres{i}}, conf.upsample_factor, conf.filters);
        features = double(features);
%         features = conf.V_pca'*features;

        features = (features' * eigvector)'; %preject testing sample 
        
        patches = zeros(size(conf.dict_hires,1), size(features,2));

%         D = pdist2(single(plores'),single(features')); %  faster but need more memory
        for t = 1:size(features,2)
%             [~, idx] = sort(D(:,t));
            D = pdist2(single(plores'),single(features(:,t)'));
            [~, idx] = sort(D);
%             D = abs(plores'*features(:,t));
%             [~, idx] = sort(D,'descend'); 

            % use references[2] method for low rank representation
            [coeffs,~] = lrraffine(features(:,t),plores(:,idx(1:NN)),1);

            % Reconstruct using patches' dictionary            
            patches(:,t) = phires(:,idx(1:NN))*coeffs; 
        end       
                
        % Add low frequencies to each reconstructed patch        
        patches = patches + collect(conf, {midres{i}}, conf.scale, {});
        
        % Combine all patches into one image
        img_size = size(imgs{i}) * conf.scale;
        grid = sampling_grid(img_size, ...
            conf.window, conf.overlap, conf.border, conf.scale);
        result = overlap_add(patches, img_size, grid);
        imgs{i} = result; % for the next iteration
        fprintf('.');
    end
fprintf('\n');
clear D;
