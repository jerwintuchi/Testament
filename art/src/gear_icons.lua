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
"..k432k99xxdd8888k34k...",
"..k32k9xddd8888887k23k..",
".k32kddd88888888877k23k.",
".k22kdd888888888887k22k.",
".k22kd8888888888877k12k.",
".k12k88888888888777k12k.",
".k12k88888888887776k12k.",
".k11k888888888777766k1k.",
"..k1k8888888777766k11k..",
"..kk1k87766677887kk1k...",
"...k11kk788887kkk11k....",
"....k111kkkkkk1112k.....",
".....kk1112221111k......",
"........kk3443kk........",
".........kwewqk.........",
".........kwewqk.........",
".........kwewqk.........",
".........kkkkkk.........",
}

-- 2. Chirurgeon's Glass — reticled: an iron crosshair set in the glass.
ICONS[2] = {
"........................",
"..........kkkkk.........",
".......kkk44555kkk......",
".....kk4443332244kk.....",
"....k43322kkkkk2234k....",
"...k432kkddaa8kk234k....",
"..k432kddd8aa8887k34k...",
"..k32kddd88aa88877k23k..",
".k32kddd888aa888877k23k.",
".k22kdd8888aa888877k22k.",
".k22kaaaaaaaaaaaaaak12k.",
".k12k888888aa888777k12k.",
".k12k888888aa887776k12k.",
".k11k888888aa8777766k1k.",
"..k1k888888aa77766k11k..",
"..kk1k87777aa7887kk1k...",
"...k11kk788aa7kkk11k....",
"....k111kkkkkk1112k.....",
".....kk1112221111k......",
"........kk3443kk........",
".........kwewqk.........",
".........kwewqk.........",
".........kwewqk.........",
".........kkkkkk.........",
}

-- 3. Witness Prism — struck glass on a brass tripod with iron feet.
ICONS[3] = {
"........................",
"...........c............",
"..........kck...........",
"..........kck...........",
".........kxc8k..........",
".........kxc8k..........",
"........kdxc87k.........",
"........kdxc87k.........",
".......kddxc877k........",
".......kddxc877k........",
"......k8ddxc8776k.......",
"......k8ddxc8776k.......",
".....k88ddxc87766k......",
".....k88ddxc87777k......",
"....k888ddxc877677k.....",
"....k888ddxc877677k.....",
"...k8888ddxc8776677k....",
"...ddddddddddddddddd....",
"...kkkkkkkkkkkkkkkkk....",
".....3333......3333.....",
".....aaaa......aaaa.....",
".....aaaa......aaaa.....",
".....kkkk......kkkk.....",
"........................",
}

-- 4. Tracker's Fetish — bone talons on a wound leather knot, brass ring.
ICONS[4] = {
"........................",
"........kkkkkkk.........",
".......k4555554k........",
"......k43kkkkk34k.......",
"......k4k.....k3k.......",
"......k3k.....k2k.......",
"......k32k...k21k.......",
".......k32k.k21k........",
"........kk22kk..........",
".......kewwwwqk.........",
".......kqeewwqk.........",
".......kweeewqk.........",
".......kqwwwwqk.........",
"........kkkkkk..........",
"......kck.kck.kck.......",
"......kxk.kxk.kxk.......",
".......kxk.kxk.kxk......",
".......kzk.kzk.kzk......",
"........kzk.kzk.kzk.....",
"........k...k...k.......",
"........................",
"........................",
"........................",
"........................",
}

-- 5. Cantor's Ear — a brass horn, iron mouthpiece, leather grip.
--    The old sheet drew a filled chevron that read as a UI arrow; a horn needs a
--    hollow bell, a tapering throat and a visible mouthpiece to read as an object.
ICONS[5] = {
"........................",
"......kkkkkkkk..........",
".....k577777776k........",
".....k477777766k........",
"......k47777663k........",
"......k4477663k.........",
".......k447632k.........",
".......k44432k..........",
"........k4332k..........",
"........k332k...........",
".........k332k..........",
".........k322k..........",
"..........k322k.........",
"..........k221k.........",
"...........k221k........",
"...........k211k........",
"............k211k.......",
"............kaaak.......",
".............kaak.......",
".............kask.......",
".............kaak.......",
"..............kk........",
"........................",
"........................",
}

-- 6. Augur's Bead — a lead bob with a brass cap on a bone cord.
ICONS[6] = {
".........z..............",
".........z..............",
".........z..............",
".........z..............",
"........kzk.............",
".......k454k............",
".......k343k............",
"......k33223k...........",
"......kkkkkk............",
"......kd8877k...........",
".....kd888777k..........",
".....kd8888776k.........",
"....kd88888776k.........",
"....kd888887766k........",
"....kd888877766k........",
"....kd88877766k.........",
".....kd8877666k.........",
".....kd877666k..........",
"......kd8766k...........",
".......kd76k............",
"........kdk.............",
".........k..............",
"........................",
"........................",
}

-- 7. Censer of Embers — a pierced brass censer on iron chains, coals within.
ICONS[7] = {
".....ds.....ds..........",
".....sd.....sd..........",
"......ds...ds...........",
"......sd...sd...........",
".......ds.ds............",
"......kkkkkkk...........",
".....k4333334k..........",
"....k433aaa334k.........",
"....k43avVvk34k.........",
"...k433vVVvk334k........",
"...k433vVvVv334k........",
"...k4333vVv3334k........",
"...k43332222334k........",
"....k332222233k.........",
".....k3222222k..........",
"......kkkkkkk...........",
"........kkk.............",
"........................",
"........................",
"........................",
"........................",
"........................",
"........................",
"........................",
}

-- 8. Phial of Hoarfrost — glass under a wood stopper, brass collar, iron wire.
ICONS[8] = {
"........................",
"........kkkk............",
"........kwek............",
"........kwek............",
".......k3443k...........",
".......kkkkk............",
"........k88k............",
"........k88k............",
".......kd887k...........",
"......kd8887k...........",
"......kd88877k..........",
".....kaaaaaaaak.........",
".....kd88888776k........",
".....kd88888776k........",
".....kaaaaaaaaak........",
".....kd88888776k........",
".....kd88887766k........",
"......kd888776k.........",
"......kkkkkkkk..........",
"........................",
"........................",
"........................",
"........................",
"........................",
}

-- 9. Consecrated Salt — a heaped bone-white salt in a brass-rimmed wood bowl.
ICONS[9] = {
"........................",
"........................",
"........................",
"........................",
"........................",
"...........k............",
".........kcxk...........",
"........kcxxzk..........",
".......kcxxxzzk.........",
"......kcxxxxzzzk........",
".....kcxxxxxzzzzk.......",
"....kcxxxxxxzzzzzk......",
"...k5444444444443k......",
"...k4333333333332k......",
"....kewwwwwwwwwqk.......",
"....kewwwwwwwwwqk.......",
".....keewwwwwwqk........",
"......kewwwwqqk.........",
".......kkkkkkk..........",
"........................",
"........................",
"........................",
"........................",
"........................",
}

-- 10. Lantern of the Creed — an iron lantern with glass panes and a brass crown.
ICONS[10] = {
".........kak............",
"........ka.ak...........",
"........ka.ak...........",
".......k43334k..........",
"......k4333334k.........",
".....kkkkkkkkkkk........",
".....kad888888dak.......",
".....kad88VV88dak.......",
".....kad8VVVV8dak.......",
".....kad8VVVV8dak.......",
".....kad88VV88dak.......",
".....kad888888dak.......",
".....kad887788dak.......",
".....kkkkkkkkkkkk.......",
"......kaaaaaaaak........",
"......kasssssak.........",
".......kkkkkkk..........",
"........................",
"........................",
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
