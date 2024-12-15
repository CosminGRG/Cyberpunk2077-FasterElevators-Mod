local config = require("modules/config/config")

local FasterLift = {
    settings = {
    },
    defaultSettings = {
        isEnabled = true,
        liftSpeed = 2.5,
        emptyLiftSpeed = 5.0
    },

    minLiftSpeed = 1.0,
    maxLiftSpeed = 24.0,
    liftSpeedStep = 0.1,
    minEmptyLiftSpeed = 2.0,
    maxEmptyLiftSpeed = 50.0,
    emptyLiftSpeedStep = 0.1
}

function FasterLift:new()
    registerForEvent("onInit", function()
        self:InitializeSettings()
        self:ObserveLiftEvents()
    end)

    return self
end

function FasterLift:InitializeSettings()
    config.tryCreateConfig("config.json", self.defaultSettings)
    self.settings = config.loadFile("config.json")

    local nativeSettings = GetMod("nativeSettings")
    if not nativeSettings then
        print("[Always My Station] Error: Missing Native Settings")
        return
    end

    self:SetupMenu(nativeSettings)
end

function FasterLift:ObserveLiftEvents()
    Override("LiftControllerPS", "GetLiftSpeed",
        ---@param this LiftControllerPS
        ---@param wrappedMethod function
        ---@return Float
        function(this, wrappedMethod)
            if not self.settings.isEnabled then
                local result = wrappedMethod()
                return result
            end

            if this:IsPlayerInsideLift() then
                return self.settings.liftSpeed;
            end
            return self.settings.emptyLiftSpeed;
        end)
end

local function SaveSettings()
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
            self.speedStep, "%.2f", self.settings.liftSpeed,
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
