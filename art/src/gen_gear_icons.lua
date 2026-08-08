-- Gear icons for the Quartermaster's writ (TD-090 Phase A).
-- Aseprite owns icons (TD-057): at 24px every pixel is a design decision.
--
-- v2. v1 failed the way TD-056 predicted: a midpoint-circle OUTLINE samples a curve
-- and at r=6..8 it breaks into dots, so every ringed instrument read as dotty. Rings
-- are now DISC SUBTRACTION (solid disc, then a smaller disc in the fill colour), which
-- cannot gap. Silhouettes are also bolder — v1's fetish and salt dish had no readable
-- shape at all.
--
-- These sit ON PARCHMENT inside a writ, so they are illuminated-manuscript marginalia:
-- iron-gall ink with a muted wash, never full-colour game icons.

local W, H, N = 24, 24, 10
local spr = Sprite(W * N, H)
local img = Image(W * N, H, ColorMode.RGB)

local function C(r, g, b, a) return app.pixelColor.rgba(r, g, b, a or 255) end
local INK   = C(38, 28, 16)
local INKD  = C(78, 62, 39)
local BRASS = C(166, 128, 58)
local BRSL  = C(206, 170, 98)
local BONE  = C(219, 206, 172)
local BONED = C(176, 162, 128)
local OXB   = C(138, 56, 48)
local VERD  = C(74, 118, 94)
local VERDL = C(108, 156, 128)
local FROST = C(122, 160, 174)
local FROSTL= C(196, 224, 234)
local EMBER = C(198, 100, 40)
local EMBRL = C(246, 176, 84)
local GLASS = C(158, 174, 172, 165)
local LIT   = C(244, 222, 158)

local ox = 0
local function px(x, y, c)
  x = x + ox
  if x >= 0 and x < W * N and y >= 0 and y < H then img:drawPixel(x, y, c) end
end
local function hl(x1, x2, y, c) for x = x1, x2 do px(x, y, c) end end
local function vl(x, y1, y2, c) for y = y1, y2 do px(x, y, c) end end
local function frect(x1, y1, x2, y2, c) for y = y1, y2 do hl(x1, x2, y, c) end end
-- Filled disc. The +r fudge keeps small radii round instead of diamond-ish.
local function disc(cx, cy, r, c)
  for y = -r, r do for x = -r, r do
    if x * x + y * y <= r * r + r then px(cx + x, cy + y, c) end
  end end
end
-- A ring that CANNOT gap: solid disc, then a smaller disc in the fill colour.
local function ring(cx, cy, r, edge, fill, thick)
  disc(cx, cy, r, edge)
  if fill then disc(cx, cy, r - (thick or 2), fill) end
end
local function diag(x, y, n, dx, dy, c) for i = 0, n - 1 do px(x + i * dx, y + i * dy, c) end end

-- ── 1. Ashen Lens — RESIDUE. A heavy brass reading glass; ash caught in the bowl.
ox = 0
ring(11, 10, 8, INK, BRASS, 2)
disc(11, 10, 6, GLASS)
hl(6, 15, 13, C(118, 108, 92, 150))        -- settled ash
hl(8, 13, 14, C(118, 108, 92, 110))
px(8, 6, C(255, 255, 255, 120)); px(9, 5, C(255, 255, 255, 90))
frect(15, 16, 17, 18, INK)                  -- collar
diag(17, 18, 5, 1, 1, INK); diag(18, 18, 4, 1, 1, INKD)   -- thick handle

-- ── 2. Chirurgeon's Glass — STRESS_MARK. A surgeon's glass with a reticle: it
ox = 24
--     does not just magnify, it MEASURES.
ring(9, 8, 6, INK, BONE, 2)
disc(9, 8, 4, GLASS)
hl(6, 12, 8, C(38, 28, 16, 150))            -- reticle
vl(9, 5, 11, C(38, 28, 16, 150))
frect(12, 12, 14, 14, INK)                  -- collar
frect(14, 14, 17, 22, INK)                  -- broad handle, angled away
frect(15, 15, 16, 21, INKD)

-- ── 3. Witness Prism — REACTION. Solid glass wedge, one lit edge, a fan out.
ox = 48
for i = 0, 10 do hl(11 - i, 11 + i, 6 + i, GLASS) end
for i = 0, 10 do px(11 - i, 6 + i, INK) end          -- left edge dark
for i = 0, 10 do px(11 + i, 6 + i, LIT) end          -- right edge catches light
hl(1, 21, 17, INK)                                    -- base
hl(2, 20, 16, C(210, 220, 218, 120))
hl(0, 5, 11, BONE); hl(0, 4, 12, C(219, 206, 172, 120))  -- beam in
px(17, 9, OXB); px(18, 8, OXB)                        -- fan out, three bands
px(18, 11, EMBER); px(19, 10, EMBER)
px(18, 13, VERD); px(19, 13, VERD)

-- ── 4. Tracker's Fetish — SPOOR. A bound charm: cord, wrapped bundle, two
ox = 72
--     hanging bones. v1's twigs-and-feather read as a paintbrush.
-- v4. v3's talons were BONE on parchment — 219,206,172 against 214,196,160 is
-- almost no contrast, so they vanished. On paper a pale object needs an INK
-- silhouette with the light colour inside it, never the light colour alone.
vl(11, 0, 4, INK)                            -- cord
frect(8, 4, 14, 8, INK)                      -- binding knot
frect(9, 5, 13, 7, OXB)
px(10, 6, C(184, 96, 82))
-- three talons: 3px ink body, 1px bone core, hooking inward at the tip
local function talon(x0, y0, n, drift)
  local xt = x0
  for i = 0, n - 1 do
    local x = x0 + math.floor(i * drift / n + 0.5)
    frect(x - 1, y0 + i, x + 1, y0 + i, INK)
    px(x, y0 + i, i < n - 2 and BONE or BONED)
    xt = x
  end
  px(xt + (drift >= 0 and 1 or -1), y0 + n, INK)   -- the hook
end
talon(5, 9, 8, 2)
talon(11, 9, 10, 0)
talon(17, 9, 8, -2)
px(5, 10, C(244, 238, 220)); px(11, 10, C(244, 238, 220)); px(17, 10, C(244, 238, 220))

-- ── 5. Cantor's Ear — LITURGY. A brass hearing-horn: wide bell, tube, earpiece.
ox = 96
for i = 0, 6 do vl(2 + i, 8 - i, 15 + i, BRASS) end   -- bell flares left
for i = 0, 6 do px(2 + i, 8 - i, INK); px(2 + i, 15 + i, INK) end
vl(2, 8, 15, INK)
for i = 0, 4 do vl(3 + i, 9 - i, 10 - i, BRSL) end    -- inner light
frect(9, 10, 17, 13, BRASS)                            -- tube
hl(9, 17, 9, INK); hl(9, 17, 14, INK)
hl(10, 16, 11, BRSL)
ring(19, 12, 4, INK, BRASS, 2)                         -- earpiece
disc(19, 12, 2, INKD)

-- ── 6. Augur's Bead — OMEN. A bead on a cord, and a smaller one below it.
ox = 120
vl(11, 1, 8, INK); px(10, 3, INKD); px(12, 6, INKD)
ring(11, 13, 5, INK, VERD, 1)
disc(11, 13, 3, VERDL)
px(9, 11, C(214, 240, 226)); px(10, 10, C(214, 240, 226, 160))
ring(11, 20, 2, INK, VERD, 1)                          -- lesser bead
hl(9, 13, 23, C(38, 28, 16, 70))                       -- it hangs, so it casts

-- ── 7. Censer of Embers — FLAME. Thurible: ring, three chains, pierced lid, coals.
ox = 144
ring(11, 2, 2, INK, nil)                               -- suspension ring
diag(11, 4, 5, -1, 1, INKD); vl(11, 4, 8, INKD); diag(11, 4, 5, 1, 1, INKD)
for i = 0, 5 do hl(6 + i, 16 - i, 8 + i, BRASS) end    -- domed lid
for i = 0, 5 do px(6 + i, 8 + i, INK); px(16 - i, 8 + i, INK) end
px(9, 10, INK); px(13, 10, INK); px(11, 9, INK)        -- pierced holes
hl(5, 17, 14, INK)                                      -- rim
ring(11, 17, 6, INK, BRASS, 2)                          -- bowl
frect(8, 16, 14, 19, EMBER)
px(9, 17, EMBRL); px(12, 18, EMBRL); px(11, 16, EMBRL)

-- ── 8. Phial of Hoarfrost — COLD. (v1 read well; kept, with a wrapped neck.)
ox = 168
frect(8, 7, 15, 20, GLASS)
frect(8, 7, 15, 20, GLASS)
vl(7, 8, 20, INK); vl(16, 8, 20, INK); hl(8, 15, 21, INK); hl(8, 15, 6, INK)
frect(9, 13, 14, 20, FROST)
hl(9, 14, 13, FROSTL)
frect(10, 2, 13, 5, INK); frect(10, 3, 13, 4, C(122, 98, 60))
frect(9, 6, 14, 6, OXB)                                 -- wax over the cork
px(9, 9, C(230, 245, 250, 210)); px(14, 11, C(230, 245, 250, 170))
px(9, 17, FROSTL)

-- ── 9. Consecrated Salt — SALT. An open dish with the salt heaped. v1 drew a
ox = 192
--     line and a smear; this is a real vessel.
for i = 0, 4 do hl(4 + i, 19 - i, 17 + i, INK) end      -- tapered bowl walls
for i = 0, 3 do hl(5 + i, 18 - i, 17 + i, INKD) end
hl(3, 20, 16, INK)                                       -- rim
hl(4, 19, 15, BONED)
for i = 0, 5 do hl(6 + i, 17 - i, 15 - i, BONE) end          -- heaped mound, wide at the rim
hl(9, 14, 12, C(246, 242, 230))                          -- lit crest
px(11, 9, BONE); px(10, 10, BONE); px(12, 10, BONE)
px(2, 19, BONE); px(21, 19, BONE); px(1, 20, C(219, 206, 172, 150))  -- spilled

-- ── 10. Lantern of the Creed — LIGHT. (v1 read well; kept, with a brighter core.)
ox = 216
vl(11, 0, 2, INK); px(10, 1, INK); px(12, 1, INK)
frect(6, 4, 17, 6, INK); frect(7, 5, 16, 5, C(122, 98, 60))
vl(6, 6, 19, INK); vl(17, 6, 19, INK); hl(6, 17, 19, INK)
frect(7, 7, 16, 18, LIT)
vl(11, 7, 18, C(150, 120, 68))
frect(9, 11, 13, 17, C(255, 240, 196))
frect(10, 12, 12, 16, C(255, 252, 232))
frect(5, 20, 18, 21, INK); hl(6, 17, 20, INKD)

spr.cels[1].image = img
spr:saveAs(app.params["out"])
print("wrote " .. app.params["out"])
