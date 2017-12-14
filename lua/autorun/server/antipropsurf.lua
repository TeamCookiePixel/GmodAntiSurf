/* MIT License

Copyright (c) 2017 Elanis

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

AntiPropSurf = AntiPropSurf or {};

/**
 * Convars
 */
CreateConVar('antipropsurf_enable','1', {FVCAR_REPLICATED, FCVAR_ARCHIVE, FCVAR_NOTIFY},'Is the propsurf protection enabled ?');
CreateConVar('antipropsurf_admin_prevent','1', {FVCAR_REPLICATED, FCVAR_ARCHIVE, FCVAR_NOTIFY},'Do we block admin doing propsurf ?');

/**
 * Functions
 */
function AntiPropSurf.NoCollide(ply,ent)
	if(not ent:IsValid()) then return end

	if(not ent:IsPlayer() and
		not ent:IsWeapon() and
		not ent:IsNPC()) then
		
		ent:SetCollisionGroup( COLLISION_GROUP_INTERACTIVE_DEBRIS )
		ply:SetCollisionGroup( COLLISION_GROUP_INTERACTIVE_DEBRIS )	

		ply:GetPhysicsObject():SetMass(ply:GetPhysicsObject():GetMass() * 10)

		ent:SetPos(ent:GetPos())
		ply:SetPos(ply:GetPos())
	end
end

function AntiPropSurf.Collide(ply,ent)
	timer.Create("AntiPropSurf.Collide.Timeout", 0.25, 1, function() // We need a timeout to prevent some freeze exploits
		if(not ent:IsValid()) then return end
		
		if(not ent:IsPlayer() and
			not ent:IsWeapon() and
			not ent:IsNPC()) then
			
			ply:GetPhysicsObject():SetMass(ply:GetPhysicsObject():GetMass() / 10)
			ent:SetCollisionGroup( COLLISION_GROUP_NONE )	
		end

		ply:SetCollisionGroup( COLLISION_GROUP_PLAYER )
	end);
end

function AntiPropSurf.PickupObject(ply, ent)
	// Check convars
	if(not GetConVar('antipropsurf_enable'):GetBool()) then return end

	if(not GetConVar('antipropsurf_admin_prevent'):GetBool()) then
		if(ply:IsAdmin() || ply:IsSuperAdmin()) then return end
	end

	// Make physgunned (Does this exists ?) ent nocollide
	AntiPropSurf.NoCollide(ply,ent);

	// Make constrained ents nocollide too
	for k, v in pairs(constraint.GetAllConstrainedEntities(ent)) do
		AntiPropSurf.NoCollide(ply,v);
	end
end

function AntiPropSurf.DropObject(ply, ent)
	// Check convars
	if(not GetConVar('antipropsurf_enable'):GetBool()) then return end

	if(not GetConVar('antipropsurf_admin_prevent'):GetBool()) then
		if(ply:IsAdmin() || ply:IsSuperAdmin()) then return end
	end

	// Restore physgunned (Does this exists ?) ent collision
	AntiPropSurf.Collide(ply,ent);

	// Restore constrained ents collision
	for k, v in pairs(constraint.GetAllConstrainedEntities(ent)) do
		AntiPropSurf.Collide(ply,v);
	end
end

hook.Add( "PhysgunPickup", "AntiPropSurf.PhysgunPickup", AntiPropSurf.PickupObject);
hook.Add( "OnPhysgunFreeze", "AntiPropSurf.OnPhysgunFreeze", function( weapon, physobj, ent, ply ) AntiPropSurf.DropObject(ply, ent) end);
hook.Add( "PhysgunDrop", "AntiPropSurf.PhysgunDrop", AntiPropSurf.DropObject);