function [imgs, midres] = SR_LLE(conf, imgs, NN)

    load('plores_ft');
    load('phires');

% Super-Resolution Iteration
    fprintf('SR_LLE');
    midres = resize(imgs, conf.upsample_factor, conf.interpolate_kernel);
    
    
    for i = 1:numel(midres)
        features = collect(conf, {midres{i}}, conf.upsample_factor, conf.filters);
        features = double(features);
%         features = conf.V_pca'*features;
        
        patches = zeros(size(conf.dict_hires,1), size(features,2));
        tol = 0.0001;
        
%         D = pdist2(single(plores'),single(features')); %  faster but need more memory
        for t = 1:size(features,2)
%             [~, idx] = sort(D(:,t));
            D = pdist2(single(plores'),single(features(:,t)'));
            [~, idx] = sort(D);
            
            
            % Use K atom neighbors and obtain the LLE coefficients
            z = plores(:,idx(1:NN))-repmat(features(:,t),1,NN); % shift ith pt to origin
            C = z'*z;                                        % local covariance
            if trace(C)==0
                C = C + eye(NN,NN)*tol;                   % regularlization
            else
                C = C + eye(NN,NN)*tol*trace(C);
            end
            coeffs = C\ones(NN,1);                        % solve C*u=1
            coeffs = coeffs/sum(coeffs);                  % enforce sum(u)=1

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
