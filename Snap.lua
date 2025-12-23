local MAP_GUID = "85edc3"
local map

function onLoad()
  map = getObjectFromGUID(MAP_GUID)
  if not map then
    printToAll("ERROR: map object not found. MAP_GUID=" .. MAP_GUID, {1,0,0})
  end
end

local function hasTag(list, tag)
  if not list then return false end
  for _, t in ipairs(list) do
    if t == tag then return true end
  end
  return false
end

-- MUST match your object tags exactly (case-sensitive)
local function categoryOf(obj)
  if not obj or not obj.hasTag then return nil end
  if obj.hasTag("Capital") then return "Capital" end
  if obj.hasTag("mega")    then return "mega" end
  if obj.hasTag("factory") then return "factory" end
  if obj.hasTag("unit")    then return "unit" end
  return nil
end

-- Bounds check in this trigger's local space (works when the trigger is rotated)
local function pointInOBBLocal(p, b)
  local cx, cy, cz = b.center.x, b.center.y, b.center.z
  local hx, hy, hz = b.size.x * 0.5, b.size.y * 0.5, b.size.z * 0.5

  return (p.x >= cx - hx and p.x <= cx + hx)
     and (p.y >= cy - hy and p.y <= cy + hy)
     and (p.z >= cz - hz and p.z <= cz + hz)
end

local function closestSnapPointWithTagInsideThisBox(snapPoints, pos, wantedTag)
  local b = self.getBoundsNormalized()
  local posLocal = self.positionToLocal(pos)
  local best, bestDist = nil, math.huge

  for _, sp in ipairs(snapPoints) do
    if hasTag(sp.tags, wantedTag) then
      -- Convert snap point position to this trigger's local space so rotation
      -- does not affect the bounds check. Snap point positions are local to the
      -- map object, so they need to be converted to world space first.
      local spWorld = map.positionToWorld(Vector(sp.position))
      local spp = self.positionToLocal(spWorld)
      if pointInOBBLocal(spp, b) then
        local d = Vector.distance(spp, posLocal)
        if d < bestDist then
          bestDist = d
          best = sp
        end
      end
    end
  end

  return best
end

local function snapPieceToTaggedPoint(obj)
  if not map then return end

  local cat = categoryOf(obj)
  if not cat then
    printToAll("No matching tag on object (need one of: Capital/mega/factory/unit).", {1,0.6,0})
    return
  end

  local snaps = map.getSnapPoints()
  if not snaps or #snaps == 0 then
    printToAll("No snap points found on map object " .. MAP_GUID, {1,0,0})
    return
  end

  -- Only consider snap points that are inside THIS script trigger's bounds
  local sp = closestSnapPointWithTagInsideThisBox(snaps, obj.getPosition(), cat)
  if not sp then
    printToAll("No '" .. cat .. "' snap point inside this box.", {1,0.6,0})
    return
  end

  local p = Vector(sp.position)
  local h = obj.getBounds().size.y
  p.y = p.y + (h * 0.5)

  obj.setPositionSmooth(p, false, true)
end

function onObjectDrop(player_color, obj)
  -- Only affect objects dropped near this trigger (adjust radius if needed)
  local d = Vector.distance(self.getPosition(), obj.getPosition())
  if d > 6 then return end
  snapPieceToTaggedPoint(obj)
end
