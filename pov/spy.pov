// Copyright (c) 2002  Dustin Sallings <dustin@spy.net>
//
// $Id: spy.pov,v 1.7 2003/04/22 08:11:10 dustin Exp $

#include "colors.inc"
#include "shapes.inc"
#include "textures.inc"
#include "chars.inc"
#include "skies.inc"

#include "spy_words.inc"

#if(clock_on=0)
	camera {
		location <0, -1.8, -15>
		look_at <0, 0, 0>
	}
#else
	#debug concat("\nClock is ", str(clock,5,5), "\n")

	#if(clock < 1.0)
		camera {
			location <0, clock-1.8, -15*clock>
			look_at <0, 0, 0>
			#local r = 90-(90*clock);
			#debug concat("Angle is ", str(r,2,2), " for ", str(clock,5,5), "\n")
			rotate <0, 0, r>
		}
	#else
		camera {
			location <0, 1.8, -15>
			look_at <0, 0, 0>
		}
	#end
#end

// Declaration of a light
#declare a_light =
	union {
		light_source {
			<0, 1, -4>
			color Gray75
			looks_like {
				sphere { <0, 0, 0>, .3
					texture {
						Chrome_Texture
						pigment { White }
						normal { bumps 0.4 scale 0.2 }
					}
				}
			}
			fade_distance 5
			fade_power 2
		}

		cylinder {
			<0, .9, -4>, <0, -2, -4>, .1
			texture {
				Chrome_Texture
				pigment { White }
				normal { bumps 0.2 scale 0.2 }
			}
		}
	}

sky_sphere { S_Cloud5 }

// Light on the right

object {
	a_light
	translate <3.3, 0, 0>
}

// Light on the left

object {
	a_light
	translate <-3.3, 0, 0>
}

// The water

plane {
  <0, 2, 0>, -2
  texture { Water scale 15 }
  #if(clock_on)
  normal { phase clock }
  #end
  pigment { color red 0.5 green 0.5 blue 0.9}
  finish  { ambient .2 diffuse .4 reflection .8}
}

// Letter textures

#declare lettering = Brushed_Aluminum

#declare small_lettering =
texture {
	lettering
	pigment { rgb <0.15, 0.15, 0.4> }
}

// SPY
object {
	word_spy
	translate <0, -2, 0>
	texture { lettering }
}

// productions
#declare Font = "cyrvetic.ttf"

#declare final_productions =
	text { ttf Font
		"productions",.3,0
		translate <-2.5, 0, -1.5>
		rotate <0,0,15>
		texture { small_lettering }
		scale <1.5,1.5,1>
	}

#if(clock_on = 0)
	final_productions
#else
	#if(clock > 1)
		#local cl = (clock - 1.0);
		#if(cl > 1)
			final_productions
		#else
			text { ttf Font
				"productions",.3,0
				translate <-2.5, 0, 1+(-2.5*cl)>
				rotate <0,0,10+(5*cl)>
				texture { small_lettering }
				scale <0.5+cl,0.5+cl,1>
			}
		#end
	#end
#end
