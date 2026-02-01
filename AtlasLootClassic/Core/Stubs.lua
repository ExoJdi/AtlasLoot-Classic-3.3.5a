local _G = _G
local AtlasLoot = _G.AtlasLoot
if not AtlasLoot then return end

-- Minimal stubs for modules that are not enabled yet on 3.3.5a

if not AtlasLoot.ItemInfo then AtlasLoot.ItemInfo = {} end
if not AtlasLoot.ItemInfo.GetDescription then
  AtlasLoot.ItemInfo.GetDescription = function()
		return ""
  end
end

if not AtlasLoot.Data then AtlasLoot.Data = {} end

-- Recipe
if not AtlasLoot.Data.Recipe then AtlasLoot.Data.Recipe = {} end
local Recipe = AtlasLoot.Data.Recipe
if not Recipe.IsRecipe then
  Recipe.IsRecipe = function()
    return false
  end
end
if not Recipe.GetRecipeDataForExtraFrame then
  Recipe.GetRecipeDataForExtraFrame = function()
    return nil
  end
end
if not Recipe.GetRecipeDescriptionWithRank then
  Recipe.GetRecipeDescriptionWithRank = function()
    return nil
  end
end

-- Profession
if not AtlasLoot.Data.Profession then AtlasLoot.Data.Profession = {} end
local Profession = AtlasLoot.Data.Profession
if not Profession.GetColorSkillRankItem then
  Profession.GetColorSkillRankItem = function()
    return nil
  end
end

-- Companion
if not AtlasLoot.Data.Companion then AtlasLoot.Data.Companion = {} end
local Companion = AtlasLoot.Data.Companion
if not Companion.IsCompanion then
  Companion.IsCompanion = function()
    return false
  end
end
if not Companion.GetTypeName then
  Companion.GetTypeName = function()
    return ""
  end
end
if not Companion.GetCollectedString then
  Companion.GetCollectedString = function()
    return ""
  end
end
if not Companion.GetDescription then
  Companion.GetDescription = function()
    return nil
  end
end
if not Companion.GetCreatureID then
  Companion.GetCreatureID = function()
    return nil
  end
end
