function k = findcols(A, b)
%FINDCOLS Find indices of a given column within a matrix.
%   Usage: idx = findcols(A,b)
%
%   Input options:
%       A   - matrix
%       b   - colum to search for in A
%
%   output options:
%       idx - indices of found columns in matrix
%
%   FINDCOLS(A, b) returns a row vector with the indices of the columns
%   in the matrix A that are identical to the column vector b.  If no
%   columns in A are identical to b, an empty vector is returned.
%
%   The methods uses a for-loop, but it uses less memory and is in many
%   cases a lot faster than the vectorized methods
%
%      find( all( A == repmat(b, 1, size(A, 2)), 1 ) )
%      find( all( A == b(:,ones(size(A, 2), 1)), 1 ) )
%
%   See also find, findrows.

% AUTHOR: Peter John Acklam, Hagen Wierstorf


%% ===== Checking of input parameters ====================================
nargmin = 2;
nargmax = 2;
error(nargchk(nargmin,nargmax,nargin));
isargmatrix(A);
isargvector(b);


%% ===== Computation =====================================================
k = find( A(1,:) == b(1) );
for j = 2:size(A, 1)
  k = k( A(j,k) == b(j) );
  if isempty(k)
     return
  end
end