adminManager = adminManager or {
	Admins = {},

	AddAdmin = function(self, id)
		self.Admins[id] = true
	end,

	Initialize = function(self)
		return self
	end,

	PlayerIsAdmin = function(self, plyid)
		return self.Admins[plyid]
	end,
}