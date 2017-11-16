function A = runningPrctile(A, winSize, base_prctile)
% runningPrctile(A, winSize, base_prctile)

assert(isvector(A), 'A must be a vector')
assert(winSize>=1 && winSize<=numel(A) && round(winSize)==winSize, ...
    'winSize must be an integer between 1 and numel(A)');
assert(base_prctile>=0 && base_prctile <=100, 'base_prctile must be between 0 and 100')

nth = ceil((winSize/100)*base_prctile);
A = runningPrctileMex(A, winSize, nth);

% Fix edges (this is quick and dirty, implement it in mex file at some
% point!):
A(1:winSize) = A(winSize+1);
A(end-winSize+1:end) = A(end-winSize);