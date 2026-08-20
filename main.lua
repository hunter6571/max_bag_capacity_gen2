local TARGET_CAP = 999

local function patchBag(Bag)
    if not Bag then return end
    
    -- Expand built-in pocket limits if the table exists
    if Bag.GEN2_POCKET_CAP then
        Bag.GEN2_POCKET_CAP.ITEM = TARGET_CAP
        Bag.GEN2_POCKET_CAP.BALL = TARGET_CAP
        Bag.GEN2_POCKET_CAP.KEY_ITEM = TARGET_CAP
    end

    -- Fully override Bag.add to allow up to 999 items per stack and pocket
    Bag.add = function(save, id, qty, data)
        save.inventory = save.inventory or {}
        local inv = save.inventory
        
        -- Check pocket slot limits against 999 instead of 20
        if not inv[id] and not Bag.isBadge(id) then
            local pocket = "ITEM"
            if Bag.pocketOf then
                pocket = Bag.pocketOf(id, data)
            end
            if Bag.pocketSlots and Bag.pocketSlots(save, pocket, data) >= TARGET_CAP then
                return false
            end
        end

        -- Check stack limit against 999 instead of 99
        if not Bag.isBadge(id) and (inv[id] or 0) + (qty or 1) > TARGET_CAP then
            return false
        end

        local isNew = not inv[id]
        inv[id] = (inv[id] or 0) + (qty or 1)
        
        if isNew and not Bag.isBadge(id) then
            if Bag.order then
                table.insert(Bag.order(save), id)
            else
                save.bagOrder = save.bagOrder or {}
                table.insert(save.bagOrder, id)
            end
        end
        
        return true
    end
end

-- Intercept and patch all possible path variations (lowercase and uppercase)
local paths = {
    "src.inventory.bag", 
    "src/inventory/bag", 
    "src.inventory.Bag", 
    "src/inventory/Bag"
}

for _, path in ipairs(paths) do
    local orig = package.preload[path]
    package.preload[path] = function(...)
        local bagMod = orig and orig(...) or {}
        patchBag(bagMod)
        return bagMod
    end
    
    if package.loaded[path] then
        patchBag(package.loaded[path])
    end
end

if _G.Bag then
    patchBag(_G.Bag)
end
