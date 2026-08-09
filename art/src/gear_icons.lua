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

local PAL = {
  k = Color{ r=0x1C, g=0x18, b=0x13 },   -- black[2]
  d = Color{ r=0x2A, g=0x1B, b=0x10 },   -- wood[0]
  m = Color{ r=0x5A, g=0x3D, b=0x28 },   -- wood[2]
  l = Color{ r=0x7A, g=0x53, b=0x34 },   -- wood[3]
  g = Color{ r=0x3C, g=0x42, b=0x48 },   -- stone[2]
  G = Color{ r=0x61, g=0x6A, b=0x72 },   -- stone[4]
  p = Color{ r=0xA8, g=0x94, b=0x6A },   -- parchment[1]
  P = Color{ r=0xCB, g=0xB5, b=0x83 },   -- parchment[2]
  b = Color{ r=0x6E, g=0x54, b=0x26 },   -- gold[0]  dim bronze
  B = Color{ r=0x8C, g=0x6C, b=0x30 },   -- gold[1]  muted brass (the ceiling for items)
  i = Color{ r=0x2B, g=0x2F, b=0x33 },   -- stone[1]
  I = Color{ r=0x4C, g=0x54, b=0x5A },   -- stone[3]
  r = Color{ r=0x8F, g=0x2F, b=0x2A },   -- wax[1]
  f = Color{ r=0xE8, g=0x97, b=0x3C },   -- flame[0]
  s = Color{ r=0xE0, g=0xCF, b=0x9F },   -- parchment[3]
}

-- Each glyph: 24 rows of 24 chars. '.' is transparent.
local ICONS = {}

-- 1. Ashen Lens — smoked glass, brown handle. Reads as a lens at a glance.
ICONS[1] = {
"........................",
"........................",
"........kkkkkk..........",
"......kkggggggkk........",
".....kggggggggggk.......",
"....kggGGgggggggk.......",
"....kgGGgggggggggk......",
"...kggggggggggggggk.....",
"...kggggggggggggggk.....",
"...kggggggggggggggk.....",
"....kgggggggggggggk.....",
"....kggggggggggggk......",
".....kgggggggggggk......",
"......kkgggggggkk.......",
"........kkkkkkk.........",
"..........kmmk..........",
"...........kmmk.........",
"............kmmk........",
".............kmmk.......",
"..............kmmk......",
"...............kmk......",
"................k.......",
"........................",
"........................",
}

-- 2. Chirurgeon's Glass — reticled: a cross in the lens says "measured, not admired".
ICONS[2] = {
"........................",
"........................",
"........kkkkkk..........",
"......kkGGGGGGkk........",
".....kGGGGiGGGGGk.......",
"....kGGGGGiGGGGGk.......",
"....kGGGGGiGGGGGGk......",
"...kGGGGGGiGGGGGGGk.....",
"...kiiiiiiiiiiiiiik.....",
"...kGGGGGGiGGGGGGGk.....",
"....kGGGGGiGGGGGGk......",
"....kGGGGGiGGGGGk.......",
".....kGGGGiGGGGk........",
"......kkGGGGGkk.........",
"........kkkkk...........",
"..........kmmk..........",
"...........kmmk.........",
"............kmmk........",
".............kmmk.......",
"..............kmmk......",
"...............kmk......",
"................k.......",
"........................",
"........................",
}

-- 3. Witness Prism — a struck prism on a small stand. Triangular, unmistakable.
ICONS[3] = {
"........................",
"........................",
"..........kk............",
".........kGGk...........",
".........kGGGk..........",
"........kGGGGk..........",
"........kGgGGGk.........",
".......kGGgGGGk.........",
".......kGGgGGGGk........",
"......kGGGgGGGGk........",
"......kGGGgGGGGGk.......",
".....kGGGGgGGGGGk.......",
".....kGGGGgGGGGGGk......",
"....kGGGGGgGGGGGGk......",
"....kkkkkkkkkkkkkk......",
".....kiiiiiiiiiik.......",
"......kmmmmmmmmk........",
".......kmmmmmmk.........",
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
".........kmmk...........",
".........kmmk...........",
"........kkmmkk..........",
".......kmllllmk.........",
"......kmllllllmk........",
"......kmllllllmk........",
".......kmllllmk.........",
"........kkkkkk..........",
".......k..k..k..........",
"......ks.ks.ks..........",
"......ks.ks.ks..........",
".....ks..ks..ks.........",
".....ks..ks..ks.........",
"....ks...ks...ks........",
"....kss..kss..kss.......",
"...kss...kss...kss......",
"...ks.....ks....ks......",
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
"..................kkbBk.",
"................kkbBBBk.",
"..............kkbBBBBBk.",
"...........kkkbBBBbbbBk.",
".....kkkkkkbBBbbk...kBk.",
"...kkbbbbbBBbkk.....kBk.",
"..kbbkkkkbBbk.......kBk.",
"..kbk...kbBk........kBk.",
"..kbk...kbBbk.......kBk.",
"..kbbkkkkbBBbkk.....kBk.",
"...kkbbbbbBBbbBBk...kBk.",
".....kkkkkkbBBBBBBBBBBk.",
"..............kkbBBBBBk.",
"................kkbBBk..",
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
"..........ks............",
"..........ks............",
"..........ks............",
"..........ks............",
"..........ks............",
"..........ks............",
".........kkkk...........",
"........kiIIik..........",
".......kiIIIIik.........",
"......kiIIIIIIik........",
"......kiIIIIIIik........",
"......kiIIIIIIik........",
"......kiIIIIIIik........",
".......kiIIIIik.........",
".......kiIIIIik.........",
"........kiIIik..........",
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
"......kbBBBBBBbk........",
"......kbBBrrBBbk........",
".....kbBBrrrrBBbk.......",
".....kbBBrfrrBBbk.......",
"....kbBBBrrrrBBBbk......",
"....kbBBBBrrBBBBbk......",
"....kbBBBBBBBBBBbk......",
".....kbBBBBBBBBbk.......",
".....kkbBBBBBBbkk.......",
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
"........kmmk............",
"........kmmk............",
"........kkkk............",
".......kkGGkk...........",
".......kGGGGk...........",
"......kGGGGGGk..........",
".....kGGGGGGGGk.........",
".....kGGGGGGGGk.........",
".....kGGIIIIGGk.........",
".....kGIIIIIIGk.........",
".....kGIIIIIIGk.........",
".....kGIIIIIIGk.........",
".....kGIIIIIIGk.........",
".....kGGIIIIGGk.........",
"......kGGGGGGk..........",
"......kkGGGGkk..........",
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
"..........ss............",
".........ssss...........",
"........ssssss..........",
".......ssssssss.........",
"......sssssssssss.......",
".....kssssssssssk.......",
"....kmssssssssssmk......",
"...kmmmmmmmmmmmmmmk.....",
"...kmmmmmmmmmmmmmmk.....",
"....kmmmmmmmmmmmmk......",
".....kmmmmmmmmmmk.......",
"......kmmmmmmmmk........",
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
"......kiIIIIIIik........",
"......kiIffffIik........",
"......kiIffffIik........",
"......kiIffffIik........",
"......kiIffffIik........",
"......kiIffffIik........",
"......kiIffffIik........",
"......kiIIIIIIik........",
"......kiiiiiiiik........",
".....kiiiiiiiiiik.......",
".....kiIIIIIIIIik.......",
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

for n = 1, N do
  local glyph = ICONS[n]
  local ox = (n - 1) * W
  for y = 1, math.min(#glyph, H) do
    local row = glyph[y]
    for x = 1, math.min(#row, W) do
      local ch = row:sub(x, x)
      if ch ~= "." then
        local c = PAL[ch]
        if c ~= nil then
          img:drawPixel(ox + x - 1, y - 1, c)
        end
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
