local config = require("modules/config/config")

local FasterLift = {
    settings = {
    },
    defaultSettings = {
        isEnabled = true,
        isDisabledDuringQuest = false,
        liftSpeed = 12.5,
        emptyLiftSpeed = 30.0
    },

    -- Quest objectives that will enable or disable the mod | true is enabled, false is disabled
    modToggleObjectiveIds = {
        ["05_leave_restaurant"] = false, --quests/meta/02_sickness/q115
        ["01_4_sit"] = true,             --quests/meta/02_sickness/q115_ripperdoc
        ["05_leave_roof"] = false,       --quests/meta/02_sickness/q115_ripperdoc
        ["06_talk_to_misty"] = true,     --quests/meta/02_sickness/q115_ripperdoc
        ["00e_take_elev"] = false,       --quests/meta/09_solo
        ["01e_to_mikoshi"] = true,       --quests/meta/09_solo
        ["15_enter_the_lobby"] = false,  --quests/main_quest/prologue/q005_heist
        ["00b_goto_landing_pad"] = true, --quests/main_quest/prologue/q005_heist
        ["01_proceed_to_roof"] = false,  --ep1/quests/main_quest/q306_devils_bargain
        ["08_proceed_to_maglev"] = true  --ep1/quests/main_quest/q306_devils_bargain
    },

    minLiftSpeed = 1.0,
    maxLiftSpeed = 20.0,
    liftSpeedStep = 0.1,
    minEmptyLiftSpeed = 2.0,
    maxEmptyLiftSpeed = 40.0,
    emptyLiftSpeedStep = 0.1,
}

function FasterLift:new()
    registerForEvent("onInit", function()
        self:InitializeSettings()
        self:ObserveLiftEvents()
        self:ObserveQuestTracking()
    end)

    return self
end

function FasterLift:InitializeSettings()
    config.tryCreateConfig("config.json", self.defaultSettings)
    self.settings = config.loadFile("config.json")

    local nativeSettings = GetMod("nativeSettings")
    if not nativeSettings then
        print("[Faster Elevators] Error: Missing Native Settings")
        return
    end

    self:SetupMenu(nativeSettings)
end

function DisableBeforeQuestOverride()
    FasterLift.settings.isDisabledDuringQuest = true
    SaveSettings()
end

function EnableAfterQuestOverride()
    FasterLift.settings.isDisabledDuringQuest = false
    SaveSettings()
end

function FasterLift:ObserveQuestTracking()
    ObserveAfter("JournalManager", "OnQuestEntryTracked",
        ---@param this JournalManager
        ---@param entry JournalEntry
        function(this, entry)
            local toggleState = self.modToggleObjectiveIds[entry.id]
            if toggleState == false then
                DisableBeforeQuestOverride()
            elseif toggleState == true then
                EnableAfterQuestOverride()
            end
        end)
end

function FasterLift:ObserveLiftEvents()
    Override("LiftControllerPS", "GetLiftSpeed",
        ---@param this LiftControllerPS
        ---@param wrappedMethod function
        ---@return Float
        function(this, wrappedMethod)
            if not self.settings.isEnabled or self.settings.isDisabledDuringQuest then
                local result = wrappedMethod()
                return result
            end

            if this:IsPlayerInsideLift() then
                return self.settings.liftSpeed;
            end
            return self.settings.emptyLiftSpeed;
        end)

    ObserveAfter("LiftControllerPS", "OnQuestEnableLiftTravelTimeOverride",
        ---@param this LiftControllerPS
        ---@param evt QuestEnableLiftTravelTimeOverride
        function(this, evt)
            DisableBeforeQuestOverride()
        end)

    ObserveAfter("LiftControllerPS", "OnQuestDisableLiftTravelTimeOverride",
        ---@param this LiftControllerPS
        ---@param evt QuestDisableLiftTravelTimeOverride
        function(this, evt)
            EnableAfterQuestOverride()
        end)
end

function SaveSettings()
    config.saveFile("config.json", FasterLift.settings)
end

function FasterLift:SetupMenu(nativeSettings)
    if not nativeSettings.pathExists("/faster_elevators") then
        nativeSettings.addTab("/faster_elevators", "Faster Elevators")
        nativeSettings.addSubcategory("/faster_elevators/general", "Faster Elevators")
        nativeSettings.addSubcategory("/faster_elevators/settings", "Faster Elevators Settings")

        nativeSettings.addSwitch("/faster_elevators/general", "Faster Elevators",
            "Enable or Disable the Faster Elevators mod", self.settings.isEnabled, self.defaultSettings.isEnabled,
            function(state)
                self.settings.isEnabled = state
                SaveSettings()
            end)

        nativeSettings.addRangeFloat("/faster_elevators/settings", "Elevator Speed",
            "The speed of the elevator when you are in it. Game default value is 2.5. Anything over 25 makes you go through the floor and flatline.",
            self.minLiftSpeed,
            self.maxLiftSpeed,
            self.liftSpeedStep, "%.2f", self.settings.liftSpeed,
            self.defaultSettings.liftSpeed,
            function(value)
                self.settings.liftSpeed = value
                SaveSettings()
            end)

        nativeSettings.addRangeFloat("/faster_elevators/settings", "Empty Elevator Speed",
            "The speed of the elevator when it is empty (e.g., when you call it). Game default value is 5.0",
            self.minEmptyLiftSpeed,
            self.maxEmptyLiftSpeed,
            self.emptyLiftSpeedStep, "%.2f", self.settings.emptyLiftSpeed,
            self.defaultSettings.emptyLiftSpeed,
            function(value)
                self.settings.emptyLiftSpeed = value
                SaveSettings()
            end)
    end
end

return FasterLift:new()
