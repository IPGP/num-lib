function varargout = harmfit(x,y,varargin)
%HARMFIT Sinusoidal harmonic curve fitting.
%	H = HARMFIT(X,Y,N) computes the N'th harmonic amplitude and phase of the
%	data vector Y relative to phase vector X (in radian), and returns result
%	in a 4-element vector H = [N,AMP,PHA,STD], so that AMP*COS(N*X + PHA) 
%	fits Y, STD is the standard deviation of AMP residual.
%
%	N = 1 (default) stands for the fundamental, N = 2 is second harmonic,
%	etc... N can be a scalar or a vector of positive integers. For example,
%	use N = 1:3 to compute the first three harmonics.
%
%	[H,YY] = HARMFIT(...) returns also an evaluation of harmonic curve fit
%	in vector YY (as the sum of harmonics defined in N, adding a constant as
%	the mean of Y).
%
%	HARMFIT without output argument or with 'plot' input argument option 
%	will display and plot a figure of results.
%
%	Note: This is simply the core calculation of discrete Fourier transform.
%	For calculation, HARMFIT uses only defined values of X and Y (not NaN) 
%	and truncates X (and Y) at the largest 2*PI integer multiple. This implies
%   that X must contain at least one sample greater of equal to 2*PI.
%
%	Example:
%	   t = linspace(0,2*pi);
%	   x = 2*cos(t + pi/2) - cos(3*t) + rand(size(t));
%	   harmfit(t,x,1:4,'plot')
%
%	displays estimation of amplitudes/phases for the first four harmonics and
%	plots the result. Note that negative amplitudes are fitted with positive 
%	value and a PI phase difference. 
%
%	Author: François Beauducel <beauducel@ipgp.fr>
%		Institut de Physique du Globe de Paris
%	Created: 2014-05-22
%	Updated: 2025-05-22

%	Copyright (c) 2014-2024, François Beauducel, covered by BSD License.
%	All rights reserved.
%
%	Redistribution and use in source and binary forms, with or without 
%	modification, are permitted provided that the following conditions are 
%	met:
%
%	   * Redistributions of source code must retain the above copyright 
%	     notice, this list of conditions and the following disclaimer.
%	   * Redistributions in binary form must reproduce the above copyright 
%	     notice, this list of conditions and the following disclaimer in 
%	     the documentation and/or other materials provided with the distribution
%	                           
%	THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
%	AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
%	IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
%	ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE 
%	LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
%	CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
%	SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
%	INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
%	CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
%	ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
%	POSSIBILITY OF SUCH DAMAGE.

n = 1;
fplot = false;
if nargout == 0 || any(strcmpi(varargin,'plot'))
	fplot = true;
end
fcrop = ~any(strcmpi(varargin,'nocrop'));
if nargin > 2 && isnumeric(varargin{1})
	n = varargin{1};
end

if ~isnumeric(x) || ~isnumeric(y) || numel(x) ~= numel(y)
	error('X and Y must be vector of the same size.')
else
	x = x(:);
	y = y(:);
end

if ~isnumeric(n) || any(fix(n) ~= n)
	error('N argument must be positive integers.')
end

% selects 
k = all(~isnan([x,y]),2) & (~fcrop | x - min(x) < 2*pi*floor((max(x)-min(x))/(2*pi)));
n = n(:)';
nn = length(n);

% computes the complex mean
c = mean(repmat(y(k),1,nn).*exp(-1j*repmat(x(k),1,nn).*repmat(n,sum(k),1)));
h = [n;2*abs(c);angle(c)]';

m = length(x);
amp = repmat(h(:,2)',m,1);
pha = repmat(h(:,3)',m,1);
yy = sum(amp.*cos(repmat(x,1,nn).*repmat(n,m,1) + pha),2) + mean(y(k));

% std of residual
h = [h,std(repmat(y,1,nn)-yy)'];

if nargout > 0
    varargout{1} = h;
else
    fprintf('Harmonic #%d: amp %g ± %g, pha %g\n',h(:,[1,2,4,3])');
end

if nargout > 1
	varargout{2} = yy;
end

if fplot
    figure
    plot(x,[y,yy],'LineWidth',2);
    if exist('phasetick','file')
        phasetick('x')
    end
    title('harmfit.m')
    xlabel('Phase (rad)')
end
