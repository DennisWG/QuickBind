--[[
	Author: Dennis Werner Garske (DWG)
	License: MIT License
]]

-- Setup to wrap our stuff in a table so we don't pollute the global environment
local _G = _G or getfenv(0);
local QuickBind = _G.QuickBind or {};
_G.QuickBind = QuickBind;

-- A list of settings!
QuickBind.Settings = {
    -- Set to 'true' in order to enable debug output
    Debug = true,
};

-- Debug output
-- msg: The message to print to chat
function QuickBind.Print(msg)
    if not QuickBind.Settings.Debug then
        return;
    end
    
    if not DEFAULT_CHAT_FRAME:IsVisible() then
        FCF_SelectDockFrame(DEFAULT_CHAT_FRAME);
    end
    
    local out = "|cffc8c864QuickBind:|r "..tostring(msg);
    DEFAULT_CHAT_FRAME:AddMessage(out);
end

-- Splits the given string into a list of sub-strings
-- str: The string to split
-- seperatorPattern: The seperator between sub-string. May contain patterns
-- returns: A list of sub-strings
function QuickBind.SplitString(str, seperatorPattern)
    local tbl = {};
    local pattern = "(.-)" .. seperatorPattern;
    local lastEnd = 1;
    local s, e, cap = string.find(str, pattern, 1);
   
    while s do
        if s ~= 1 or cap ~= "" then
            table.insert(tbl,cap);
        end
        lastEnd = e + 1;
        s, e, cap = string.find(str, pattern, lastEnd);
    end
    
    if lastEnd <= string.len(str) then
        cap = string.sub(str, lastEnd);
        table.insert(tbl, cap);
    end
    
    return tbl
end

-- Searches for the given string in the given table
-- str: The string to search for
-- tbl: The table to search in
-- returns: True when the table contains the given string
function QuickBind.FindInTable(str, tbl)
    for k,v in pairs(tbl) do
        if string.find(str, v) then
            return true;
        end
    end
    
    return false;
end

-- A set of button name to BindingID aliases
QuickBind.Aliases = {
    ["BonusActionButton"] = "ACTIONBUTTON",
    ["MultiBarBottomLeftButton"] = "MULTIACTIONBAR1BUTTON",
    ["MultiBarBottomRightButton"] = "MULTIACTIONBAR2BUTTON",
    ["MultiBarRightButton"] = "MULTIACTIONBAR3BUTTON",
    ["MultiBarLeftButton"] = "MULTIACTIONBAR4BUTTON",
    ["ShapeshiftButton"] = "SHAPESHIFTBUTTON",
    ["PetActionButton"] = "BONUSACTIONBUTTON",
};

-- A set of BindingID to button name aliases
QuickBind.Aliases2 = {
    ["ACTIONBUTTON"] = "BonusActionButton",
    ["MULTIACTIONBAR1BUTTON"] = "MultiBarBottomLeftButton",
    ["MULTIACTIONBAR2BUTTON"] = "MultiBarBottomRightButton",
    ["MULTIACTIONBAR3BUTTON"] = "MultiBarRightButton",
    ["MULTIACTIONBAR4BUTTON"] = "MultiBarLeftButton",
    ["SHAPESHIFTBUTTON"] = "ShapeshiftButton",
    ["BONUSACTIONBUTTON"] = "PetActionButton",
};

-- Sets up the event handling
QuickBind.Frame = CreateFrame("FRAME");

-- Resets all registered events on the last button the player has hovered over
function QuickBind.ResetLastButtonEvents()
    if not QuickBind.LastButton then
        return;
    end
    
    QuickBind.LastButton:SetScript("OnKeyDown", nil);
    QuickBind.LastButton:EnableKeyboard(nil);
    QuickBind.LastButton = nil;
end

-- Gets the name and number of the current button
-- returns: The button's name and the button's number
function QuickBind.GetButtonNameAndNumber()
    local buttonName = QuickBind.SplitString(QuickBind.LastButton:GetName(), "%d+")[1];
    local buttonNumber = QuickBind.SplitString(QuickBind.LastButton:GetName(), "%a+")[1];
    
    return buttonName, buttonNumber;
end

-- Resets the binding for the currently selected button
function QuickBind.ResetBindingForButton()
    local buttonName, buttonNumber = QuickBind.GetButtonNameAndNumber();
    
    if not buttonName then
        QuickBind.Print("Couldn't get name from "..QuickBind.LastButton:GetName().."!");
        return;
    end

    local bindingName = QuickBind.Aliases[buttonName];

    if not bindingName then
        QuickBind.Print("Couldn't find BindingID for button "..buttonName.."!");
        return;
    end

    local bindings = {GetBindingKey(bindingName..buttonNumber)};
    for k,v in pairs(bindings) do
        SetBinding(v);
    end
    getglobal(QuickBind.LastButton:GetName().."HotKey"):SetText("");
end

-- Adds the given key to the currently selected button's binding
-- key: The key to add
function QuickBind.AddKeyToBinding(key)
    local buttonName, buttonNumber = QuickBind.GetButtonNameAndNumber();
    
    if not buttonName then
        QuickBind.Print("Couldn't get name from "..QuickBind.LastButton:GetName().."!");
        return;
    end

    local bindingName = QuickBind.Aliases[buttonName];

    if not bindingName then
        QuickBind.Print("Couldn't find BindingID for button "..buttonName.."!");
        return;
    end
    
    local binding = bindingName..buttonNumber;
    
    if (IsShiftKeyDown()) then
        key = "SHIFT-"..key;
    end
    if (IsControlKeyDown()) then
        key = "CTRL-"..key;
    end
    if (IsAltKeyDown()) then
        key = "ALT-"..key;
    end
    
    local action = GetBindingAction(key);
    local len = string.len(action);
    
    if string.sub(action, len - 1, len - 1) == "N" then
        buttonName = string.sub(action, 0, len - 1);
        buttonNumber = string.sub(action, len);
    else
        buttonName = string.sub(action, 0, len - 2);
        buttonNumber = string.sub(action, len - 1);
    end
    buttonName = QuickBind.Aliases2[buttonName];
    
    local bindings = {GetBindingKey(binding)};
    for k,v in pairs(bindings) do
        SetBinding(v);
    end
    
    if buttonName then
        getglobal(buttonName..buttonNumber.."HotKey"):SetText("");
    end
    
    SetBinding(key, binding);
end

-- Sets the last button the player has hovered his mouse over and registers its events
-- button: The button the player currently has its mouse over
function QuickBind.SetLastKey(button)
    if QuickBind.LastButton and QuickBind.LastButton:GetScript("OnKeyDown") then
        QuickBind.ResetLastButtonEvents();
    end
    
    QuickBind.LastButton = button;
    QuickBind.LastButton:EnableKeyboard(true);
    QuickBind.LastButton:SetScript("OnKeyDown", function()
        local key = arg1;
        if key == "ESCAPE" then
            QuickBind.ResetBindingForButton();
        elseif key == "ALT" or key == "SHIFT" or key == "CTRL" then
        else
            QuickBind.AddKeyToBinding(key);
        end
    end);
end

-- Handles "OnUpdate" event
function QuickBind.Frame:OnUpdate()
    local frame = GetMouseFocus();
    
    local names = { "MultiBar", "BonusActionButton", "ShapeshiftButton", "PetActionButton" };
    
    if frame and frame.GetName then
        if QuickBind.FindInTable(frame:GetName(), names) then
            if frame ~= QuickBind.LastButton then
                QuickBind.ResetLastButtonEvents();
                QuickBind.SetLastKey(frame);
            end
        else
            QuickBind.ResetLastButtonEvents();
        end
    end
end

SLASH_QUICKBIND1 = "/quickbind";
SLASH_QUICKBIND2 = "/qb";

SlashCmdList["QUICKBIND"] = function(cmd)
    local enabled;
    if QuickBind.Frame:GetScript("OnUpdate") then
        QuickBind.Frame:SetScript("OnUpdate", nil);
        enabled = "disabled";
    else
        QuickBind.Frame:SetScript("OnUpdate", function()
            this:OnUpdate();
        end);
        enabled = "enabled";
    end
    
    QuickBind.Print("Binding mode "..enabled);
end