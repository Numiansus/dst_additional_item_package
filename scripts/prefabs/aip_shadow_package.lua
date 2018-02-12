local foldername = KnownModIndex:GetModActualName(TUNING.ZOMBIEJ_ADDTIONAL_PACKAGE)

------------------------------------ 配置 ------------------------------------
-- 魔法关闭
local additional_magic = GetModConfigData("additional_magic", foldername)
if additional_magic ~= "open" then
	return nil
end

local language = GetModConfigData("language", foldername)

local LANG_MAP = {
	english = {
		NAME = "Shadow Package",
		DESC = "Package your building",
		DESCRIBE = "It's wrapped with something!",

		PAPER_NAME = "Shadow Package Rune",
		PAPER_DESCRIBE = "Put it on a building",
	},
	chinese = {
		NAME = "暗影打包带",
		DESC = "用于打包你的建筑",
		DESCRIBE = "它蕴含着某种东西",

		PAPER_NAME = "暗影打包符文",
		PAPER_DESCRIBE = "把它放到建筑上",
	},
}

local LANG = LANG_MAP[language] or LANG_MAP.english
local LANG_ENG = LANG_MAP.english

-- 文字描述
STRINGS.NAMES.AIP_SHADOW_PACKAGE = LANG.NAME or LANG_ENG.NAME
STRINGS.RECIPE_DESC.AIP_SHADOW_PACKAGE = LANG.DESC or LANG_ENG.DESC
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_SHADOW_PACKAGE = LANG.DESCRIBE or LANG_ENG.DESCRIBE

STRINGS.NAMES.AIP_SHADOW_PAPER_PACKAGE = LANG.PAPER_NAME or LANG_ENG.PAPER_NAME
STRINGS.CHARACTERS.GENERIC.DESCRIBE.AIP_SHADOW_PAPER_PACKAGE = LANG.PAPER_DESCRIBE or LANG_ENG.PAPER_DESCRIBE

-- 配方
local aip_shadow_package = Recipe("aip_shadow_package", {Ingredient("waxpaper", 1), Ingredient("nightmarefuel", 5), Ingredient("featherpencil", 1)}, RECIPETABS.MAGIC, TECH.MAGIC_TWO)
aip_shadow_package.atlas = "images/inventoryimages/aip_shadow_package.xml"

-----------------------------------------------------------
local assets =
{
	Asset("ATLAS", "images/inventoryimages/aip_shadow_package.xml"),
	Asset("ATLAS", "images/inventoryimages/aip_shadow_paper_package.xml"),
	Asset("ANIM", "anim/aip_shadow_package.zip"),
}

local prefabs =
{
}

function fn_common(name, preFunc, postFunc)
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddNetwork()
	
	MakeInventoryPhysics(inst)
	
	inst.AnimState:SetBank("aip_shadow_package")
	inst.AnimState:SetBuild("aip_shadow_package")

	inst:AddTag("bundle")

	inst.entity:SetPristine()

	inst:AddComponent("aipc_info_client")

	if preFunc then
		preFunc(inst)
	end

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("inspectable")

	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.atlasname = aipStr("images/inventoryimages/", name, ".xml")

	inst:AddComponent("aipc_action")

	MakeHauntableLaunch(inst)

	if postFunc then
		postFunc(inst)
	end

	return inst
end

----------------------------- 包装纸 -----------------------------
local function doPackage(inst, doer, target)
	if not inst or not doer or not target then
		return
	end

	-- New package
	local item = SpawnPrefab("aip_shadow_package")
	item.packageTarget = target

	local holder = doer ~= nil and (doer.components.inventory or doer.components.container) or nil
	if holder ~= nil then
		holder:GiveItem(item)
	else
		local x, y, z = inst.Transform:GetWorldPosition()
		item.Transform:SetPosition(x, y, z)
	end

	inst:Remove()

	-- 添加物品到包裹里 (TODO:需要测试重启游戏是否出现)
	target:RemoveFromScene()
end

function fnPaper()
	return fn_common("aip_shadow_paper_package", function(inst)
		-- Pre Func
		inst.AnimState:PlayAnimation("paper", true)
	end, function(inst)
		-- Post Func
		inst.components.aipc_action.onDoTargetAction = doPackage
	end)
end

------------------------------ 包裹 ------------------------------
local function checkPackaged(inst)
	if inst.packageTarget then
		return
	end

	inst:AddComponent("perishable")
	inst.components.perishable.onperishreplacement = "aip_shadow_paper_package"
	inst:DoTaskInTime(0, function()
		inst.components.perishable:Perish()
	end)
end

function fnPackage()
	return fn_common("aip_shadow_package", function(inst)
		-- Pre Func
		inst.AnimState:PlayAnimation("idle", true)
	end, function(inst)
		-- Post Func

		-- 容器
		-- inst:AddComponent("container")
		-- inst.components.container:WidgetSetup("aip_shadow_package")
		-- inst.components.container.canbeopened = false

		inst:DoTaskInTime(0, checkPackaged)
	end)
end

return Prefab("aip_shadow_paper_package", fnPaper, assets, prefabs),
		Prefab("aip_shadow_package", fnPackage, assets, prefabs)