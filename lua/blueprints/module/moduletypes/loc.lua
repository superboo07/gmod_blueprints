AddCSLuaFile()

module("mod_locmodule", package.seeall, bpcommon.rescope(bpcommon, bpschema, bpcompiler))

local MODULE = {}

MODULE.Creatable = true
MODULE.Name = LOCTEXT"module_loc_name","Localization"
MODULE.Description = LOCTEXT"module_loc_desc","Localization data for the editor"
MODULE.Icon = "icon16/table.png"
MODULE.EditorClass = "locmodule"

function MODULE:Setup()

	BaseClass.Setup(self)

	self.data = {}

	local t = {}
	for k, v in ipairs( bplocalization.GetKeys() ) do
		t[v] = tostring(bplocalization.Get(v))
	end

	self.data.language = "en"
	self.data.keys = t

end

function MODULE:GetLanguage()

	return self.data.language

end

function MODULE:GetLocString( key )

	return self.data.keys[key]

end

function MODULE:WriteData( stream, mode, version )

	BaseClass.WriteData( self, stream, mode, version )

	stream:WriteStr( self.data.language )

	local num = 0
	for k,v in pairs(self.data.keys) do
		num = num + 1
	end

	stream:WriteInt( num, false )

	for k,v in pairs(self.data.keys) do
		stream:WriteStr( k )
		stream:WriteStr( v )
	end

end

function MODULE:ReadData( stream, mode, version )

	BaseClass.ReadData( self, stream, mode, version )

	self.data.language = stream:ReadStr()

	local num = stream:ReadInt()

	for i=1, num do

		local k = stream:ReadStr()
		local v = stream:ReadStr()
		self.data.keys[k] = v

	end

end


RegisterModuleClass("LocModule", MODULE, "Configurable")