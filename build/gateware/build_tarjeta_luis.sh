# Autogenerated by LiteX / git: 34ec22f8
set -e
yosys -l tarjeta_luis.rpt tarjeta_luis.ys
nextpnr-ecp5 --json tarjeta_luis.json --lpf tarjeta_luis.lpf --textcfg tarjeta_luis.config  --25k --package CABGA256 --speed 6 --timing-allow-fail --seed 1 
ecppack  --bootaddr 0   --compress  tarjeta_luis.config --svf tarjeta_luis.svf --bit tarjeta_luis.bit 
