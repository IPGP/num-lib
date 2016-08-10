# Round with fixed significant digits

## roundsd.m

This little function rounds a number (or the elements of a vector or matrix) towards the nearest number with N significant digits. This is a useful complement to Matlab's ROUND, ROUND10 and ROUNDN (Mapping toolbox), especially when dealing with data with a large variety of order of magnitudes.

## Examples
```matlab
roundsd(0.012345,3) returns 0.0123
roundsd(12345,2) returns 12000
roundsd(12.345,4,'ceil') returns 12.35
```

## Author
**François Beauducel**, [IPGP](www.ipgp.fr), [beaudu](https://github.com/beaudu), beauducel@ipgp.fr 

## Documentation
Type 'doc roundsd' for help and syntax.

## Important note
This file was selected as MATLAB Central [Pick of the Week](http://blogs.mathworks.com/pick/2014/11/28/rounding-digits/), and integrated as an option of the core function ROUND in the new Matlab release 2014b.

