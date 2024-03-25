function phasetick(a)
%PHASETICK Phase formatted tick labels
%   The function labels the tick lines of the axis specified by tickaxis
%   using PI-based, replacing the numeric labels in radian.
%
%   Syntax:
%      PHASETICK(tickaxis) where tickaxis is 'x' or 'y'
%
%   Author: F. Beauducel <beauducel@ipgp.fr>
%   Created: 2024-03-25

at = [a,'Tick'];
axis tight
lim = get(gca,[a,'Lim'])/pi;
d = diff(lim);
m = 10^floor(log10(d));
p = ceil(d/m);
if p <= 2
	dd = .25*m;
elseif p <= 4
	dd = .5*m;
else
	dd = m;
end

x = ceil(lim(1)/dd)*dd:dd:floor(lim(2)/dd)*dd;
set(gca,at,x*pi);

s = cell(size(x));
for n = 1:length(s)
    ax = abs(x(n));
    switch rem(ax,1)
    case 0
        s{n} = [num2str(x(n)),'\pi'];
    case 1/2
        s{n} = [num2str(2*x(n)),'\pi/2'];
    case {1/4,3/4}
        s{n} = [num2str(4*x(n)),'\pi/4'];
    end
end
s = regexprep(s,'1','');
s = regexprep(s,'0\\pi','0');

set(gca,[at,'Label'],s)
axis tight
