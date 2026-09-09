-- Spawn constants and the seven route tables the locations and connections are built from:
-- the speed, the five angles, the per-location densities and 7-wide class ratios, and one route
-- per connection ramping origin mix at 0.1 to destination mix at 0.9. Satisfies DESIGN.md section 1.
-- Shape of space-age/prototypes/planet/asteroid-spawn-definitions.lua:1-53 with a 7-slot vector.
-- Every density is a placeholder to tune.

local routes = {}

routes.standard_speed = 1 * meter/second

routes.weighted_average = function(A, B, weight)
  local result = A + ((B-A)*weight)
  return result
end

-- Ratio slots are {s, m, c, v, e, d, promethium}.
routes.home_ratio   = {75,  0, 25,  0,  0,  0, 0}
routes.inner_ratio  = {50, 25,  0,  0, 25,  0, 0}
routes.psyche_ratio = {20, 70,  0,  0, 10,  0, 0}
routes.vesta_ratio  = {30,  0, 10, 60,  0,  0, 0}
routes.outer_ratio  = {10,  0, 50,  0,  0, 40, 0}
routes.trojan_ratio = { 0,  0, 20,  0,  0, 80, 0}
routes.edge_ratio   = { 3,  0,  5,  0,  0,  2, 0}

routes.home_chunks   = 0.0125
routes.home_small    = 0.0008
routes.home_medium   = 0.0003
routes.inner_chunks  = 0.0030
routes.inner_medium  = 0.0025
routes.psyche_chunks = 0.0025
routes.psyche_big    = 0.0025
routes.psyche_huge   = 0.0005
routes.vesta_chunks  = 0.0025
routes.vesta_medium  = 0.0025
routes.vesta_big     = 0.0010
routes.outer_chunks  = 0.0015
routes.outer_medium  = 0.0025
routes.outer_big     = 0.0020
routes.trojan_chunks = 0.0030
routes.trojan_big    = 0.0030
routes.trojan_huge   = 0.0015
routes.edge_chunks   = 0.0005
routes.edge_huge     = 0.00125

routes.chunk_angle = 1
routes.small_angle = 0.7
routes.medium_angle = 0.6
routes.big_angle = 0.5
routes.huge_angle = 0.4

-- Two rows: the origin density at 0.1 and the destination density at 0.9.
local function ramp(size, from, to)
  local angle = routes[size .. "_angle"]
  return
  {
    {position = 0.1, probability = from, angle_when_stopped = angle},
    {position = 0.9, probability = to, angle_when_stopped = angle}
  }
end

-- The vanilla mid-route spike for medium and big asteroids. A size that appears along the way
-- peaks at three times the destination density at 0.5 (nauvis_vulcanus); one present at both
-- ends peaks at three times their average (vulcanus_gleba); one fading out ramps straight to
-- zero with no spike (gleba_aquilo).
local function spiked(size, from, to)
  local angle = routes[size .. "_angle"]
  if to == 0 then
    return ramp(size, from, to)
  end
  local peak = to * 3
  if from > 0 then
    peak = routes.weighted_average(from, to, 0.5) * 3
  end
  return
  {
    {position = 0.1, probability = from, angle_when_stopped = angle},
    {position = 0.5, probability = peak, angle_when_stopped = angle},
    {position = 0.9, probability = to, angle_when_stopped = angle}
  }
end

local function mix(from, to)
  return
  {
    {position = 0.1, ratios = from},
    {position = 0.9, ratios = to}
  }
end

-- Home Orbit to Inner Belt. Home spawns chunks, small and medium only.
routes.home_inner =
{
  probability_on_range_chunk = ramp("chunk", routes.home_chunks, routes.inner_chunks),
  probability_on_range_small = ramp("small", routes.home_small, 0),
  probability_on_range_medium = spiked("medium", routes.home_medium, routes.inner_medium),
  type_ratios = mix(routes.home_ratio, routes.inner_ratio)
}

-- Inner Belt to Psyche Field. Medium fades out, big and huge arrive.
routes.inner_psyche =
{
  probability_on_range_chunk = ramp("chunk", routes.inner_chunks, routes.psyche_chunks),
  probability_on_range_medium = spiked("medium", routes.inner_medium, 0),
  probability_on_range_big = spiked("big", 0, routes.psyche_big),
  probability_on_range_huge = ramp("huge", 0, routes.psyche_huge),
  type_ratios = mix(routes.inner_ratio, routes.psyche_ratio)
}

-- Inner Belt to Vesta Family.
routes.inner_vesta =
{
  probability_on_range_chunk = ramp("chunk", routes.inner_chunks, routes.vesta_chunks),
  probability_on_range_medium = spiked("medium", routes.inner_medium, routes.vesta_medium),
  probability_on_range_big = spiked("big", 0, routes.vesta_big),
  type_ratios = mix(routes.inner_ratio, routes.vesta_ratio)
}

-- Home Orbit to Outer Belt. The long way out.
routes.home_outer =
{
  probability_on_range_chunk = ramp("chunk", routes.home_chunks, routes.outer_chunks),
  probability_on_range_small = ramp("small", routes.home_small, 0),
  probability_on_range_medium = spiked("medium", routes.home_medium, routes.outer_medium),
  probability_on_range_big = spiked("big", 0, routes.outer_big),
  type_ratios = mix(routes.home_ratio, routes.outer_ratio)
}

-- Outer Belt to Trojan Cloud.
routes.outer_trojan =
{
  probability_on_range_chunk = ramp("chunk", routes.outer_chunks, routes.trojan_chunks),
  probability_on_range_medium = spiked("medium", routes.outer_medium, 0),
  probability_on_range_big = spiked("big", routes.outer_big, routes.trojan_big),
  probability_on_range_huge = ramp("huge", 0, routes.trojan_huge),
  type_ratios = mix(routes.outer_ratio, routes.trojan_ratio)
}

-- Vesta Family to Solar System Edge. Ends on the vanilla Edge densities.
routes.vesta_edge =
{
  probability_on_range_chunk = ramp("chunk", routes.vesta_chunks, routes.edge_chunks),
  probability_on_range_medium = spiked("medium", routes.vesta_medium, 0),
  probability_on_range_big = spiked("big", routes.vesta_big, 0),
  probability_on_range_huge = ramp("huge", 0, routes.edge_huge),
  type_ratios = mix(routes.vesta_ratio, routes.edge_ratio)
}

-- Solar System Edge to Shattered Planet: the vanilla shattered_planet_trip rows
-- (asteroid-spawn-definitions.lua:216-237) with each {metallic, carbonic, oxide, promethium}
-- vector written as {s, 0, c, 0, 0, d, promethium}. Keeps the vanilla 0.001 and 0.999 ends.
routes.edge_shattered =
{
  has_promethium_asteroids = true,
  probability_on_range_huge =
  {
    {position = 0.001, probability = routes.edge_huge, angle_when_stopped = routes.huge_angle},
    {position = 0.999, probability = 0.111, angle_when_stopped = routes.huge_angle}
  },
  type_ratios =
  {
    {position = 0.001, ratios = routes.edge_ratio},
    {position = 0.002, ratios = { 3/10*16, 0, 5/10*16, 0, 0, 2/10*16,   0.04 }},
    {position = 0.2,   ratios = {  5, 0, 3, 0, 0, 8,   0.40 }},
    {position = 0.3,   ratios = {  3, 0, 9, 0, 0, 4,   2.03 }},
    {position = 0.4,   ratios = {  7, 0, 6, 0, 0, 3,   6.40 }},
    {position = 0.5,   ratios = {  9, 0, 2, 0, 0, 5,  15.63 }},
    {position = 0.6,   ratios = {  2, 0, 6, 0, 0, 8,  32.40 }},
    {position = 0.7,   ratios = {  8, 0, 2, 0, 0, 5,  60.03 }},
    {position = 0.8,   ratios = {  3, 0, 9, 0, 0, 4, 102.40 }},
    {position = 0.999, ratios = { 10, 0, 2, 0, 0, 4, 164.03 }}
  }
}

return routes
