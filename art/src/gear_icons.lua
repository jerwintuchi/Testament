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
-- Widened for reference density (TD-110 R382): each material's triple now spans a
-- wider range, so the form pass has real contrast to work with instead of three
-- neighbouring greys.
local MAT = {
  w = { "#916339", "#5A3D28", "#2A1B10" },   -- wood / horn
  g = { "#8F7A63", "#4C545A", "#22242A" },   -- glass, pale at the lit face
  i = { "#616A72", "#3C4248", "#22242A" },   -- iron
  b = { "#8C6C30", "#6E5426", "#3A2617" },   -- brass, capped below the bright gold
  n = { "#F1E4BE", "#CBB583", "#8A7A54" },   -- bone / salt / parchment
  r = { "#C65A4E", "#8F2F2A", "#5E1D1A" },   -- wax / ember
  f = { "#F9DCA6", "#F0B25F", "#E8973C" },   -- flame, used sparingly
}

-- A SPECULAR pass on top of the form pass: the ONE pixel where a curved material
-- catches the room. Only glass, brass and iron take one — wood, bone and wax are
-- matte, and giving everything a highlight is what makes a sheet look like plastic.
--
-- Brass's bright stop returns here and ONLY here. P168 bans gold as a FIELD on an
-- ordinary instrument; a single lit pixel is not a field, it is how metal reads.
local SPEC = { g = "#F1E4BE", b = "#B08A3E", i = "#8F7A63" }
local OUTLINE = "#1C1813"

local function hexc(h)
  return Color{ r = tonumber(h:sub(2,3),16), g = tonumber(h:sub(4,5),16), b = tonumber(h:sub(6,7),16) }
end


-- ── HAND-PLACED TONES (TD-111) ─────────────────────────────────────────────
-- The material letters above hand shading to an ALGORITHM: "this pixel is brass,
-- work out its shade from its neighbours". That can only ever produce a bevel. Item
-- sprites in the games this is measured against look the way they do because an artist
-- places every tone on purpose — the highlight, the terminator, the core shadow, and
-- the reflected light that keeps a shadow side from going dead.
--
-- These letters are absolute colours. A glyph using them skips the neighbour pass
-- entirely, so the drawing is exactly what is written.
--
--   brass  1 dark  2 body  3 lit   4 bright  5 specular
--   glass  6 dark  7 body  8 lit   9 specular
--   wood   q dark  w body  e lit
--   iron   a dark  s body  d lit
--   bone   z dark  x body  c lit
--   ember  v dark  V hot
local TONE = {
  ["1"]="#3A2617", ["2"]="#6E5426", ["3"]="#8C6C30", ["4"]="#B08A3E", ["5"]="#D6AE5C",
  ["6"]="#22242A", ["7"]="#2B2F33", ["8"]="#4C545A", ["9"]="#8F7A63",
  q="#2A1B10", w="#5A3D28", e="#7A5334",
  a="#22242A", s="#3C4248", d="#616A72",
  z="#8A7A54", x="#CBB583", c="#F1E4BE",
  v="#8F2F2A", V="#E8973C",
}

-- Each glyph: 24 rows of 24 chars. '.' is transparent.
local ICONS = {}

-- 1. Ashen Lens — HAND-SHADED (TD-111): brass ring with a lit crown, a
--    core shadow at the foot and reflected light under it; smoked glass with a
--    specular and a dark rim; a wood handle. Every tone placed, none inferred.
ICONS[1] = {
"........................",
"..........kkkkk.........",
".......kkk44555kkk......",
".....kk4443332244kk.....",
"....k43322kkkkk2234k....",
"...k432kk99988kk234k....",
"..k432k9988877776k34k...",
"..k32k988777766667k23k..",
".k32k88777666666667k23k.",
".k22k87766666666666k22k.",
".k22k77666666666666k12k.",
".k12k76666666666667k12k.",
".k12k66666666666677k12k.",
".k11k666666666667788k1k.",
"..k1k6666666667788k11k..",
"..kk1k66666677788kk1k...",
"...k11kk666778kkk11k....",
"....k111kkkkkk1112k.....",
".....kk1112221111k......",
".......kkk1qqkkk........",
"..........qwek..........",
"..........qwek..........",
"...........qek..........",
"...........kk...........",
}

-- 2. Chirurgeon's Glass — reticled: an iron crosshair set in the glass.
ICONS[2] = {
"........................",
"........bbbbbb..........",
"......bbggiggggbb.......",
".....bggggiggggggb......",
"....bggggigggggggbb.....",
"...bgggggigggggggggb....",
"...bgggggigggggggggb....",
"..bggggggigggggggggbb...",
"..biiiiiiiiiiiiiiiibb...",
"..bggggggigggggggggbb...",
"...bgggggigggggggggb....",
"...bgggggigggggggggb....",
"....bggggigggggggbb.....",
".....bgggigggggggb......",
"......bbggiggggbb.......",
"........bbbbbb..........",
".........bbb............",
".........www............",
"..........www...........",
"..........www...........",
"...........ww...........",
"...........ww...........",
"........................",
"........................",
}

-- 3. Witness Prism — struck glass on a brass tripod with iron feet.
ICONS[3] = {
"........................",
"..........gg............",
".........gggg...........",
".........gggg...........",
"........gggggg..........",
"........gggggg..........",
".......gggggggg.........",
".......gggggggg.........",
"......gggggggggg........",
"......gggggggggg........",
".....gggggggggggg.......",
".....gggggggggggg.......",
"....gggggggggggggg......",
"....gggggggggggggg......",
"...bbbbbbbbbbbbbbbb.....",
"...bbbbbbbbbbbbbbbb.....",
".....b..........b.......",
"....b............b......",
"...b..............b.....",
"..bb..............bb....",
"..ii..............ii....",
"........................",
"........................",
"........................",
}

-- 4. Tracker's Fetish — bone talons on a wound leather knot, brass ring.
ICONS[4] = {
"..........bb............",
".........b..b...........",
".........b..b...........",
".........bbbb...........",
"........wwwwww..........",
".......wwwwwwww.........",
".......wwwwwwww.........",
"......wwwwwwwwww........",
"......wwwwwwwwww........",
".......wwwwwwww.........",
".......wwwwwwww.........",
"........wwwwww..........",
".......k.k..k.k.........",
"......nn.nn.nn.nn.......",
"......nn.nn.nn.nn.......",
".....nn..nn.nn..nn......",
".....nn..nn.nn..nn......",
"....nn...nn.nn...nn.....",
"....nn...nn.nn...nn.....",
"...nn....n...n....nn....",
"...nn.............nn....",
"...n...............n....",
"........................",
"........................",
}

-- 5. Cantor's Ear — a brass horn, iron mouthpiece, leather grip.
--    The old sheet drew a filled chevron that read as a UI arrow; a horn needs a
--    hollow bell, a tapering throat and a visible mouthpiece to read as an object.
ICONS[5] = {
"........................",
"........................",
"....................bb..",
"..................bbbBb.",
"................bbbbbbb.",
"..............bbbbbbbbb.",
"............bbbbbbbbbbb.",
"..........bbbbbbbbbbbbb.",
"........bbbbbbb...bbbbb.",
"......bbbbbb.......bbbb.",
"....iiibbb..........bbb.",
"..iiiiib............bbb.",
"..iiiiib............bbb.",
"....iiibbb..........bbb.",
"......bbbbbb.......bbbb.",
"........bbbbbbb...bbbbb.",
"..........bbbbbbbbbbbbb.",
"............bbbbbbbbbbb.",
"..............bbbbbbbbb.",
"................bbbbbbb.",
"..................bbbbb.",
"....................bb..",
"........................",
"........................",
}

-- 6. Augur's Bead — a lead bob with a brass cap on a bone cord.
ICONS[6] = {
"..........nn............",
"..........nn............",
"..........nn............",
"..........nn............",
"..........nn............",
".........bbbb...........",
".........bbbb...........",
"........bbbbbb..........",
".......iiiiiiii.........",
"......iiiiiiiiii........",
"......iiiiiiiiii........",
".....iiiiiiiiiiii.......",
".....iiiiiiiiiiii.......",
"......iiiiiiiiii........",
"......iiiiiiiiii........",
".......iiiiiiii.........",
".......iiiiiiii.........",
"........iiiiii..........",
".........iiii...........",
"..........ii............",
"..........ii............",
"........................",
"........................",
"........................",
}

-- 7. Censer of Embers — a pierced brass censer on iron chains, coals within.
ICONS[7] = {
"..........ii............",
".........i..i...........",
"........i....i..........",
".......i......i.........",
"......i........i........",
".....iiiiiiiiiiii.......",
".....bbbbbbbbbbbb.......",
"....bbwwbbwwbbwwbb......",
"....bbbbbbbbbbbbbb......",
"...bbbbbbbbbbbbbbbb.....",
"...bbrrrrrrrrrrrrbb.....",
"..bbrrffrrrrffrrrrbb....",
"..bbrrrrffrrrrrrrrbb....",
"..bbrrrrrrrrffrrrrbb....",
"..bbrrrrrrrrrrrrrrbb....",
"...bbrrrrrrrrrrrrbb.....",
"...bbbbbbbbbbbbbbbb.....",
"....bbbbbbbbbbbbbb......",
".....bbbbbbbbbbbb.......",
"......bbbbbbbbbb........",
".........bbbb...........",
"..........bb............",
"........................",
"........................",
}

-- 8. Phial of Hoarfrost — glass under a wood stopper, brass collar, iron wire.
ICONS[8] = {
"........................",
".........wwww...........",
".........wwww...........",
".........wwww...........",
".........bbbb...........",
".........bbbb...........",
"........ggggggg.........",
".......gggggggggg.......",
"......gggggggggggg......",
"......gggggggggggg......",
"......ggiiiiiiiigg......",
"......gggggggggggg......",
"......gggggggggggg......",
"......ggiiiiiiiigg......",
"......gggggggggggg......",
"......gggggggggggg......",
"......gggggggggggg......",
"......bbbbbbbbbbbb......",
".......bbbbbbbbbb.......",
"........bbbbbbbb........",
"........................",
"........................",
"........................",
"........................",
}

-- 9. Consecrated Salt — a heaped bone-white salt in a brass-rimmed wood bowl.
ICONS[9] = {
"........................",
"........................",
"..........nn............",
".........nnnn...........",
"........nnnnnn..........",
".......nnnnnnnn.........",
"......nnnnnnnnnn........",
".....nnnnnnnnnnnn.......",
"....nnnnnnnnnnnnnn......",
"...nnnnnnnnnnnnnnnn.....",
"..bbbbbbbbbbbbbbbbbb....",
"..bbbbbbbbbbbbbbbbbb....",
"..wwwwwwwwwwwwwwwwww....",
"..wwwwwwwwwwwwwwwwww....",
"...wwwwwwwwwwwwwwww.....",
"...wwwwwwwwwwwwwwww.....",
"....wwwwwwwwwwwwww......",
".....wwwwwwwwwwww.......",
"......wwwwwwwwww........",
".......bbbbbbbb.........",
"........................",
"........................",
"........................",
"........................",
}

-- 10. Lantern of the Creed — an iron lantern with glass panes and a brass crown.
ICONS[10] = {
"..........bb............",
".........b..b...........",
".........bbbb...........",
"........bbbbbb..........",
".......bbbbbbbb.........",
"......iiiiiiiiii........",
"......iiiiiiiiii........",
"......iggiiiiggi........",
"......iggffffggi........",
"......iggffffggi........",
"......iggffffggi........",
"......iggffffggi........",
"......iggffffggi........",
"......iggffffggi........",
"......iggffffggi........",
"......iggiiiiggi........",
"......iiiiiiiiii........",
"......iiiiiiiiii........",
".....bbbbbbbbbbbb.......",
".....bbbbbbbbbbbb.......",
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
        if TONE[ch] ~= nil then
          col = hexc(TONE[ch])          -- hand-placed: drawn exactly as written
        elseif ch == "k" then
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
            -- The specular sits where the lit face meets the object's top-left
            -- corner: one pixel, on curved materials only.
            local u2 = at(glyph, x, y - 1)
            local l2 = at(glyph, x - 1, y)
            if SPEC[ch] ~= nil and (not solid(u2)) and (not solid(l2)) then
              col = hexc(SPEC[ch])
            else
              col = hexc(m[1])
            end
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
