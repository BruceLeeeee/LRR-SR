%==========================================================================
% usage: learn a linear projection of cheap features to imitate the
% manifold over expensive features 
%
% inputs
% train_fet_ch    -cheap features [MXN]
% expe_fet_tr     -expensive feature [KXN] 
% embedding_method     -learning methods 
% 
% outputs
% eigenvector      -linear projection
%
% written by Dengxin Dai
% Oct. 26 2014, CVL, ETHZ
%==========================================================================


function [eigvector,E] = MetricImitation(train_fet_ch, expe_fet_tr, D_ex_tr, NN, embedding_method)

    train_num = size(train_fet_ch, 1);

    switch embedding_method

            
        case 'NPE'
            options.k =  NN * 2; 
            options.ReducedDim = size(train_fet_ch,2);
            [sorted,index] = sort(D_ex_tr,2);
            neighborhood = index(:,2:(1+options.k));  
            tol=1e-6;
            W = zeros(options.k,train_num);
            for ii=1:train_num
                z = expe_fet_tr(neighborhood(ii,:),:)-repmat(expe_fet_tr(ii,:),options.k,1); % shift ith pt to origin
                C = z*z';                                        % local covariance
                C = C + eye(size(C))*tol*trace(C);                   % regularlization
                W(:,ii) = C\ones(options.k,1);                           % solve Cw=1
                W(:,ii) = W(:,ii)/sum(W(:,ii));                  % enforce sum(w)=1
            end

%             W = ones(options.k, train_num); W = normalize(W, 1);
            train_fet_ch = train_fet_ch + rand(size(train_fet_ch)) .* mean(train_fet_ch(:)) .*0.04;  % to avoid complex values from the decomposition
            [eigvector, eigvalue] = NPE(options, double(train_fet_ch), neighborhood, W);

            if(~isreal(eigvector)) error('decomposition generates complex values'); end 
            
            
    %%     Laplacian Eigenmaps
    case 'Eigenmaps'
            options.k =  NN * 2;
            options.ReducedDim = size(train_fet_ch,2);

            neighborhood = zeros(train_num,options.k);
            dis_nn = zeros(train_num,options.k);
            for ii=1:train_num
                D = pdist2(expe_fet_tr,expe_fet_tr(ii,:));
                [sorted, idx] = sort(D);
                neighborhood(ii,:) = idx(2:(1+options.k));
                dis_nn(ii,:) = sorted(2:(1+options.k));
            end
            
%           W = ones(options.k, train_num); 
            W = exp(-dis_nn./(mean(dis_nn(:))));
            W = W';
            
            W = normalize(W, 1); 
            train_fet_ch = train_fet_ch + rand(size(train_fet_ch)) .* mean(train_fet_ch(:)) .*0.04;
            [eigvector, eigvalue] = NPE(options, double(train_fet_ch), neighborhood, W);

            if(~isreal(eigvector)) error('decomposition generates complex values'); end  
    end


end