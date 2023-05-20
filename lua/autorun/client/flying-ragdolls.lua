local addonName = "Flying Ragdolls!"

-- Libraries
local hook = hook

-- Variables
local KEY_W, KEY_S, KEY_D, KEY_A = KEY_W, KEY_S, KEY_D, KEY_A
local CreateClientConVar = CreateClientConVar
local LocalPlayer = LocalPlayer
local util_Decal = util.Decal
local IsValid = IsValid
local ipairs = ipairs

local enabled = CreateClientConVar( "cl_flying_ragdolls", "1", true, false, "Allows control of the player's body after death if 1.", 0, 1 )
local blood = CreateClientConVar( "cl_flying_ragdolls_blood", "1", true, false, "If the impact is strong enough it will leave a trail of blood if 1.", 0, 1 )
local velocity = CreateClientConVar( "cl_flying_ragdolls_speed", "10", true, false, "Player's dead body flight speed.", 0, 10000 ):GetInt() * 100
cvars.AddChangeCallback( "cl_flying_ragdolls_speed", function( _, __, value )
    velocity = ( tonumber( value ) or 10 ) * 100
end, addonName )

local directions = {
    [ KEY_W ] = function( ang ) return ang:Forward() * velocity end,
    [ KEY_S ] = function( ang ) return ang:Forward() * -velocity end,
    [ KEY_D ] = function( ang ) return ang:Right() * velocity end,
    [ KEY_A ] = function( ang ) return ang:Right() * -velocity end
}

hook.Add( "CreateClientsideRagdoll", addonName, function( entity, ragdoll )
    if not enabled:GetBool() then return end
    if entity:EntIndex() ~= LocalPlayer():EntIndex() then return end

    local phys = ragdoll:GetPhysicsObject()
    if not IsValid( phys ) then return end

    local keys = {
        { KEY_W, false },
        { KEY_S, false },
        { KEY_A, false },
        { KEY_D, false }
    }

    hook.Add( "PlayerButtonDown", phys, function( _, __, keyCode )
        for _, data in ipairs( keys ) do
            if data[1] == keyCode then
                data[2] = true
                break
            end
        end
    end )

    hook.Add( "PlayerButtonUp", phys, function( _, __, keyCode )
        for _, data in ipairs( keys ) do
            if data[1] == keyCode then
                data[2] = false
                break
            end
        end
    end )

    hook.Add( "Think", phys, function( self )
        for _, data in ipairs( keys ) do
            if not data[2] then continue end

            local func = directions[ data[1] ]
            if not func then continue end

            self:ApplyForceCenter( func( entity:EyeAngles() ) )
        end
    end )

    ragdoll:AddCallback( "PhysicsCollide", function( _, data )
        if not blood:GetBool() then return end
        if data.HitSpeed:Length() < 1000 then return end
        util_Decal( "Blood", data.HitPos + data.HitNormal, data.HitPos - data.HitNormal )
    end )
end )