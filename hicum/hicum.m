function [yy,p,n,hh,t0,f] = hicum(t,x,w,varargin)
%HICUM	Earth tide phase histogram stacking method.
%	Y = HICUM(T,X,W,DP) compute the histogram of phases from data X and time 
%	vector T, for tide wave W, optional phase increment DP (default is 5°).
%	It returns a vector Y of stacked amplitudes for each phase increment DP.
%
%	W can be the tidal wave name (see DOODSON function for a list) as a
%	string, or a list of waves as cell of strings, 'all' to compute on all
%	known tidal waves, or the numerical value of a period (in days).
%
%	HICUM(T,[],W,...) or HICUM(...,'count') will use only the time vector T
%	and compute the histogram on the occurrences of T, in events/day.
%
%	HICUM(...,'solstice') or HICUM(...,'equinox') will split the data into
%	two subsets of ± 3 months around soltices or equinox, respectively,
%	returning two results.
%
%	[Y,P,N,H,T0] = HICUM(...) returns also phase vector P, vector of counts
%	N, first harmonic fitting amplitude, phase and std H = [AMP,PHA,STD], 
%	and origin time T0.
%
%	HICUM needs functions DOODSON and HARMFIT (and optionally DAYS2H).
%
%	References:
%	van Ruymbeke M., F. Beauducel, and A. Somerhausen (2001). The
%		Environmental Data Acquisition System (EDAS) developped at the
%		Royal Observatory of Belgium. J. Geod. Soc. Japan., 47(1), 40-46.
%	Beauducel F., M. van Ruymbeke, C. Bizouard, J. Lebrun, S. Toussaint
%		(2024). Application of the stacking algorithm HiCum method to analyse 
%		volcanic processes. 20th International Symposium on Geodynamics and
%		Earth Tides, 25-30 Aug 2024, Strasbourg, France.
%
%
%	Author: François Beauducel, Michel van Ruymbeke
%	Created: 2000-05-08
%	Updated: 2025-02-03

count = false;

% if X and T sizes are not consistent, switches to count mode.
if numel(x) ~= numel(t) || any(strcmpi(varargin,'count'))
	count = true;
	x = ones(size(t));
end

if ~iscell(w)
	if strcmpi(w,'all')
		W = doodson;
		w = W.symbol;
	else
		w = {w};
	end
end

fplot = any(strcmpi(varargin,'plot')) + 2*any(strcmpi(varargin,'plot1'));
displ = any(strcmpi(varargin,'print'));
solstice = any(strcmpi(varargin,'solstice'));
equinox = any(strcmpi(varargin,'equinox'));
dp = 5;
if nargin > 3
	if isnumeric(varargin{1})
		dp = varargin{1};
	end
end

% number of phase bins
s = 360/dp;
p = (0:(s-1))*dp;

% dimension of result
m = 1;
if solstice || equinox
	m = 2;
	SA = doodson('sa');
	tw = mod(t-datenum(2000,1,1),SA.period);
end

for iw = 1:length(w)
	if ischar(w{iw})
		X = doodson(w{iw});
		dd = X.doodson;
		p0 = X.period;
		t0 = phase_doodson(t(1),dd)/p0;
		wave = true;
	else
		p0 = w{iw};
		t0 = 0;
		wave = false;
	end
	tratio = diff(minmax(t)); % approximate number of cycles in data
		
	if wave
		f = phase_doodson(t,dd);
	else
		f = mod(t,w{iw})/w{iw};
	end
	
	% subset of data
	if m == 1
		[y,n] = hcum(s,f,x,count,tratio);
		subp = {''};
	else
		if solstice
			k = (tw > datenum(0,3,20) & tw < datenum(0,9,21));
			[y(:,1),n(:,1)] = hcum(s,f(k),x(k),count,tratio);
			[y(:,2),n(:,2)] = hcum(s,f(~k),x(~k),count,tratio);
			subp = {' (Jun solstice)',' (Dec solstice)'};
		end
		if equinox
			k = (tw > datenum(0,6,21) & tw < datenum(0,12,22));
			[y(:,1),n(:,1)] = hcum(s,f(k),x(k),count,tratio);
			[y(:,2),n(:,2)] = hcum(s,f(~k),x(~k),count,tratio);
			subp = {' (Mar equinox)',' (Sep equinox)'};
		end
	end
	
	clear h hf
	for i = 1:m
		[h(i,:),hf(:,i)] = harmfit((p(n(:,i)>0)+dp/2)*pi/180,y(n(:,i)>0,i),1,'nocrop');
	end
	
	if nargout == 0 || displ
		for i = 1:m
			fprintf('%s%s: Amp = %g ± %g, Pha = %+1.0f°\n',w{iw},subp{i},h(i,2),roundsd(h(i,4),2),h(i,3)*180/pi);
		end
	end
	if fplot
		figure
		if fplot < 2
			subplot(5,1,1:4)
		end
		plot(p,[y,hf],'LineWidth',4)
		set(gca,'XLim',[0,360])
		if count
			ylabel('Data counts per day')
		else
			ylabel('Data unit')
		end
		if solstice || equinox
			legend(sprintf('HiCum%s',subp{1}),sprintf('HiCum%s',subp{2}), ...
				sprintf('Amp = %g ± %g, \\Delta\\phi = %+1.0f°%s',h(1,2),roundsd(h(1,4),2),h(1,3)*180/pi,subp{1}), ...
				sprintf('Amp = %g ± %g, \\Delta\\phi = %+1.0f°%s',h(2,2),roundsd(h(2,4),2),h(2,3)*180/pi,subp{2}))
		else
			legend('HiCum',sprintf('Amp = %g ± %g, \\Delta\\phi = %+1.0f°',h(2),roundsd(h(4),2),h(3)*180/pi))
		end
		if exist('days2h','file')
			pp = days2h(p0);
		else
			pp = sprintf('%g day%s',p0,repmat('s',p0>1));
		end
		if wave
			tt = sprintf('Wave %s (%s)',upper(w{iw}),pp);
		else
			tt = sprintf('Period = %s',pp);
		end
		title(tt)
		if fplot < 2
			set(gca,'XTickLabel',[])
			subplot(5,1,5)
			plot(p,n,'-','LineWidth',4)
			ylabel('# Count')
			set(gca,'XLim',[0,360])
		end
		xlabel('Phase (degree)')
	end

	if nargout > 0
		if isscalar(w)
			yy = y;
			hh = h(2:4);
		else
			yy(iw).w = w{iw};
			yy(iw).y = y;
			yy(iw).h = h;
		end
	end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function a = phase_doodson(t,dd)
%Computes phase of time t for doodson wave dd
%Translated and modified from "HICUM3.C" by A. Somerhausen/ROB

% converts time T (Matlab DATENUM) into century from January 1, 1900
tj = (t - datenum(1900,1,1))/36525;

LL = 4.3581;
SW = polyval(fliplr([277.022362,481267.883142,0.0011333,0.000001889]),tj);	
HW = polyval(fliplr([280.189501,36000.768925,0.0003027]),tj);
PW = polyval(fliplr([334.385258,4069.034034,0.0103249,0.0000125]),tj);
NW = polyval(fliplr([100.843202,1934.142008,0.002078,0.000002]),tj);
PSW = polyval(fliplr([281.220868,1.719175,0.0004527,0.000033]),tj);

TW = mod(t*24,24)*15. + HW - SW + LL;

a = dd(1)*TW + dd(2)*SW + dd(3)*HW + dd(4)*PW + dd(5)*NW + dd(6)*PSW ...
	+ 36000 ...
	+ 90 * (all(dd == [1,-1,0,0,0,0]) || all(dd == [1,1,-2,0,0,0])) ... % O1 or P1
	- 90 * all(dd == [1,1,0,0,0,0]) ... % K1
	+ 180 * (dd(1) == 2); % Semi-diurnal

a = mod(a/360,1);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [y,n] = hcum(s,t,x,count,r)

y = zeros(s,1);
n = zeros(s,1);
for i = 1:s
	k = (t >= (i-1)/s & t < i/s & ~isnan(x));
	n(i) = sum(k);
	if count
		y(i) = n(i);
	else
		y(i) = mean(x(k));
	end
end

% for event counting, normalizes the result per day
if count
	y = y*s/r;
end

