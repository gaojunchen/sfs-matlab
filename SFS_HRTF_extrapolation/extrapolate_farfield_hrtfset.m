function irs_pw = extrapolate_farfield_hrtfset(irs,conf)
%EXTRAPOLATE_FARFIELD_HRTFSET far-field extrapolation of a given HRTF dataset
%
%   Usage: irs_pw = extrapolate_farfield_hrtfset(irs,[conf])
%
%   Input parameters:
%       irs     - IR data set for the virtual secondary sources
%       conf    - optional configuration struct (see SFS_config)
%
%   Output parameters:
%       irs_pw  - IR data set extra polated to conation plane wave IRs
%
%   EXTRAPOLATE_FARFIELD_HRTFSET(IRS) generates a far-field extrapolated set of
%   impulse responses, using the given irs set. Far-field means that the
%   resulting impulse responses are plane waves. The extrapolation is done via
%   WFS.
%
%   References:
%       S. Spors and J. Ahrens. Generation of far-field head-related transfer
%       functions using sound field synthesis.
%       In German Annual Conference on Acoustics (DAGA), 2011.
%
%   see also: ir_point_source, get_ir, driving_function_imp_wfs_25d

%*****************************************************************************
% Copyright (c) 2010-2013 Quality & Usability Lab, together with             *
%                         Assessment of IP-based Applications                *
%                         Deutsche Telekom Laboratories, TU Berlin           *
%                         Ernst-Reuter-Platz 7, 10587 Berlin, Germany        *
%                                                                            *
% Copyright (c) 2013      Institut fuer Nachrichtentechnik                   *
%                         Universitaet Rostock                               *
%                         Richard-Wagner-Strasse 31, 18119 Rostock           *
%                                                                            *
% This file is part of the Sound Field Synthesis-Toolbox (SFS).              *
%                                                                            *
% The SFS is free software:  you can redistribute it and/or modify it  under *
% the terms of the  GNU  General  Public  License  as published by the  Free *
% Software Foundation, either version 3 of the License,  or (at your option) *
% any later version.                                                         *
%                                                                            *
% The SFS is distributed in the hope that it will be useful, but WITHOUT ANY *
% WARRANTY;  without even the implied warranty of MERCHANTABILITY or FITNESS *
% FOR A PARTICULAR PURPOSE.                                                  *
% See the GNU General Public License for more details.                       *
%                                                                            *
% You should  have received a copy  of the GNU General Public License  along *
% with this program.  If not, see <http://www.gnu.org/licenses/>.            *
%                                                                            *
% The SFS is a toolbox for Matlab/Octave to  simulate and  investigate sound *
% field  synthesis  methods  like  wave  field  synthesis  or  higher  order *
% ambisonics.                                                                *
%                                                                            *
% http://dev.qu.tu-berlin.de/projects/sfs-toolbox       sfstoolbox@gmail.com *
%*****************************************************************************


%% ===== Checking of input  parameters ==================================
nargmin = 1;
nargmax = 2;
narginchk(nargmin,nargmax);
check_irs(irs);
if nargin<nargmax
    conf = SFS_config;
else
    isargstruct(conf);
end


%% ===== Configuration ===================================================
fs = conf.fs;                   % sampling frequency
dimension = conf.dimension;


%% ===== Variables ======================================================
R = irs.distance;
L = 2*R;
conf.secondary_sources.number = length(irs.apparent_azimuth);
conf.secondary_sources.x0 = zeros(nls,6);
conf.secondary_sources.x0(:,1:2) = [R*cos(irs.apparent_azimuth) ; R*sin(irs.apparent_azimuth)]';
conf.secondary_sources.x0(:,4:6) = direction_vector(conf.x0(:,1:3),repmat(conf.xref,nls,1));
conf.wfs.hprefhigh = aliasing_frequency(x0,conf);
%conf.wfs.hpreflow = 1;
if strcmp('2.5D',dimension)
    % Apply a amplitude correction, due to 2.5D. This will result in a correct
    % reproduced ILD in the resulting impulse responses (see, Spors 2011)
    amplitude_correction = -1.7 * sin(irs.apparent_azimuth);
else
    amplitude_correction = zeros(size(irs.apparent_azimuth));
end



%% ===== Computation =====================================================
% get virtual secondary source positions
x0_all = secondary_source_positions(L,conf);

% Initialize new irs set
irs_pw = irs;
irs_pw.description = 'Extrapolated HRTF set containing plane waves';
irs_pw.left = zeros(size(irs_pw.left));
irs_pw.right = zeros(size(irs_pw.right));
irs_pw.distance = 'Inf';

% Generate a irs set for all given angles
for ii = 1:length(irs.apparent_azimuth)

    % direction of plane wave
    xs = -[cos(irs.apparent_azimuth(ii)) ...
        sin(irs.apparent_azimuth(ii))];

    % calculate active virtual speakers
    x0 = secondary_source_selection(x0_all,xs,'pw');

    % generate tapering window
    win = tapering_window(x0,conf);

    % sum up contributions from individual virtual speakers
    %     delay = [];
    [~,delay,weight] = driving_function_imp_wfs(x0,xs,'pw',conf);
    for l=1:size(x0,1)
        dt = delay(l)*fs + R/conf.c*fs;
        w = weight(l) * win(l);
        % get IR for the secondary source position
        [phi,theta,r] = cart2sph(x0(l,1),x0(l,2),x0(l,3));
        ir_tmp = get_ir(irs,[phi theta r],'spherical',conf);
        % truncate IR length
        ir = fix_ir_length(ir_tmp,size(ir_tmp,1),dt);
        % delay and weight HRTFs
        irs_pw.left(:,ii) = irs_pw.left(:,ii) + delayline(ir(:,1)',dt,w,conf)';
        irs_pw.right(:,ii) = irs_pw.right(:,ii) + delayline(ir(:,2)',dt,w,conf)';
    end
    irs_pw.left(:,ii) = irs_pw.left(:,ii)/10^(amplitude_correction(ii)/20);
    irs_pw.right(:,ii) = irs_pw.right(:,ii)/10^(-amplitude_correction(ii)/20);

end

%% ===== Pre-equalization ===============================================
irs_pw.left = wfs_preequalization(irs_pw.left,conf);
irs_pw.right = wfs_preequalization(irs_pw.right,conf);