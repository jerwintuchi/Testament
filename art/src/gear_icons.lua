-- Testament — the ten Collegium instruments, 24x24 each (TD-102 R373/R376).
--
-- HAND-PLACED PIXELS, not shape functions: TD-057 settled that a shape function
-- samples a curve and cannot decide WHICH pixel carries a crossguard, and TD-077 set
-- the precedent of authoring small art as ASCII stamps after five analytic passes
-- failed. Each glyph below is a 24x24 map, so a pixel is a decision.
--
-- GOLD IS RESERVED. No instrument uses the bright end of the gold ramp — that belongs
-- to selection, headings, the insignia and the seal (R376/P168). The previous sheet
-- broke this: `cantors-ear` was 204 opaque pixels dominated by #A6803A, the goldest
-- object on the whole screen, and at 24px it read as a UI arrow. It is now a dull
-- bronze horn seen side-on, with a bell that cannot be mistaken for a chevron.
--
-- Ash & Ember stops only.
--   k outline      d dark wood    m mid wood     l lit wood
--   g glass        G glass lit    p parchment    P parchment lit
--   b bronze dim   B bronze       i iron         I iron lit
--   r wax red      f flame        s salt/bone

-- MATERIALS, not colours (TD-103). Each letter names a substance; the shading pass
-- below picks the light, mid or dark tone from its triple by looking at the pixel's
-- NEIGHBOURS. That is how a pixel artist renders a small object — form first, fill
-- second — and it is why the previous sheet read as icons: every glyph was one flat
-- tone inside an outline, so nothing had a lit side or an occluded one.
--
-- Light comes from the upper-left, the convention the rest of the game's sprites use.
-- Gold's bright stops (#B08A3E, #D6AE5C) remain BANNED here: they belong to selection,
-- headings, the insignia and the seal (P168).
local MAT = {
  w = { "#7A5334", "#5A3D28", "#2A1B10" },   -- wood / horn
  g = { "#616A72", "#4C545A", "#2B2F33" },   -- glass
  i = { "#4C545A", "#2B2F33", "#22242A" },   -- iron
  b = { "#8C6C30", "#6E5426", "#3A2617" },   -- brass, capped below the bright gold
  n = { "#E0CF9F", "#CBB583", "#A8946A" },   -- bone / salt / parchment
  r = { "#C65A4E", "#8F2F2A", "#5E1D1A" },   -- wax / ember
  f = { "#F9DCA6", "#F0B25F", "#E8973C" },   -- flame, used sparingly
}
local OUTLINE = "#1C1813"

local function hexc(h)
  return Color{ r = tonumber(h:sub(2,3),16), g = tonumber(h:sub(4,5),16), b = tonumber(h:sub(6,7),16) }
end

-- Each glyph: 24 rows of 24 chars. '.' is transparent.
local ICONS = {}

-- 1. Ashen Lens — smoked glass, brown handle. Reads as a lens at a glance.
ICONS[1] = {
"........................",
"........................",
"........kkkkkk..........",
"......kkggggggkk........",
".....kggggggggggk.......",
"....kgggggggggggk.......",
"....kggggggggggggk......",
"...kggggggggggggggk.....",
"...kggggggggggggggk.....",
"...kggggggggggggggk.....",
"....kgggggggggggggk.....",
"....kggggggggggggk......",
".....kgggggggggggk......",
"......kkgggggggkk.......",
"........kkkkkkk.........",
"..........kwwk..........",
"...........kwwk.........",
"............kwwk........",
".............kwwk.......",
"..............kwwk......",
"...............kwk......",
"................k.......",
"........................",
"........................",
}

-- 2. Chirurgeon's Glass — reticled: a cross in the lens says "measured, not admired".
ICONS[2] = {
"........................",
"........................",
"........kkkkkk..........",
"......kkggggggkk........",
".....kggggigggggk.......",
"....kgggggigggggk.......",
"....kgggggiggggggk......",
"...kggggggigggggggk.....",
"...kiiiiiiiiiiiiiik.....",
"...kggggggigggggggk.....",
"....kgggggiggggggk......",
"....kgggggigggggk.......",
".....kggggiggggk........",
"......kkgggggkk.........",
"........kkkkk...........",
"..........kwwk..........",
"...........kwwk.........",
"............kwwk........",
".............kwwk.......",
"..............kwwk......",
"...............kwk......",
"................k.......",
"........................",
"........................",
}

-- 3. Witness Prism — a struck prism on a small stand. Triangular, unmistakable.
ICONS[3] = {
"........................",
"........................",
"..........kk............",
".........kggk...........",
".........kgggk..........",
"........kggggk..........",
"........kgggggk.........",
".......kggggggk.........",
".......kgggggggk........",
"......kggggggggk........",
"......kgggggggggk.......",
".....kggggggggggk.......",
".....kgggggggggggk......",
"....kggggggggggggk......",
"....kkkkkkkkkkkkkk......",
".....kiiiiiiiiiik.......",
"......kwwwwwwwwk........",
".......kwwwwwwk.........",
"........kkkkkk..........",
"........................",
"........................",
"........................",
"........................",
"........................",
}

-- 4. Tracker's Fetish — three talons on a knotted cord, in the old Choir manner.
ICONS[4] = {
"........................",
"..........kk............",
".........kwwk...........",
".........kwwk...........",
"........kkwwkk..........",
".......kwwwwwwk.........",
"......kwwwwwwwwk........",
"......kwwwwwwwwk........",
".......kwwwwwwk.........",
"........kkkkkk..........",
".......k..k..k..........",
"......kn.kn.kn..........",
"......kn.kn.kn..........",
".....kn..kn..kn.........",
".....kn..kn..kn.........",
"....kn...kn...kn........",
"....knn..knn..knn.......",
"...knn...knn...knn......",
"...kn.....kn....kn......",
"..kk......kk....kk......",
"........................",
"........................",
"........................",
"........................",
}

-- 5. Cantor's Ear — a bronze horn SEEN SIDE-ON, bell to the right, mouthpiece left.
--    The old sheet drew a filled chevron that read as a UI arrow; a horn needs a
--    hollow bell, a tapering throat and a visible mouthpiece to read as an object.
ICONS[5] = {
"........................",
"........................",
"........................",
"....................kk..",
"..................kkbbk.",
"................kkbbbbk.",
"..............kkbbbbbbk.",
"...........kkkbbbbbbbbk.",
".....kkkkkkbbbbbk...kbk.",
"...kkbbbbbbbbkk.....kbk.",
"..kbbkkkkbbbk.......kbk.",
"..kbk...kbbk........kbk.",
"..kbk...kbbbk.......kbk.",
"..kbbkkkkbbbbkk.....kbk.",
"...kkbbbbbbbbbbbk...kbk.",
".....kkkkkkbbbbbbbbbbbk.",
"..............kkbbbbbbk.",
"................kkbbbk..",
"..................kkk...",
"........................",
"........................",
"........................",
"........................",
"........................",
}

-- 6. Augur's Bead — weighted lead on a cord: a plumb bob, hanging.
ICONS[6] = {
"..........kk............",
"..........kn............",
"..........kn............",
"..........kn............",
"..........kn............",
"..........kn............",
"..........kn............",
".........kkkk...........",
"........kiiiik..........",
".......kiiiiiik.........",
"......kiiiiiiiik........",
"......kiiiiiiiik........",
"......kiiiiiiiik........",
"......kiiiiiiiik........",
".......kiiiiiik.........",
".......kiiiiiik.........",
"........kiiiik..........",
".........kiik...........",
"..........kk............",
"........................",
"........................",
"........................",
"........................",
"........................",
}

-- 7. Censer of Embers — a hanging censer with chains and a lit coal.
ICONS[7] = {
"..........kk............",
".........k..k...........",
"........k....k..........",
".......k......k.........",
"......k........k........",
".....kbkkkkkkkkbk.......",
".....kbbbbbbbbbbk.......",
"......kbbbbbbbbk........",
"......kbbbrrbbbk........",
".....kbbbrrrrbbbk.......",
".....kbbbrfrrbbbk.......",
"....kbbbbrrrrbbbbk......",
"....kbbbbbrrbbbbbk......",
"....kbbbbbbbbbbbbk......",
".....kbbbbbbbbbbk.......",
".....kkbbbbbbbbkk.......",
".......kbbbbbbk.........",
"........kkkkkk..........",
"..........kk............",
"........................",
"........................",
"........................",
"........................",
"........................",
}

-- 8. Phial of Hoarfrost — a stoppered phial, pale and cold-looking but not blue-bright.
ICONS[8] = {
"........................",
"........kkkk............",
"........kwwk............",
"........kwwk............",
"........kkkk............",
".......kkggkk...........",
".......kggggk...........",
"......kggggggk..........",
".....kggggggggk.........",
".....kggggggggk.........",
".....kggiiiiggk.........",
".....kgiiiiiigk.........",
".....kgiiiiiigk.........",
".....kgiiiiiigk.........",
".....kgiiiiiigk.........",
".....kggiiiiggk.........",
"......kggggggk..........",
"......kkggggkk..........",
".......kkkkkk...........",
"........................",
"........................",
"........................",
"........................",
"........................",
}

-- 9. Consecrated Salt — an open dish, heaped. Bone-white, never gold.
ICONS[9] = {
"........................",
"........................",
"........................",
"........................",
"..........nn............",
".........nnnn...........",
"........nnnnnn..........",
".......nnnnnnnn.........",
"......nnnnnnnnnnn.......",
".....knnnnnnnnnnk.......",
"....kwnnnnnnnnnnwk......",
"...kwwwwwwwwwwwwwwk.....",
"...kwwwwwwwwwwwwwwk.....",
"....kwwwwwwwwwwwwk......",
".....kwwwwwwwwwwk.......",
"......kwwwwwwwwk........",
".......kkkkkkkk.........",
"........................",
"........................",
"........................",
"........................",
"........................",
"........................",
"........................",
}

-- 10. Lantern of the Creed — an iron lantern with a warm pane. Restrained flame.
ICONS[10] = {
"..........kk............",
".........k..k...........",
".........kiik...........",
"........kiiiik..........",
".......kiiiiiik.........",
"......kiiiiiiiik........",
"......kiiiiiiiik........",
"......kiiffffiik........",
"......kiiffffiik........",
"......kiiffffiik........",
"......kiiffffiik........",
"......kiiffffiik........",
"......kiiffffiik........",
"......kiiiiiiiik........",
"......kiiiiiiiik........",
".....kiiiiiiiiiik.......",
".....kiiiiiiiiiik.......",
".....kiiiiiiiiiik.......",
"......kkkkkkkkkk........",
"........................",
"........................",
"........................",
"........................",
"........................",
}

local N = #ICONS
local W, H = 24, 24
local sprite = Sprite(W * N, H, ColorMode.RGB)
sprite.filename = app.params["out"] or "gear_icons.png"

local img = Image(sprite.width, sprite.height, ColorMode.RGB)
img:clear(Color{ r=0, g=0, b=0, a=0 })

-- Form-aware shading: a pixel is LIT if nothing sits above-left of it (so it is on the
-- surface facing the light), SHADED if nothing sits below-right (an edge rolling away),
-- and MID otherwise. `k` stays a hard outline — the pixel-art register keeps its edges.
local function at(glyph, x, y)
  if y < 1 or y > #glyph then return "." end
  local row = glyph[y]
  if x < 1 or x > #row then return "." end
  return row:sub(x, x)
end

local function solid(ch) return ch ~= "." end

for n = 1, N do
  local glyph = ICONS[n]
  local ox = (n - 1) * W
  for y = 1, H do
    for x = 1, W do
      local ch = at(glyph, x, y)
      if ch ~= "." then
        local col
        if ch == "k" then
          col = hexc(OUTLINE)
        else
          local m = MAT[ch]
          if m == nil then m = MAT.w end
          local up = at(glyph, x, y - 1)
          local left = at(glyph, x - 1, y)
          local down = at(glyph, x, y + 1)
          local right = at(glyph, x + 1, y)
          local lit = (not solid(up)) or up == "k" or (not solid(left)) or left == "k"
          local dark = (not solid(down)) or down == "k" or (not solid(right)) or right == "k"
          if lit and not dark then
            col = hexc(m[1])
          elseif dark and not lit then
            col = hexc(m[3])
          else
            col = hexc(m[2])
          end
        end
        img:drawPixel(ox + x - 1, y - 1, col)
      end
    end
  end
end

sprite.cels[1].image = img
sprite.cels[1].position = Point(0, 0)

app.command.SaveFileCopyAs{ filename = app.params["out"] }
if app.params["src"] then
  sprite:saveAs(app.params["src"])
end
print("wrote " .. tostring(app.params["out"]))
