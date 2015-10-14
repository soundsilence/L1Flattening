function [M] = windowvar(image, window_size, param)
% [M] = windowvariation(image, window_size)
% Usage: generate a matrix used to get the total varation for each pixel 
%	in a window centered at it.
% Input:
%	- image: original image
%	- window_size: half size of the window
%	- param
%	  	.mu 		[10] lightness weight in Lab color space
%	  	.ga 		[120] color-opponent weight in Lab color space
%	  	.sigma 		[0.5] lightness weight
% Ouput:
% 	- M: generated matrix (sparse)

param = getPrmDflt(param, {'mu', 10, 'ga', 120, 'sigma', 0.5});
mu = param.mu; ga = param.ga; sigma = param.sigma;

grad = sobelgrad(image);

cform = makecform('srgb2lab');
image_lab = applycform(uint8(image),cform);
image_lab = double(image_lab);

height = size(image, 1); width = size(image,2); pixel_num = height * width;

chrom = image_lab(:,:,1) / 100.0 ;
chrom_r = image_lab(:,:,2) / 220.0;
chrom_g = image_lab(:,:,3) / 220.0;

chrom = mu * chrom; chrom = chrom(:); % 10: best 
chrom_r = ga * chrom_r; chrom_r = chrom_r(:);
chrom_g = ga * chrom_g; chrom_g = chrom_g(:);

arr = 1:pixel_num;
f = @window;
temp_1 = repmat(window_size, 1, pixel_num); temp_2 = repmat(height, 1, pixel_num);
temp_3 = repmat(width, 1, pixel_num);
all_pair = arrayfun(f, arr, temp_1, temp_2, temp_3, 'UniformOutput', 0);
all_pair = cell2mat(all_pair');
pair_num = size(all_pair,1);

pair_1 = all_pair(:,1)'; pair_2 = all_pair(:,2)';

save('test.mat', 'grad', 'pair_1', 'pair_2');
return;
grad_val = zeros(pair_num, 1);
fprintf('start grad\n');

function [val] = maxgrad(index1, index2)
im_size = size(grad);
[y1, x1] = ind2sub(im_size, index1); [y2, x2] = ind2sub(im_size, index2);
[x,y] = bresenham(x1,y1,x2,y2);
index = sub2ind(im_size, y, x);
val = max(grad(index));
end
fx = @maxgrad;
grad_val = arrayfun(fx, pair_1, pair_2);
fprintf('end grad\n');

row = [1 : pair_num 1:pair_num];
col = [pair_1 pair_2];
val = [chrom(pair_1) - chrom(pair_2) ...
	   chrom_r(pair_1) - chrom_r(pair_2) ...
	   chrom_g(pair_1) - chrom_g(pair_2)];

val = sum(val.^2, 2);
val = exp(-sigma * val);
val = [val -1.0 * val];

row_1 = row + length(row) / 2; col_1 = col + pixel_num ;
row_2 = row_1 + length(row) / 2; col_2 = col_1 + pixel_num;
final_row = [row row_1 row_2];
final_col = [col col_1 col_2];
final_val = [val val val];
M = sparse(final_row, final_col, final_val);

end

function [win] = window(index, window_size, height, width)
row_index = mod(index, height);
col_index = floor(index / height) + 1;
p = row_index : min([height, row_index + window_size]);
q = col_index : min([width, col_index + window_size]);
[x,y] = meshgrid(p,q);
x = x(:); y = y(:);
id = (y-1) * height + x;
id = id(2:end); 
win = [index * ones(length(id),1) id];
end



function [g] = sobelgrad(image)
h = fspecial('sobel');
g1 = imfilter(image,h); g2 = imfilter(image,h');
g1 = double(g1); g2 = double(g2);
g1 = mean(g1, 3); g2 = mean(g2,3);
g = sqrt(g1.^2 + g2.^2);
end


function [x, y]=bresenham(x1,y1,x2,y2)
x1=round(x1); x2=round(x2);
y1=round(y1); y2=round(y2);
dx=abs(x2-x1);
dy=abs(y2-y1);
steep=abs(dy)>abs(dx);
if steep 
    t=dx;dx=dy;dy=t; 
end

%The main algorithm goes here.
if dy==0 
    q=zeros(dx+1,1);
else
    q=[0;diff(mod([floor(dx/2):-dy:-dy*dx+floor(dx/2)]',dx))>=0];
end

if steep
    if y1<=y2 
        y=[y1:y2]'; 
    else
        y=[y1:-1:y2]'; 
    end
    
    if x1<=x2 
        x=x1+cumsum(q);
    else
        x=x1-cumsum(q); 
    end
else
    if x1<=x2 
        x=[x1:x2]'; 
    else
        x=[x1:-1:x2]'; 
    end
    if y1<=y2 
        y=y1+cumsum(q);
    else
        y=y1-cumsum(q); 
    end
end

end