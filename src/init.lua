local RunService = game:GetService("RunService")



-- //

local RENDERSTEP_BIND_NAME = "SpringUpdate"

-- //



local SpringFactory = {Springs = {}}
local Spring = {}

-- //

export type Spring<T> = typeof(setmetatable({} :: {
    Target: T,
    Position: T,
    Velocity: T,

    Speed: number,
    Damper: number

}, {__index = Spring}))

-- //


function SpringFactory.new<T>(Initial: T)
    local newSpring = Spring.new(Initial)

    table.insert(SpringFactory.Springs, newSpring)

    return newSpring;
end


function SpringFactory.Dispose<T>(SpringObject: Spring<T>)
    local index = table.find(SpringFactory.Springs, SpringObject)

    if (index ~= nil) then
        table.clear(SpringObject)
        table.remove(SpringFactory.Springs, index)
    end
end


function Spring.new<T>(Initial: T)
    local self = setmetatable({
        Target = Initial,
        Position = Initial,
        Velocity = Initial * 0,

        Speed = 1,
        Damper = 1
    }, {__index = Spring})

    return self;
end


function Spring.UpdatePositionVelocity<T>(self: Spring<T>, DeltaTime: number)
    local Damper, Speed = self.Damper, self.Speed
    local P0, V0 = self.Position, self.Velocity
    local P1 = self.Target

    local DamperSquared = math.pow(Damper, 2)

    local t = Speed * DeltaTime
    local h, sin, cos

    if (DamperSquared < 1) then
        h = math.sqrt(1 - DamperSquared)

        local epsilon = math.exp(- (Damper * t))/h
        
        sin, cos = epsilon * math.sin(h * t), epsilon * math.cos(h * t)
    elseif (DamperSquared == 1) then
        h = 1

        local epsilon = math.exp(- (Damper * t))/h

        sin, cos = epsilon * math.sin(h * t), epsilon * math.cos(h * t)
    else
        h = math.sqrt(DamperSquared - 1)

        local u = math.exp( (- (Damper - h) * DeltaTime)/(2 * h) )
        local v = math.exp( (- (Damper - h) * DeltaTime)/(2 * h) )

        sin, cos = u - v, u + v
    end


    local a0 = h * cos + Damper * sin
    local a1 = 1 - (h * cos + Damper * sin)
    local a2 = sin/Speed

    local b0 = - (Speed * sin)
    local b1 = sin * Speed
    local b2 = h * cos - Damper * sin

    local updatedPosition = a0 * P0 + a1 * P1 + a2 * V0
    local updatedVelocity = b0 * P0 + b1 * P1 + b2 * V0

    return updatedPosition, updatedVelocity;
end

function Spring.Update<T>(self: Spring<T>, DeltaTime: number)
    local position, velocity = self:UpdatePositionVelocity(DeltaTime)

    self.Position = position
    self.Velocity = velocity
end

function Spring.Dispose<T>(self: Spring<T>)
    local index = table.find(SpringFactory.Springs, self)

    if (index ~= nil) then
        table.remove(SpringFactory.Springs, index)
    end

    table.clear(self)
end


if (RunService:IsClient()) then
    RunService:BindToRenderStep(RENDERSTEP_BIND_NAME, Enum.RenderPriority.First.Value, function(DeltaTime)
        for i, v in ipairs(SpringFactory.Springs) do
            v:Update(DeltaTime)
        end
    end)
else
    RunService.Heartbeat:Connect(function(DeltaTime)
        for i, v in ipairs(SpringFactory.Springs) do
            v:Update(DeltaTime)
        end
    end)
end



return SpringFactory;
