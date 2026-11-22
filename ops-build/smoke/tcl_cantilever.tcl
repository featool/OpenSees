model BasicBuilder -ndm 2 -ndf 3
node 1 0.0 0.0
node 2 1.0 0.0
fix 1 1 1 1
geomTransf Linear 1
element elasticBeamColumn 1 1 2 1.0 29000.0 100.0 1
timeSeries Constant 1
pattern Plain 1 1 {
  load 2 0.0 1.0 0.0
}
system UmfPack
numberer RCM
constraints Plain
integrator LoadControl 1.0
algorithm Linear
analysis Static
analyze 1
puts "TCL disp_y = [nodeDisp 2 2]"
puts "TCL rot = [nodeDisp 2 3]"
