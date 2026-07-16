
-- The Collegium device, hand-authored at the size it is SHOWN (17x22 — the medallion's field).
-- '#' = lit metal, '+' = lower relief. Every pixel is placed, not derived: at this size a shape
-- function cannot make the calls that matter (which single pixel carries the crossguard, where
-- the ridge sits). gen_header.py reads this as the device's alpha+luminance and strikes it in
-- bronze relief; Aseprite owns the SPRITE, Python owns the surface. (TD-057.)
local map = {
  "........#........",   -- pommel: the author's diamond
  ".......###.......",
  "........#........",
  "........+........",   -- grip
  "......#####......",   -- upper (patriarchal) crossguard
  "........+........",
  "...###########...",   -- main crossguard
  ".......+#+.......",   -- blade: lit ridge down the centre
  "....#..+#+..#....",   -- laurel tips begin
  "...#+..+#+..+#...",
  "..#+...+#+...+#..",
  "..#....+#+....#..",
  "..#+...+#+...+#..",
  "..#.....#.....#..",   -- blade narrows to the tip
  "..#+....#....+#..",
  "...#....#....#...",
  "...#+...#...+#...",
  "....#...#...#....",
  ".....#..#..#.....",
  "........#........",
  "........+........",   -- tip
  ".................",
}
local BRIGHT = app.pixelColor.rgba(238, 212, 156, 255)
local MID    = app.pixelColor.rgba(146, 122,  80, 255)
local spr = Sprite(17, 22, ColorMode.RGB)
local img = spr.cels[1].image
for y = 1, #map do
  local row = map[y]
  for x = 1, #row do
    local ch = row:sub(x, x)
    if ch == "#" then img:drawPixel(x - 1, y - 1, BRIGHT)
    elseif ch == "+" then img:drawPixel(x - 1, y - 1, MID) end
  end
end
spr:saveAs("C:/Users/jerwi/AppData/Local/Temp/device.png")
spr:saveAs("C:/Users/jerwi/AppData/Local/Temp/collegium_device.aseprite")
print("device drawn: " .. spr.width .. "x" .. spr.height)
