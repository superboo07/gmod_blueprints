AddCSLuaFile()

module("bpfile", package.seeall)

function Sanitizer( str )

	return str

end

FL_None = 0
FL_Running = 1
FL_AlwaysRun = 2
FL_HasOwner = 4
FL_HasLock = 8
FL_IsServerFile = 16
FL_HasLocalChanges = 32

FT_Unknown = 0
FT_Module = 1

local meta = bpcommon.MetaTable("bpfile")
meta.__tostring = function(self) return self:ToString() end

bpcommon.AddFlagAccessors(meta)

meta.__eq = function(a,b)

	if a.uid ~= b.uid then return false end
	return true

end

function meta:Init(uid, type, name)

	self.flags = FL_None
	self.uid = uid or bpcommon.GUID()
	self.type = type or FT_Unknown
	self.name = name
	return self

end

function meta:GetLock()

	return self.lock

end

function meta:CanTakeLock( user )

	if self.lock ~= nil and self.lock ~= user then return false end
	return true

end

function meta:TakeLock( user )

	assert(SERVER)

	if not self:CanTakeLock(user) then error("File already locked by: " .. tostring( self.lock )) end
	self.lock = user
	if user ~= nil then self:SetFlag(FL_HasLock) end

end

function meta:ReleaseLock()

	assert(SERVER)

	self.lock = nil
	self:ClearFlag(FL_HasLock)

end

function meta:SetOwner( owner )

	self.owner = owner
	if self.owner ~= nil then
		self:SetFlag(FL_HasOwner)
	else
		self:ClearFlag(FL_HasOwner)
	end
	return self

end

function meta:GetOwner()

	return self.owner

end

function meta:GetUID()

	return self.uid

end

function meta:GetName()

	return self.name or bpcommon.GUIDToString(self.uid, true)

end

function meta:SetName( name )

	self.name = name

end

function meta:SetPath( path )

	self.path = path

end

function meta:SetRevision( rev )

	self.revision = rev

end

function meta:GetRevision()

	return self.revision or 0

end

function meta:GetPath()

	return self.path

end

function meta:GetName()

	return self.name or ""

end

function meta:WriteToStream(stream, mode, version)

	stream:WriteBits(self.flags, 8)
	stream:WriteStr(self.uid)
	bpdata.WriteValue(self.name, stream)

	if mode == bpcommon.STREAM_NET then
		stream:WriteInt(self.revision or 0, false)
	end

	if self:HasFlag(FL_HasOwner) then
		self.owner:WriteToStream(stream, mode, version)
	end

	if self:HasFlag(FL_HasLock) then
		self.lock:WriteToStream(stream, mode, version)
	end

end

function meta:ReadFromStream(stream, mode, version)

	self.flags = stream:ReadBits(8)
	self.uid = stream:ReadStr(16)
	self.name = bpdata.ReadValue(stream)

	if mode == bpcommon.STREAM_FILE then
		if not self:HasFlag( FL_AlwaysRun ) then self:ClearFlag( FL_Running ) end
	end

	if mode == bpcommon.STREAM_NET then
		self.revision = stream:ReadInt(false)
	end

	if self:HasFlag(FL_HasOwner) then
		self.owner = bpuser.New()
		self.owner:ReadFromStream(stream, mode, version)
	end

	if self:HasFlag(FL_HasLock) then
		self.lock = bpuser.New()
		self.lock:ReadFromStream(stream, mode, version)
	end

	return self

end

function meta:CopyRemoteToLocal( f )

	f.owner = self.owner
	f.lock = self.lock
	f.uid = self.uid
	f.name = self.name

	local copyFlagMask = bit.bor( FL_HasOwner, FL_HasLock, FL_AlwaysRun, FL_Running, FL_IsServerFile )
	local fl = self:GetFlags()
	local oldFlags = f:GetFlags()

	f:SetFlags( bit.bor( bit.band(oldFlags, bit.bnot(copyFlagMask)), bit.band(fl, copyFlagMask) ) )

end

function meta:ForgetRemote()

	self:ClearFlag( bpfile.FL_IsServerFile )
	self:ClearFlag( bpfile.FL_HasLock )
	self:ClearFlag( bpfile.FL_HasOwner )
	self:ClearFlag( bpfile.FL_Running )

	self.lock = nil
	self.owner = nil

end

function meta:ToString()

	local name = self.name or "unnamed"
	local own = self:HasFlag(FL_HasOwner) and " [" .. tostring(self.owner) .. "]" or ""
	return "[" .. name .. "] " .. bpcommon.GUIDToString( self.uid ) .. " (" .. self.flags .. ")" .. own

end

function New(...) return bpcommon.MakeInstance(meta, ...) end