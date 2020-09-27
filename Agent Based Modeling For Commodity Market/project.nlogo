globals [logB logS marketmakeroptions speculation-bottom-line speculation-upper-line marketmakercash marketmakerasset futuresprice askprice bidprice strike-price calloptionprice putoptionprice previous-futuresprice finalformula]
breed [Hedgers Hedger]
breed [Speculators Speculator]
breed [Marketmakers Marketmaker]
Speculators-own[buy sell getinformation price cash options bankruptcy]
Hedgers-own[buy sell getinformation cash options]

to setup
  ca
  set logB []
  set logS []
  set marketmakeroptions market-maker-options
  set marketmakercash market-maker-cash
  reset-ticks
  ;exogenous-effect
  set futuresprice spot-price * (1 + random-normal 0 finalformula)
  create-Speculators speculator-population [set shape "person" set bankruptcy false set cash speculator-mean-cash + (random-normal 0 20) setxy int random-xcor int random-ycor]
  create-Marketmakers 1 [set shape "house"  set size 2 setxy int random-xcor int random-ycor]
  create-Hedgers 5 [set shape "square" set size 1 setxy int random-xcor int random-ycor]
  let side sqrt speculator-population let step max-pxcor / side let an 0 let x 0 let y 0
  while [an < speculator-population][if x > (side - 1) * step [set y y + step set x 0] ask Speculator an [setxy x y] set x x + step set an an + 1]
end

to go
  initialize
  ask Speculators [ifelse random-float 1 < marketmaker-participation-rate / 100 [speculators-trade-with-marketmaker][speculatorstrade]]
  update-speculators-status
  hedgerstrade
  set-price-limit
end

to set-price-limit
  set speculation-upper-line futuresprice + (variable-price-limit / 2)
  ifelse futuresprice - (variable-price-limit / 2) > 0[
    set speculation-bottom-line futuresprice - (variable-price-limit / 2)][set speculation-bottom-line 1 / 4 * futuresprice]
end

to exogenous-effect
  let productivity-factor (- 1 / (productivity) ^ 2 )
  let policy-factor  ( 1 - 1 / (1 +  exp (policy-effect * -1)))
  let natural-factor  0.1 * natural-effect
  let pdt-factor-portion (prob_productivity / (prob_productivity + prob_natural + prob_regulation))
  let n-factor-portion (prob_natural / (prob_productivity + prob_natural + prob_regulation))
  let r-factor-portion (prob_regulation / (prob_productivity + prob_natural + prob_regulation))
  set finalformula pdt-factor-portion * productivity-factor + n-factor-portion * natural-factor + r-factor-portion * policy-factor
end

to  initialize
  ask Marketmaker speculator-population [ set askprice futuresprice + spread / 2 set bidprice futuresprice - spread / 2 ]
  ask Speculators
  [ if not bankruptcy [
    ifelse random-float 1 < (1 - speculator-participation-rate / 100) [set getinformation true]
    [set getinformation false]
    ifelse not getinformation
    [ifelse random-float 1 < 0.5 [set buy true set sell false] [set buy false set sell true ]]
    [set buy false set sell false]
    let price-var 10
    set price futuresprice + (random-normal 0 price-var)
    ifelse ticks = 0 [
    if futuresprice < initial-speculation-bottom-line [set buy true set sell false set getinformation false]
    if futuresprice > initial-speculation-upper-line  [set buy false set sell true set getinformation false]]
    [if futuresprice < speculation-bottom-line [set buy true set sell false set getinformation false]
    if futuresprice > speculation-upper-line  [set buy false set sell true set getinformation false]]
    if getinformation [set color gray] if buy [set color red] if sell [set color green]]
    set logB [] set logS []]
  tick
end

to speculatorstrade
  ask Speculators
  [if not getinformation and not bankruptcy
    [ let tmp []
      set tmp lput price tmp
      set tmp lput who tmp
      ;show tmp
      if buy [set logB lput tmp logB]
      set logB sort-by [[a b] -> first a < first b]logB
      ;show logB
      if (not empty? logB and not empty? logS) and item 0 (item 0 logB) >= item 0 ( item 0 logS)
      [set futuresprice (item 0 (item 0 logS))
        let agB item 1 (item 0 logB) let agS item 1 (item 0 logS)
        ask Speculator agB [set options options + 1 set cash cash - futuresprice]
        ask Speculator agS [set options options - 1 set cash cash + futuresprice]
        set logB but-first logB set logS but-first logS]
      if sell [set logS lput tmp logS]
      set logS sort-by [[a b] -> first a > first b] logS
      ;show logS
      if (not empty? logB and not empty? logS) and item 0 (item 0 logB) >= item 0 ( item 0 logS)
      [set futuresprice item 0 (item 0 logB)
        let agB item 1 (item 0 logB) let agS item 1 (item 0 logS)
        ask Speculator agB [set options options + 1 set cash cash - futuresprice]
        ask Speculator agS [set options options - 1 set cash cash + futuresprice]
        set logB but-first logB set logS but-first logS]
     ]]
end

to speculators-trade-with-marketmaker
if not getinformation and not bankruptcy
  [let tmp [] set tmp lput price tmp set tmp lput who tmp
  if buy [set logB lput tmp logB]
  set logB sort-by [[a b] -> first a < first b]logB
  ifelse (not empty? logB and not empty? logS) and askprice < item 0 (item 0 logS) and item 0 (item 0 logB) >= askprice and marketmakeroptions > 0 or (not empty? logB and empty? logS) and item 0 (item 0 logB) >= askprice and marketmakeroptions > 0
  [set futuresprice askprice let agB item 1 (item 0 logB)
  ask Speculator agB [set options options + 1 set cash cash - futuresprice]
  ask Marketmaker speculator-population [set marketmakeroptions marketmakeroptions - 1 set marketmakercash marketmakercash + futuresprice
  ifelse marketmakeroptions > 0 [set marketmakerasset marketmakercash + (marketmakeroptions * futuresprice)] [set marketmakerasset marketmakercash]]
      set logB but-first logB]
  [if (not empty? logB and not empty? logS) and item 0 (item 0 logB) >= item 0 ( item 0 logS)
  [set futuresprice item 0 (item 0 logS)
  let agB item 1 (item 0 logB) let agS item 1 (item 0 logS)
  ask Speculator agB [set options options + 1 set cash cash - futuresprice]
  ask Speculator agS [set options options - 1 set cash cash + futuresprice]
  set logB but-first logB set logS but-first logS]]
  if sell [set logS lput tmp logS] set logS sort-by [[a b] -> first a > first b] logS
  ifelse (not empty? logB and not empty? logS) and bidprice > item 0 ( item 0 logB) and bidprice >= item 0 (item 0 logS) and marketmakercash >= bidprice or (empty? logB and not empty? logS) and bidprice >= item 0 (item 0 logS) and marketmakercash >= bidprice
  [set futuresprice bidprice let agS item 1 (item 0 logS)
  ask Speculator agS [set options options - 1 set cash cash + futuresprice]
  ask Marketmaker speculator-population [set marketmakeroptions marketmakeroptions + 1 set marketmakercash marketmakercash - futuresprice
  ifelse marketmakeroptions > 0 [set marketmakerasset marketmakercash + (marketmakeroptions * futuresprice)] [set marketmakerasset marketmakercash]]
  ;show logs
      set logS but-first logS]
  [if (not empty? logB and not empty? logS) and item 0 (item 0 logB) >= item 0 ( item 0 logS)
  [set futuresprice item 0 (item 0 logB)
  let agB item 1 (item 0 logB) let agS item 1 (item 0 logS)
  ask Speculator agB [set options options + 1 set cash cash - futuresprice]
  ask Speculator agS [set options options - 1 set cash cash + futuresprice]
  set logB but-first logB set logS but-first logS]]]
end

to update-speculators-status
  let getinfo-cash-flow 1000
  ask Speculators
  [if cash < futuresprice [set buy false set sell false set getinformation true]
   if getinformation [ifelse random-float 1 < 0.5  [set cash cash + random getinfo-cash-flow] [set cash cash - random (getinfo-cash-flow / 2)]]
   if cash < 0 [set cash 0 set bankruptcy true set buy false set sell false set getinformation false set color black]
  ]
end


to hedgerstrade
  ;simplify Black Scholes model and Delta Hedging
  let optionratio-var 0.13
  let optionratio (option-ratio / 100 + random-float optionratio-var)
  let strike-price-var 10
  set strike-price ( spot-price + random-normal 0 strike-price-var )
  let putoption-price strike-price * ( - optionratio + random-normal 0 1) - futuresprice * ( - optionratio + random-normal 0 1)
  let calloption-price futuresprice * ( optionratio + random-normal 0 1) - strike-price * ( optionratio + random-normal 0 1)
  set putoptionprice ( futuresprice + putoption-price )
  set calloptionprice ( futuresprice + calloption-price )
  let black-scholes-ratio 0.20
  let black-scholes-call-option-price putoptionprice * ( 1 + random-float black-scholes-ratio )
  ifelse calloptionprice > Black-Scholes-call-option-price ;-ve:long calls short puts/ +ve：long puts short calls
  [ask hedgers [let deltac 0.05 + random-float 0.35 let finaloffset deltac * futuresprice - calloptionprice  set options options - 1 set cash cash + finaloffset]]
  [ask hedgers [let deltac 0.05 + random-float 0.35 let finaloffset calloptionprice - deltac * futuresprice set options options + 1 set cash cash + finaloffset]]
  let black-scholes-put-option-price calloptionprice * ( 1 + random-float 0.20 )
  ifelse putoptionprice < Black-Scholes-put-option-price
  [ask hedgers [let deltap 0.05 + random-float 0.35 let finaloffset deltap * futuresprice - putoptionprice set options options - 1 set cash cash + finaloffset]]
  [ask hedgers [let deltap 0.05 + random-float 0.35 let finaloffset putoptionprice - deltap * futuresprice set options options + 1 set cash cash + finaloffset]]
end

to updatehedgersprofit
  set-current-plot "hedgersprofit"
  clear-plot
  let i 0
  ask hedgers [
  create-temporary-plot-pen (word who)
  set-plot-pen-color random 140
  set-plot-pen-mode 1
  plotxy i cash
  set i (i + 1)]
end
@#$#@#$#@
GRAPHICS-WINDOW
209
10
646
448
-1
-1
13.0
1
10
1
1
1
0
1
1
1
-16
16
-16
16
0
0
1
ticks
30.0

BUTTON
15
44
81
77
setup
setup
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
104
44
185
77
go once
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

PLOT
658
18
858
168
Crude Oil Price Trend
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"pen-0" 1.0 0 -5298144 true "" "plot futuresprice"

BUTTON
14
94
77
127
go
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

MONITOR
657
179
794
224
Crude Oil Price
futuresprice
2
1
11

SLIDER
0
236
206
269
spread
spread
1
20
15.0
1
1
NIL
HORIZONTAL

SLIDER
0
288
206
321
marketmaker-participation-rate
marketmaker-participation-rate
0
40
20.0
1
1
NIL
HORIZONTAL

SLIDER
0
332
208
365
speculator-participation-rate
speculator-participation-rate
0
100
60.0
1
1
NIL
HORIZONTAL

MONITOR
655
238
796
283
market maker bid price
bidprice
2
1
11

MONITOR
652
299
796
344
market maker ask price
askprice
2
1
11

SLIDER
2
380
207
413
initial-speculation-bottom-line
initial-speculation-bottom-line
20
40
35.0
1
1
NIL
HORIZONTAL

SLIDER
2
425
206
458
initial-speculation-upper-line
initial-speculation-upper-line
70
100
90.0
1
1
NIL
HORIZONTAL

MONITOR
651
352
797
397
marketmakerasset
marketmakerasset
2
1
11

SLIDER
208
608
415
641
market-maker-options
market-maker-options
0
100
80.0
1
1
NIL
HORIZONTAL

SLIDER
0
516
206
549
market-maker-cash
market-maker-cash
1000
10000
10000.0
1
1
NIL
HORIZONTAL

MONITOR
650
403
798
448
NIL
marketmakercash
2
1
11

SLIDER
0
562
173
595
productivity
productivity
0
10
4.0
1
1
NIL
HORIZONTAL

SLIDER
0
604
172
637
policy-effect
policy-effect
0
10
6.0
1
1
NIL
HORIZONTAL

SLIDER
0
642
172
675
natural-effect
natural-effect
0
10
2.0
1
1
NIL
HORIZONTAL

SLIDER
213
452
405
485
option-ratio
option-ratio
0
20
6.0
1
1
NIL
HORIZONTAL

SLIDER
0
187
205
220
spot-price
spot-price
0
100
70.0
1
1
NIL
HORIZONTAL

MONITOR
649
454
754
499
NIL
calloptionprice
2
1
11

MONITOR
761
454
866
499
NIL
putoptionprice
2
1
11

SLIDER
210
507
405
540
speculator-mean-cash
speculator-mean-cash
100
500
244.0
1
1
NIL
HORIZONTAL

SLIDER
208
563
404
596
speculator-population
speculator-population
20
100
80.0
1
1
NIL
HORIZONTAL

MONITOR
485
455
632
500
bankruptcy speculators
count speculators with [bankruptcy = true]
17
1
11

PLOT
522
511
722
661
hedgersprofit
NIL
NIL
0.0
5.0
0.0
5.0
true
true
"" "updatehedgersprofit"
PENS

SLIDER
6
689
178
722
prob_natural
prob_natural
0
1
0.22
0.01
1
NIL
HORIZONTAL

SLIDER
5
734
177
767
prob_productivity
prob_productivity
0
1
0.45
0.01
1
NIL
HORIZONTAL

SLIDER
5
779
177
812
prob_regulation
prob_regulation
0
1
0.32
0.01
1
NIL
HORIZONTAL

SLIDER
3
471
206
504
variable-price-limit
variable-price-limit
0
80
40.0
1
1
NIL
HORIZONTAL

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
NetLogo 6.1.1
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="speculator-participation" repetitions="20" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <exitCondition>ticks &gt; 100</exitCondition>
    <metric>count speculators with [color = black]</metric>
    <enumeratedValueSet variable="option-ratio">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="speculation-upper-line">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prob_natural">
      <value value="0.47"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="market-maker-cash">
      <value value="10000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prob_regulation">
      <value value="0.48"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="speculator-mean-cash">
      <value value="140"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spot-price">
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="speculation-bottom-line">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="marketmaker-participation-rate">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="natural-effect">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="speculator-population">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="speculator-participation-rate">
      <value value="0"/>
      <value value="20"/>
      <value value="40"/>
      <value value="60"/>
      <value value="80"/>
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prob_productivity">
      <value value="0.76"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="productivity">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="market-maker-options">
      <value value="68"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spread">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="futuresprice">
      <value value="40"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="policy-effect">
      <value value="6"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="marketmaker-cash" repetitions="5" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <exitCondition>ticks &gt; 100</exitCondition>
    <metric>count speculators with [color = black]</metric>
    <enumeratedValueSet variable="option-ratio">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="speculation-upper-line">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prob_natural">
      <value value="0.22"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="market-maker-cash">
      <value value="1000"/>
      <value value="2000"/>
      <value value="3000"/>
      <value value="4000"/>
      <value value="5000"/>
      <value value="6000"/>
      <value value="7000"/>
      <value value="8000"/>
      <value value="9000"/>
      <value value="10000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prob_regulation">
      <value value="0.32"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="speculator-mean-cash">
      <value value="184"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spot-price">
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="speculation-bottom-line">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="marketmaker-participation-rate">
      <value value="40"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="speculator-population">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="natural-effect">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="speculator-participation-rate">
      <value value="40"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prob_productivity">
      <value value="0.45"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="productivity">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="market-maker-options">
      <value value="68"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spread">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="policy-effect">
      <value value="6"/>
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
