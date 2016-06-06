breed [insects insect] ;; insects
 
insects-own [
  age 
  target
  memory-limit
  visited-patches
  search-radius
  search-method
  emigration-probability
  emigration-threshold
  last-plant 
  moved
  landing-chance
  repellent-plant
  ]

;; BLUE PATCHES REPRESENT THE TRAP CROP AND GREEN PATCHES THE REGULAR CROP
patches-own [resources 
  chd ;; cumulative-herbivore-days the cumulative number of previous visits by herbivores
  damage-threshold ;; the number of visits a plant can withstand before becoming repellent 
  this-patch 
  flight-tendency ;; the probability of an insect leaving the plant 
  insect-load
  ]

globals [
  ageMortInsect ;; the number of insects that have died due to age related mortality
  trap-trap
  crop-crop
  trap-crop
  crop-trap
  ]
;////////DESNITY OF HOST PATCHES LAYOUT OPTIONS///////////////////////

to border ;;TRAP CROP IN A BORDER 7 PATCHES WIDE    
    let minCor 0 + 6
    let maxCor 99 - 6 
  ask patches[
   ifelse (pxcor > minCor and pxcor < maxCor) and (pycor > minCor and pycor < maxCor)
    [set pcolor green set flight-tendency flight-tendency-main-crop]
    [set pcolor blue set flight-tendency flight-tendency-trap-crop]
  ]
end

to plantsIntercrop ;;TRAP CROP IN ROWS 5 PATCHES WIDE AND 100 LONG, SPACED 15 PATCHES APART 
  ask patches[
    set pcolor green set flight-tendency flight-tendency-main-crop
    if pxcor >= 0 and pxcor <= 4 [set pcolor blue set flight-tendency flight-tendency-trap-crop]
    if pxcor >= 20 and pxcor <= 24 [set pcolor blue set flight-tendency flight-tendency-trap-crop]
    if pxcor >= 40 and pxcor <= 44 [set pcolor blue set flight-tendency flight-tendency-trap-crop]
    if pxcor >= 60 and pxcor <= 64 [set pcolor blue set flight-tendency flight-tendency-trap-crop]
    if pxcor >= 80 and pxcor <= 84 [set pcolor blue set flight-tendency flight-tendency-trap-crop]
    ] 
end

to plantsPatches ;; CREATES PATCHES OF TRAP CROP 10 X 10 RANDOMLY DISTRIBUTED AND NOT OVERLAPPING
  loop [
     let chosen-patch one-of patches with [(pxcor <= 90) and (pycor >= 9)] 
     let cornerx [pxcor] of chosen-patch
     let cornery [pycor] of chosen-patch
     let cluster patches with [(pxcor >= cornerx and pxcor <= cornerx + 9) and (pycor <= cornery and pycor >= cornery - 9) 
     ]
    if all? (patch-set [neighbors] of cluster) [pcolor = green] [
       ask cluster [ set pcolor blue set flight-tendency flight-tendency-trap-crop]
       stop
    ]
  ]
end

to halfPatch ;; CREATES PATCHES OF TRAP CROP 5 X 5 RANDOMLY DISTRIBUTED AND NOT OVERLAPPING (CAN BE USED IN CONJUNCTION WITH plantsPatches)
  loop [
     let chosen-patch one-of patches with [(pxcor <= 90 and pxcor >= 9) and (pycor <= 90 and pycor >= 9)] 
     let cornerx [pxcor] of chosen-patch
     let cornery [pycor] of chosen-patch
     let cluster patches with [(pxcor >= cornerx and pxcor <= cornerx + 4) and (pycor <= cornery and pycor >= cornery - 9)
     ]
    if all? (patch-set [neighbors] of cluster) [pcolor = green] [
       ask cluster [ set pcolor blue set flight-tendency flight-tendency-trap-crop]
       stop
    ]
  ]
end    

;///// CREATE INSECTS///////////////////////////////////////////

to makeInsects ;; create insects
  set-default-shape insects "circle"
  create-insects number-of-insects
  [ 
    set size 1
    set color red
    if colonisation = "random" ;; the direction of colonisation, can be from a specific coordinate or insects can be randomly distributed through the patches
     [setxy random-xcor random-ycor]
    if colonisation = "specific location"
     [set xcor insect-x-cor set ycor insect-y-cor]
    if colonisation = "random west" ;; randomly distributed along the west edge 
     [set xcor random-exponential 0.5 set ycor random-ycor] 
    if colonisation = "random east" 
     [ set xcor (99 - random-exponential 0.5) set ycor random-ycor] 
    if colonisation = "random south"
     [ set xcor random-xcor set ycor random-exponential 0.5]
    if colonisation = "random north"
     [ set xcor random-xcor set ycor (99 - random-exponential 0.5)]
     
    set emigration-probability emigration-prob
    set search-method detection-method
    set emigration-threshold 0
    set visited-patches[]
    set landing-chance landing-prob 
  ]
end 

;///// SETUP AND GO //////////////////////////////////////////////

to setup ;; create the plants and insects
  clear-all 
  reset-ticks

  if PlantLayout = "intercrop" [plantsIntercrop]
  if PlantLayout = "patches" [ask patches [set pcolor green set flight-tendency flight-tendency-main-crop] repeat num-patches [plantsPatches] repeat num-half-patches [halfPatch]]
  if PlantLayout = "border"[border]
  ask patches [set chd 0] ;; set cumulative herbivore days to 0
  ask patches with [pcolor = blue][set damage-threshold damage-threshold-trap-crop]
  ask patches with [pcolor = green][set damage-threshold damage-threshold-main-crop]

  makeInsects ;; create the insects
  ask insects [set visited-patches lput patch-here visited-patches];; input the starting plant as visited
  ask patches [set insect-load count insects-here]
  ask insects [setLastPlant]
  
 ;  if flight-tendency-main-crop = 1 and flight-tendency-trap-crop = 1 [output-print "Trap and main crop cannot both be repellent" stop]
end

to go
 ask insects[ 
  setLastPlant 
  ageDependentMortalityInsect
  move ;; move to chosen plant
  if flight-tendency = 1 [
    ifelse repellent = true [repellent-movement]
  [deterrent]
  ];; test if the plant is repellent
  if flight-tendency != 1 [set emigration-probability emigration-prob] 
 ]
 ask insects [if moved = true[addMovement]]
 ;; update plants and insects
 ask patches [update-patches] ;; every time step the trap and main crop plants accumulate herbivore visits measured as cumulative herbivore days    
 ask insects [set age age + 1]
 tick
end

;///////////////////////PATCH FUNCTIONS///////////////////////////////////////

to update-patches
  set chd chd + count turtles-here
  if chd > damage-threshold [set flight-tendency 1];; once chd exceeds the damage threshold the plant becomes repellent (flight tendency of 1)
  set insect-load count insects-here
end

;///////////////////MOVEMENT FUNCTIONS///////////////////////////////////////
to setLastPlant
  ifelse pcolor = blue [set last-plant blue]
  [set last-plant green]
end 

to addMovement
  let this-plant yellow
  ifelse pcolor = blue [set this-plant blue]
  [set this-plant  green]
  if (last-plant = blue and this-plant = blue) [set trap-trap trap-trap + 1 ]
  if (last-plant = blue and this-plant = green) [set trap-crop trap-crop + 1 ]
  if (last-plant = green and this-plant = green) [set crop-crop crop-crop + 1 ]
  if (last-plant = green and this-plant = blue) [set crop-trap crop-trap + 1 ]
  set last-plant this-plant
end 

to move  
 let flight-prob flight-tendency ;; get the probability of flying from the quality of the plant
 generate-flight-length
 set heading random 360
 ifelse random-float 1 < flight-prob[ ;; stay or fly   
   set moved true 
   if search-method = "olfactory" [olfactory-movement]
   if search-method = "visual" [visual-movement]
   if search-method = "contact" [contact-movement]
 ] 
 
 [ifelse random-float 1 < 0.5 [ ;; staying or intiating a local search (hopping)
   set moved false 
   set heading random 360 fd 1 
 ]
 [set moved false]
 ]
end  

to deterrent
  set emigration-probability induced-emigration-prob
  if moved = true[add-plant-to-memory]
end

to repellent-movement
  set repellent-plant true
 while [repellent-plant = true][
   set emigration-probability induced-emigration-prob
   set emigration-threshold emigration-threshold + 1
   if emigration-threshold >= 5 [die]
      if search-method = "olfactory" [olfactory-movement]
      if search-method = "visual" [visual-movement]
      if search-method = "contact" [contact-movement]
 ]
end  

to emigrate 
  if random-float 1 < emigration-probability [die] ;; chance of emigration when in air column (default 0.05)
  if (xcor > 99 or ycor > 99 or xcor < 1 or ycor < 1) and random-float 1 < emigration-probability [die] ;; emigration at the edge of the plot (default 0.05)
end 

to add-plant-to-memory 
 if not member? patch-here visited-patches[set visited-patches lput patch-here visited-patches] ;; prevents the plant being added to the memory twice if the insect does not move
  if length visited-patches >= 5[set visited-patches remove-item 0 visited-patches] ;; sliding window memory, insects can only remember the previous 5 plants they have visited
end

to generate-flight-length
  let distance-list n-values max-flight-length [? + 1] ;; the distance of the flight is a random number between 1 and the maximum flight length (default 10)
  set search-radius one-of distance-list  
end  

to olfactory-movement
  emigrate
  let move-distance search-radius
   loop [
    fd 1 
    set move-distance move-distance - 1 
    if flight-tendency = min[flight-tendency] of patches and not member? self visited-patches[ ;;sets the target plants as those with the lowest flight tendency and those that haven't previously been visited (memory window is 5 plants)
      if random-float 1 < landing-chance [ 
        if flight-tendency != 1[set repellent-plant false]
        stop]
      ] ;;if it comes across a target plant there is a chance it will land (0.7 default)
    if move-distance <= 0 [
      if flight-tendency != 1[set repellent-plant false]
      stop]
    ] ;; if it reaches the end of the flight path, without having found/landed on a preferred plant it will land regardless
end 

to visual-movement
  emigrate
  let move-distance search-radius 
  set this-patch no-patches
  set this-patch (patch-set patch-here this-patch)
  let remaining-patches patches in-radius move-distance with [not member? self [this-patch] of myself and not member? self [visited-patches] of myself];; remove the plant the insect is on from the search radius and remove plants that have been previosly visited (memory of 5 plants)
  let target-patches remaining-patches with [flight-tendency = min [flight-tendency] of patches] ;; sets the target plants as those with the lowest flight tendency (the least likely to promote a flight)
  ifelse any? target-patches [
    set target min-one-of target-patches [distance myself]
    face target 
    let distance-to distance target 
    let distance-travelled 0  
    loop [ ;; if there are no target patches the insect moves to the plant at the edge of the searcg radius
      fd 1
      set distance-travelled distance-travelled + 1
      if distance-travelled >= distance-to [
        if flight-tendency != 1 [set repellent-plant false]
        stop]
    ]
  ]
  [
    loop[
      fd 1 
      set move-distance move-distance - 1
      if move-distance <= 0 [
        if flight-tendency != 1 [set repellent-plant false]
        stop]
    ]
  ]
end 

to contact-movement
  emigrate
  let movement-length search-radius
  fd movement-length
  if flight-tendency != 1 [set repellent-plant false] 
end 

;/////////////////////////////MORTALITY FUNCTIONS////////////////////////////////////////////////////////

to ageDependentMortalityInsect ;; age dependent ageDependentMortality
  let survival 1 - ( mortality-rate * age )
  if not (random-float 1.0 < survival)[set ageMortInsect ageMortInsect + 1 die]  
end 

;////////////////////// DISPLAY AND REPORT CONTROLS ///////////////////////////////////////////////////

to-report chd-trap-crop
  let total-chd sum [chd] of patches with [pcolor = blue]
  report total-chd 
end

to-report chd-main-crop
  let total-chd sum [chd] of patches with [pcolor = green]
  report total-chd 
end

to-report on-trap
let total-insect-load sum [insect-load] of patches with [pcolor = blue]
report total-insect-load 
end 

to-report on-main
let total-insect-load sum [insect-load] of patches with [pcolor = green]
report total-insect-load
end

to-report insects-load 
  report map [[(list  insect-load)] of ?] sort patches
end 

to-report location-of-insects
  report map [[(list xcor ycor)]of ?] sort insects
end 

to-report location-of-hosts
   report map [[(list pxcor pycor)] of ?] sort patches with [pcolor = blue]
end 

to-report location-of-nonhosts
   report map [[(list pxcor pycor)] of ?] sort patches with [pcolor = green]
end
  

    
@#$#@#$#@
GRAPHICS-WINDOW
461
78
971
609
-1
-1
5.0
1
10
1
1
1
0
0
0
1
0
99
0
99
0
0
1
ticks
30.0

BUTTON
40
10
103
43
setup
setup\n
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
39
85
102
118
Go
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

CHOOSER
32
163
199
208
PlantLayout
PlantLayout
"border" "intercrop" "patches"
1

BUTTON
39
47
102
81
One tick
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

CHOOSER
28
493
166
538
colonisation
colonisation
"random" "specific location" "random north" "random south" "random east" "random west"
0

INPUTBOX
29
544
104
604
insect-x-cor
0
1
0
Number

INPUTBOX
111
543
187
603
insect-y-cor
99
1
0
Number

SLIDER
12
403
184
436
number-of-insects
number-of-insects
1
500
500
1
1
NIL
HORIZONTAL

TEXTBOX
37
137
187
157
Plant options
12
0.0
1

TEXTBOX
30
475
180
493
Colonisation
12
0.0
1

SLIDER
231
400
403
433
max-flight-length
max-flight-length
0
100
1
1
1
NIL
HORIZONTAL

CHOOSER
209
275
376
320
flight-tendency-main-crop
flight-tendency-main-crop
0.5 0.05 1
0

CHOOSER
22
336
160
381
detection-method
detection-method
"olfactory" "visual" "contact"
0

SLIDER
225
166
425
199
damage-threshold-trap-crop
damage-threshold-trap-crop
0
100
100
1
1
NIL
HORIZONTAL

SLIDER
222
211
423
244
damage-threshold-main-crop
damage-threshold-main-crop
0
100
100
1
1
NIL
HORIZONTAL

SLIDER
1052
438
1241
471
induced-emigration-prob
induced-emigration-prob
0
1
0.05
0.01
1
NIL
HORIZONTAL

OUTPUT
174
48
414
102
12

INPUTBOX
1052
480
1140
540
emigration-prob
0.05
1
0
Number

SLIDER
30
212
201
245
flight-tendency-trap-crop
flight-tendency-trap-crop
0
1
0.05
0.01
1
NIL
HORIZONTAL

INPUTBOX
352
465
434
525
landing-prob
0.7
1
0
Number

INPUTBOX
357
330
435
390
mortality-rate
0.0010
1
0
Number

INPUTBOX
1050
157
1126
217
num-patches
10
1
0
Number

INPUTBOX
1049
226
1144
286
num-half-patches
0
1
0
Number

SWITCH
50
267
154
300
repellent
repellent
0
1
-1000

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

bee 2
true
0
Polygon -1184463 true false 195 150 105 150 90 165 90 225 105 270 135 300 165 300 195 270 210 225 210 165 195 150
Rectangle -16777216 true false 90 165 212 185
Polygon -16777216 true false 90 207 90 226 210 226 210 207
Polygon -16777216 true false 103 266 198 266 203 246 96 246
Polygon -6459832 true false 120 150 105 135 105 75 120 60 180 60 195 75 195 135 180 150
Polygon -6459832 true false 150 15 120 30 120 60 180 60 180 30
Circle -16777216 true false 105 30 30
Circle -16777216 true false 165 30 30
Polygon -7500403 true true 120 90 75 105 15 90 30 75 120 75
Polygon -16777216 false false 120 75 30 75 15 90 75 105 120 90
Polygon -7500403 true true 180 75 180 90 225 105 285 90 270 75
Polygon -16777216 false false 180 75 270 75 285 90 225 105 180 90
Polygon -7500403 true true 180 75 180 90 195 105 240 195 270 210 285 210 285 150 255 105
Polygon -16777216 false false 180 75 255 105 285 150 285 210 270 210 240 195 195 105 180 90
Polygon -7500403 true true 120 75 45 105 15 150 15 210 30 210 60 195 105 105 120 90
Polygon -16777216 false false 120 75 45 105 15 150 15 210 30 210 60 195 105 105 120 90
Polygon -16777216 true false 135 300 165 300 180 285 120 285

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270

@#$#@#$#@
NetLogo 5.1.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="test varying ovi pot and l survival 2" repetitions="3" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="300"/>
    <metric>count turtles</metric>
    <metric>count larvae</metric>
    <metric>count eggs</metric>
    <metric>count insects</metric>
    <metric>allResourcesHost</metric>
    <metric>allResourcesNonHost</metric>
    <enumeratedValueSet variable="nonHostNutrients">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="depletion-rate">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="oviposition-prob-nonhost">
      <value value="0.25"/>
      <value value="0.5"/>
      <value value="0.75"/>
      <value value="0.9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trade-off">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="adult-angle">
      <value value="360"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="time-to-egg-laying">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="larval-radius">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="birth-rate-host">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PlantLayout">
      <value value="&quot;Randomly distributed&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="adult-radius">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prob-movement-host">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="age-mort-adult">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="larval-memory-limit">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="eggNumber">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colonisation">
      <value value="&quot;random north&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="larval-survival-host">
      <value value="0.25"/>
      <value value="0.95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="oviposition-prob-host">
      <value value="0.25"/>
      <value value="0.5"/>
      <value value="0.75"/>
      <value value="0.9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="adult-memory-limit">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="length-of-season">
      <value value="1000000000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="assesment-time-nonhost">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prob-movement-nonhost">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="adult-survival-host">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="border-width">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dd-mort-larvae">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="larval-development-time">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="age-mort-larvae">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pupal-development-time">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="larval-angle">
      <value value="360"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="larvae-move">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="repeat-colonisation">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="non-host-tolerance">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="adult-survival-nonhost">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hostNutrients">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="egg-maturation-time">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dd-mort-adult">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="timeSpentBareGround">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="antibiosis-adult">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="egg-survival">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="growthRateNonHost">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="propHost">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="antibiosis-larvae">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-insects">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="growthRateHost">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="insect-y-cor">
      <value value="-12"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="larval-survival-nonhost">
      <value value="0.25"/>
      <value value="0.95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exhausted-egg-mort">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="birth-rate-non-host">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="detect-plant-pre-landing">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="insect-x-cor">
      <value value="12"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="bare-ground-tolerance">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="assesment-time-host">
      <value value="1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="model testing" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="100"/>
    <metric>count turtles</metric>
    <enumeratedValueSet variable="dd-mort-adult">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="bare-ground-tolerance">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prob-movement-host">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="timeSpentBareGround">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="birth-rate-host">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="non-host-tolerance">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="age-mort-larvae">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="age-mort-adult">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="propHost">
      <value value="0"/>
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="assesment-time-host">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="adult-survival-host">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="adult-angle">
      <value value="360"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="time-to-egg-laying">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="egg-survival">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="oviposition-prob-host">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="larvae-move">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="oviposition-prob-nonhost">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="depletion-rate">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="length-of-season">
      <value value="1000000000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="larval-development-time">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hostNutrients">
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-insects">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nonHostNutrients">
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="adult-survival-nonhost">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="antibiosis-adult">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="antibiosis-larvae">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exhausted-egg-mort">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PlantLayout">
      <value value="&quot;Randomly distributed&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="growthRateNonHost">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="border-width">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pupal-development-time">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colonisation">
      <value value="&quot;random north&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="insect-y-cor">
      <value value="-12"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="egg-maturation-time">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prob-movement-nonhost">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trade-off">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="detect-plant-pre-landing">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="larval-survival-nonhost">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="larval-radius">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="larval-angle">
      <value value="360"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="repeat-colonisation">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="birth-rate-non-host">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="growthRateHost">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="adult-memory-limit">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dd-mort-larvae">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="assesment-time-nonhost">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="insect-x-cor">
      <value value="12"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="adult-radius">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="eggNumber">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="larval-memory-limit">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="larval-survival-host">
      <value value="1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment 1" repetitions="40" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="50"/>
    <metric>count turtles</metric>
    <metric>chd-trap-crop</metric>
    <metric>chd-main-crop</metric>
    <metric>on-trap</metric>
    <metric>on-main</metric>
    <enumeratedValueSet variable="detection-method">
      <value value="&quot;visual&quot;"/>
      <value value="&quot;olfactory&quot;"/>
      <value value="&quot;touch&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="flight-tendency-trap-crop">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="insect-y-cor">
      <value value="11"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="insect-x-cor">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="damage-threshold-main-crop">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="damage-threshold-trap-crop">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-insects">
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="flight-tendency-main-crop">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="induced-emigration-prob">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-flight-length">
      <value value="1"/>
      <value value="5"/>
      <value value="10"/>
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colonisation">
      <value value="&quot;random&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PlantLayout">
      <value value="&quot;intercrop&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="sensitivity analysis olf 2" repetitions="40" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="50"/>
    <metric>count turtles</metric>
    <metric>chd-main-crop</metric>
    <metric>chd-trap-crop</metric>
    <enumeratedValueSet variable="emigration-prob">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="landing-prob">
      <value value="0.7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="repellent">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="insect-y-cor">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="flight-tendency-main-crop">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PlantLayout">
      <value value="&quot;intercrop&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="damage-threshold-trap-crop">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-insects">
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="detection-method">
      <value value="&quot;olfactory&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colonisation">
      <value value="&quot;random&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-flight-length">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="induced-emigration-prob">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="flight-tendency-trap-crop">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="insect-x-cor">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="damage-threshold-main-crop">
      <value value="80"/>
      <value value="90"/>
      <value value="100"/>
      <value value="110"/>
      <value value="120"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="sensitivity analysis olf 3" repetitions="40" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="50"/>
    <metric>count turtles</metric>
    <metric>chd-main-crop</metric>
    <metric>chd-trap-crop</metric>
    <enumeratedValueSet variable="emigration-prob">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="landing-prob">
      <value value="0.7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="repellent">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="insect-y-cor">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="flight-tendency-main-crop">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PlantLayout">
      <value value="&quot;intercrop&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="damage-threshold-trap-crop">
      <value value="80"/>
      <value value="90"/>
      <value value="100"/>
      <value value="110"/>
      <value value="120"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-insects">
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="detection-method">
      <value value="&quot;olfactory&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colonisation">
      <value value="&quot;random&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-flight-length">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="induced-emigration-prob">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="flight-tendency-trap-crop">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="insect-x-cor">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="damage-threshold-main-crop">
      <value value="100"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="sensitivity analysis olf 4" repetitions="40" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="50"/>
    <metric>count turtles</metric>
    <metric>chd-main-crop</metric>
    <metric>chd-trap-crop</metric>
    <enumeratedValueSet variable="emigration-prob">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="landing-prob">
      <value value="0.7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="repellent">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="insect-y-cor">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="flight-tendency-main-crop">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PlantLayout">
      <value value="&quot;intercrop&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="damage-threshold-trap-crop">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-insects">
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="detection-method">
      <value value="&quot;olfactory&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colonisation">
      <value value="&quot;random&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-flight-length">
      <value value="8"/>
      <value value="9"/>
      <value value="10"/>
      <value value="11"/>
      <value value="12"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="induced-emigration-prob">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="flight-tendency-trap-crop">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="insect-x-cor">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="damage-threshold-main-crop">
      <value value="100"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="sensitivity analysis 5" repetitions="40" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="50"/>
    <metric>count turtles</metric>
    <metric>chd-main-crop</metric>
    <metric>chd-trap-crop</metric>
    <enumeratedValueSet variable="emigration-prob">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="landing-prob">
      <value value="0.7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="repellent">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="insect-y-cor">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="flight-tendency-main-crop">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PlantLayout">
      <value value="&quot;intercrop&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="damage-threshold-trap-crop">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-insects">
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="detection-method">
      <value value="&quot;olfactory&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colonisation">
      <value value="&quot;random&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-flight-length">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="induced-emigration-prob">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="flight-tendency-trap-crop">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="insect-x-cor">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="damage-threshold-main-crop">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mortality-rate">
      <value value="8.0E-4"/>
      <value value="9.0E-4"/>
      <value value="0.0010"/>
      <value value="0.0011"/>
      <value value="0.0012"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="sensitivity analysis olf 6" repetitions="40" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="50"/>
    <metric>count turtles</metric>
    <metric>chd-main-crop</metric>
    <metric>chd-trap-crop</metric>
    <enumeratedValueSet variable="emigration-prob">
      <value value="0.04"/>
      <value value="0.045"/>
      <value value="0.05"/>
      <value value="0.055"/>
      <value value="0.06"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="landing-prob">
      <value value="0.7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="repellent">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="insect-y-cor">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="flight-tendency-main-crop">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PlantLayout">
      <value value="&quot;intercrop&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="damage-threshold-trap-crop">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-insects">
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="detection-method">
      <value value="&quot;olfactory&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colonisation">
      <value value="&quot;random&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-flight-length">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="induced-emigration-prob">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="flight-tendency-trap-crop">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="insect-x-cor">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="damage-threshold-main-crop">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mortality-rate">
      <value value="0.0010"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="sensitivity analysis olf 7" repetitions="40" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="50"/>
    <metric>count turtles</metric>
    <metric>chd-main-crop</metric>
    <metric>chd-trap-crop</metric>
    <enumeratedValueSet variable="emigration-prob">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="landing-prob">
      <value value="0.7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="repellent">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="insect-y-cor">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="flight-tendency-main-crop">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PlantLayout">
      <value value="&quot;intercrop&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="damage-threshold-trap-crop">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-insects">
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="detection-method">
      <value value="&quot;olfactory&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colonisation">
      <value value="&quot;random&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-flight-length">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="induced-emigration-prob">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="flight-tendency-trap-crop">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="insect-x-cor">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="damage-threshold-main-crop">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mortality-rate">
      <value value="0.0010"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-patches">
      <value value="20"/>
      <value value="22"/>
      <value value="25"/>
      <value value="27"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-half-patches">
      <value value="0"/>
      <value value="1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="sensitivity analysis olf 8" repetitions="40" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="50"/>
    <metric>count turtles</metric>
    <metric>chd-main-crop</metric>
    <metric>chd-trap-crop</metric>
    <enumeratedValueSet variable="emigration-prob">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="landing-prob">
      <value value="0.56"/>
      <value value="0.63"/>
      <value value="0.7"/>
      <value value="0.77"/>
      <value value="0.84"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="repellent">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="insect-y-cor">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="flight-tendency-main-crop">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PlantLayout">
      <value value="&quot;intercrop&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="damage-threshold-trap-crop">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-insects">
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="detection-method">
      <value value="&quot;olfactory&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colonisation">
      <value value="&quot;random&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-flight-length">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="induced-emigration-prob">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="flight-tendency-trap-crop">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="insect-x-cor">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="damage-threshold-main-crop">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mortality-rate">
      <value value="0.0010"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-patches">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-half-patches">
      <value value="0"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Experiment One" repetitions="40" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="50"/>
    <metric>count turtles</metric>
    <metric>chd-trap-crop</metric>
    <metric>chd-main-crop</metric>
    <enumeratedValueSet variable="detection-method">
      <value value="&quot;olfactory&quot;"/>
      <value value="&quot;contact&quot;"/>
      <value value="&quot;visual&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="flight-tendency-main-crop">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-patches">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-half-patches">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-insects">
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mortality-rate">
      <value value="0.0010"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="damage-threshold-trap-crop">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colonisation">
      <value value="&quot;random&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="emigration-prob">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="insect-x-cor">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-flight-length">
      <value value="1"/>
      <value value="3"/>
      <value value="5"/>
      <value value="10"/>
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="insect-y-cor">
      <value value="99"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="flight-tendency-trap-crop">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PlantLayout">
      <value value="&quot;intercrop&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="damage-threshold-main-crop">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="induced-emigration-prob">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="landing-prob">
      <value value="0.7"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Experiment Two Three" repetitions="40" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="50"/>
    <metric>count turtles</metric>
    <metric>chd-trap-crop</metric>
    <metric>chd-main-crop</metric>
    <metric>on-trap</metric>
    <metric>on-main</metric>
    <metric>trap-trap</metric>
    <metric>trap-crop</metric>
    <metric>crop-crop</metric>
    <metric>crop-trap</metric>
    <enumeratedValueSet variable="repellent">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="detection-method">
      <value value="&quot;olfactory&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="flight-tendency-main-crop">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-patches">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-half-patches">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-insects">
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mortality-rate">
      <value value="0.0010"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="damage-threshold-trap-crop">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colonisation">
      <value value="&quot;random&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="emigration-prob">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="insect-x-cor">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-flight-length">
      <value value="1"/>
      <value value="3"/>
      <value value="5"/>
      <value value="10"/>
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="insect-y-cor">
      <value value="99"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="flight-tendency-trap-crop">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PlantLayout">
      <value value="&quot;intercrop&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="damage-threshold-main-crop">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="induced-emigration-prob">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="landing-prob">
      <value value="0.7"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Experiment Four" repetitions="40" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="50"/>
    <metric>count turtles</metric>
    <metric>chd-trap-crop</metric>
    <metric>chd-main-crop</metric>
    <enumeratedValueSet variable="detection-method">
      <value value="&quot;olfactory&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="flight-tendency-main-crop">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-patches">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-half-patches">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-insects">
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mortality-rate">
      <value value="0.0010"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="damage-threshold-trap-crop">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colonisation">
      <value value="&quot;random&quot;"/>
      <value value="&quot;random east&quot;"/>
      <value value="&quot;random north&quot;"/>
      <value value="&quot;random west&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="emigration-prob">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="insect-x-cor">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-flight-length">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="insect-y-cor">
      <value value="99"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="flight-tendency-trap-crop">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PlantLayout">
      <value value="&quot;intercrop&quot;"/>
      <value value="&quot;border&quot;"/>
      <value value="&quot;patches&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="damage-threshold-main-crop">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="induced-emigration-prob">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="landing-prob">
      <value value="0.7"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Experiment Five" repetitions="40" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="50"/>
    <metric>count turtles</metric>
    <metric>chd-trap-crop</metric>
    <metric>chd-main-crop</metric>
    <enumeratedValueSet variable="detection-method">
      <value value="&quot;olfactory&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="flight-tendency-main-crop">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-patches">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-half-patches">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-insects">
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mortality-rate">
      <value value="0.0010"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="damage-threshold-trap-crop">
      <value value="1"/>
      <value value="3"/>
      <value value="5"/>
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colonisation">
      <value value="&quot;random&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="emigration-prob">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="insect-x-cor">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-flight-length">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="insect-y-cor">
      <value value="99"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="flight-tendency-trap-crop">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PlantLayout">
      <value value="&quot;intercrop&quot;"/>
      <value value="&quot;border&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="damage-threshold-main-crop">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="induced-emigration-prob">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="landing-prob">
      <value value="0.7"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Experiment Six-test" repetitions="40" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="50"/>
    <metric>count turtles</metric>
    <metric>chd-trap-crop</metric>
    <metric>chd-main-crop</metric>
    <enumeratedValueSet variable="detection-method">
      <value value="&quot;olfactory&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="flight-tendency-main-crop">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-patches">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-half-patches">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-insects">
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mortality-rate">
      <value value="0.0010"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="damage-threshold-trap-crop">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colonisation">
      <value value="&quot;random&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="emigration-prob">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="insect-x-cor">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-flight-length">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="insect-y-cor">
      <value value="99"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="flight-tendency-trap-crop">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PlantLayout">
      <value value="&quot;intercrop&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="damage-threshold-main-crop">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="induced-emigration-prob">
      <value value="0.05"/>
      <value value="0.1"/>
      <value value="0.2"/>
      <value value="0.3"/>
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="landing-prob">
      <value value="0.7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="repellent">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="sa_olf_1" repetitions="40" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="50"/>
    <metric>count turtles</metric>
    <metric>chd-main-crop</metric>
    <enumeratedValueSet variable="num-patches">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="insect-y-cor">
      <value value="99"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-insects">
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PlantLayout">
      <value value="&quot;intercrop&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colonisation">
      <value value="&quot;random&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="induced-emigration-prob">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-flight-length">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="detection-method">
      <value value="&quot;olfactory&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="damage-threshold-main-crop">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="flight-tendency-main-crop">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="flight-tendency-trap-crop">
      <value value="0.04"/>
      <value value="0.045"/>
      <value value="0.05"/>
      <value value="0.055"/>
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="damage-threshold-trap-crop">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="landing-prob">
      <value value="0.7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="insect-x-cor">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-half-patches">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="emigration-prob">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="repellent">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mortality-rate">
      <value value="0.0010"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="sa_olf_2" repetitions="40" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="50"/>
    <metric>count turtles</metric>
    <metric>chd-main-crop</metric>
    <enumeratedValueSet variable="num-patches">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="insect-y-cor">
      <value value="99"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-insects">
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PlantLayout">
      <value value="&quot;intercrop&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colonisation">
      <value value="&quot;random&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="induced-emigration-prob">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-flight-length">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="detection-method">
      <value value="&quot;olfactory&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="damage-threshold-main-crop">
      <value value="80"/>
      <value value="90"/>
      <value value="100"/>
      <value value="110"/>
      <value value="120"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="flight-tendency-main-crop">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="flight-tendency-trap-crop">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="damage-threshold-trap-crop">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="landing-prob">
      <value value="0.7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="insect-x-cor">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-half-patches">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="emigration-prob">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="repellent">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mortality-rate">
      <value value="0.0010"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="sa_olf_3" repetitions="40" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="50"/>
    <metric>count turtles</metric>
    <metric>chd-main-crop</metric>
    <enumeratedValueSet variable="num-patches">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="insect-y-cor">
      <value value="99"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-insects">
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PlantLayout">
      <value value="&quot;intercrop&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colonisation">
      <value value="&quot;random&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="induced-emigration-prob">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-flight-length">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="detection-method">
      <value value="&quot;olfactory&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="damage-threshold-main-crop">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="flight-tendency-main-crop">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="flight-tendency-trap-crop">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="damage-threshold-trap-crop">
      <value value="80"/>
      <value value="90"/>
      <value value="100"/>
      <value value="110"/>
      <value value="120"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="landing-prob">
      <value value="0.7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="insect-x-cor">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-half-patches">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="emigration-prob">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="repellent">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mortality-rate">
      <value value="0.0010"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="sa_olf_4" repetitions="40" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="50"/>
    <metric>count turtles</metric>
    <metric>chd-main-crop</metric>
    <enumeratedValueSet variable="num-patches">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="insect-y-cor">
      <value value="99"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-insects">
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PlantLayout">
      <value value="&quot;intercrop&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colonisation">
      <value value="&quot;random&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="induced-emigration-prob">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-flight-length">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="detection-method">
      <value value="&quot;olfactory&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="damage-threshold-main-crop">
      <value value="80"/>
      <value value="90"/>
      <value value="100"/>
      <value value="110"/>
      <value value="120"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="flight-tendency-main-crop">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="flight-tendency-trap-crop">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="damage-threshold-trap-crop">
      <value value="80"/>
      <value value="90"/>
      <value value="100"/>
      <value value="110"/>
      <value value="120"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="landing-prob">
      <value value="0.7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="insect-x-cor">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-half-patches">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="emigration-prob">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="repellent">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mortality-rate">
      <value value="0.0010"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="sa_olf_4" repetitions="40" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="50"/>
    <metric>count turtles</metric>
    <metric>chd-main-crop</metric>
    <enumeratedValueSet variable="num-patches">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="insect-y-cor">
      <value value="99"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-insects">
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PlantLayout">
      <value value="&quot;intercrop&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colonisation">
      <value value="&quot;random&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="induced-emigration-prob">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-flight-length">
      <value value="8"/>
      <value value="9"/>
      <value value="10"/>
      <value value="11"/>
      <value value="12"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="detection-method">
      <value value="&quot;olfactory&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="damage-threshold-main-crop">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="flight-tendency-main-crop">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="flight-tendency-trap-crop">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="damage-threshold-trap-crop">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="landing-prob">
      <value value="0.7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="insect-x-cor">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-half-patches">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="emigration-prob">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="repellent">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mortality-rate">
      <value value="0.0010"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="sa_olf_5" repetitions="40" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="50"/>
    <metric>count turtles</metric>
    <metric>chd-main-crop</metric>
    <enumeratedValueSet variable="num-patches">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="insect-y-cor">
      <value value="99"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-insects">
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PlantLayout">
      <value value="&quot;intercrop&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colonisation">
      <value value="&quot;random&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="induced-emigration-prob">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-flight-length">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="detection-method">
      <value value="&quot;olfactory&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="damage-threshold-main-crop">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="flight-tendency-main-crop">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="flight-tendency-trap-crop">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="damage-threshold-trap-crop">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="landing-prob">
      <value value="0.7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="insect-x-cor">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-half-patches">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="emigration-prob">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="repellent">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mortality-rate">
      <value value="8.0E-4"/>
      <value value="9.0E-4"/>
      <value value="0.0010"/>
      <value value="0.0011"/>
      <value value="0.0012"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="sa_olf_6" repetitions="40" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="50"/>
    <metric>count turtles</metric>
    <metric>chd-main-crop</metric>
    <enumeratedValueSet variable="num-patches">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="insect-y-cor">
      <value value="99"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-insects">
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PlantLayout">
      <value value="&quot;intercrop&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colonisation">
      <value value="&quot;random&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="induced-emigration-prob">
      <value value="0.0040"/>
      <value value="0.0045"/>
      <value value="0.05"/>
      <value value="0.055"/>
      <value value="0.06"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-flight-length">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="detection-method">
      <value value="&quot;olfactory&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="damage-threshold-main-crop">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="flight-tendency-main-crop">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="flight-tendency-trap-crop">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="damage-threshold-trap-crop">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="landing-prob">
      <value value="0.7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="insect-x-cor">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-half-patches">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="emigration-prob">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="repellent">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mortality-rate">
      <value value="0.0010"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="sa_olf_7" repetitions="40" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="50"/>
    <metric>count turtles</metric>
    <metric>chd-main-crop</metric>
    <enumeratedValueSet variable="num-patches">
      <value value="20"/>
      <value value="22"/>
      <value value="25"/>
      <value value="27"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="insect-y-cor">
      <value value="99"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-insects">
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PlantLayout">
      <value value="&quot;patches&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colonisation">
      <value value="&quot;random&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="induced-emigration-prob">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-flight-length">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="detection-method">
      <value value="&quot;olfactory&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="damage-threshold-main-crop">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="flight-tendency-main-crop">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="flight-tendency-trap-crop">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="damage-threshold-trap-crop">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="landing-prob">
      <value value="0.7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="insect-x-cor">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-half-patches">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="emigration-prob">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="repellent">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mortality-rate">
      <value value="0.0010"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles</metric>
    <enumeratedValueSet variable="repellent">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PlantLayout">
      <value value="&quot;intercrop&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="insect-y-cor">
      <value value="99"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="flight-tendency-trap-crop">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="emigration-prob">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-flight-length">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="landing-prob">
      <value value="0.7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-patches">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-half-patches">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="flight-tendency-main-crop">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="damage-threshold-main-crop">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-insects">
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colonisation">
      <value value="&quot;random&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="detection-method">
      <value value="&quot;visual&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mortality-rate">
      <value value="0.0010"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="damage-threshold-trap-crop">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="induced-emigration-prob">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="insect-x-cor">
      <value value="0"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Experiment Two Three  one run only" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="50"/>
    <metric>count turtles</metric>
    <metric>chd-trap-crop</metric>
    <metric>chd-main-crop</metric>
    <metric>on-trap</metric>
    <metric>on-main</metric>
    <metric>trap-trap</metric>
    <metric>trap-crop</metric>
    <metric>crop-crop</metric>
    <metric>crop-trap</metric>
    <enumeratedValueSet variable="repellent">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="detection-method">
      <value value="&quot;olfactory&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="flight-tendency-main-crop">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-patches">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-half-patches">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-insects">
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mortality-rate">
      <value value="0.0010"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="damage-threshold-trap-crop">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colonisation">
      <value value="&quot;random&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="emigration-prob">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="insect-x-cor">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-flight-length">
      <value value="1"/>
      <value value="3"/>
      <value value="5"/>
      <value value="10"/>
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="insect-y-cor">
      <value value="99"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="flight-tendency-trap-crop">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PlantLayout">
      <value value="&quot;intercrop&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="damage-threshold-main-crop">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="induced-emigration-prob">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="landing-prob">
      <value value="0.7"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180

@#$#@#$#@
0
@#$#@#$#@
