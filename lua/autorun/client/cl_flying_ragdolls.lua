local cvars_AddChangeCallback = cvars.AddChangeCallback
local CreateClientConVar = CreateClientConVar
local LocalPlayer = LocalPlayer
local util_Decal = util.Decal
local tonumber = tonumber
local hook_Add = hook.Add
local IsValid = IsValid
local tobool = tobool
local pairs = pairs

local enable = CreateClientConVar( "flying_ragdolls", "1", true, false, "Enable/Disable ragdoll fly on client", 0, 1):GetBool()
cvars_AddChangeCallback( "flying_ragdolls", function( name, old, new)
    enable = tobool( new ) or false
end, "flying_ragdolls")

local velocity = (CreateClientConVar( "flying_ragdolls_speed", "10", true, false, "Ragdoll fly speed...", 0, 10000):GetInt() or 10) * 100
cvars_AddChangeCallback( "flying_ragdolls_speed", function( name, old, new)
    velocity = (tonumber( new ) or 10) * 100
end, "flying_ragdolls")

local directions = {
    [KEY_W] = function( ang )
        return ang:Forward() * velocity
    end,
    [KEY_S] = function( ang )
        return ang:Forward() * -velocity
    end,
    [KEY_D] = function( ang )
        return ang:Right() * velocity
    end,
    [KEY_A] = function( ang )
        return ang:Right() * -velocity
    end
}

hook_Add("CreateClientsideRagdoll", "flying_ragdolls", function( pl, ent )
    if enable and pl:IsPlayer() and (pl:EntIndex() == LocalPlayer():EntIndex()) then
        local keys = {
            [KEY_W] = false,
            [KEY_S] = false,
            [KEY_A] = false,
            [KEY_D] = false
        }

        ent:AddCallback( "PhysicsCollide", function( self, data )
            if (data["HitSpeed"]:Length() > 1000) then
                util_Decal("Blood", data["HitPos"] + data["HitNormal"], data["HitPos"] - data["HitNormal"])
            end
        end)

        hook_Add("PlayerButtonDown", ent, function( self, ply, key )
            if (ply:EntIndex() == pl:EntIndex()) and (keys[ key ] != nil) then
                keys[ key ] = true
            end
        end)

        hook_Add("PlayerButtonUp", ent, function( self, ply, key )
            if (ply:EntIndex() == pl:EntIndex()) and (keys[ key ] != nil) then
                keys[ key ] = false
            end
        end)

        local phys = ent:GetPhysicsObject()
        if IsValid( phys ) then
            hook_Add("Think", phys, function( self )
                for key, state in pairs( keys ) do
                    if ( state == true ) then
                        local func = directions[ key ]
                        if ( func == nil ) then continue end

                        self:ApplyForceCenter( func( pl:EyeAngles() ) )
                    end
                end
            end)
        end
    end
end)