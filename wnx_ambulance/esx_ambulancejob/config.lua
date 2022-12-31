Config                            = {}

Config.DrawDistance               = 100.0

Config.Marker                     = { type = 20, x = 1.0, y = 1.0, z = 1.0, r = 0, g = 105, b = 0, a = 100, rotate = true }
Config.Marker2                     = { type = 21, x = 1.0, y = 1.0, z = 1.0, r = 0, g = 105, b = 0, a = 100, rotate = true }
Config.Marker3                     = { type = 22, x = 1.0, y = 1.0, z = 1.0, r = 0, g = 105, b = 0, a = 100, rotate = true }

Config.ReviveReward               = 50  -- revive reward, set to 0 if you don't want it enabled
Config.AntiCombatLog              = true -- enable anti-combat logging?
Config.LoadIpl                    = true -- disable if you're using fivem-ipl or other IPL loaders

Config.Locale = 'en'

local second = 1000
local minute = 60 * second

Config.EarlyRespawnTimer          = 10 * minute  -- Time til respawn is available
Config.BleedoutTimer              = 10 * minute -- Time til the player bleeds out

Config.EnablePlayerManagement     = true

Config.RemoveWeaponsAfterRPDeath  = false
Config.RemoveCashAfterRPDeath     = false
Config.RemoveItemsAfterRPDeath    = false

-- Let the player pay for respawning early, only if he can afford it.
Config.EarlyRespawnFine           = false
Config.EarlyRespawnFineAmount     = 5000

Config.RespawnPoint = { coords = vector3(298.84, -571.6, 43.26), heading = 157.07 }

Config.Hospitals = {

	CentralLosSantos = {

		Blip = {
			coords = vector3(297.66, -584.07, 43.26),
			sprite = 61,
			scale  = 0.7,
			color  = 2
		},

		AmbulanceActions = {
			vector3(310.96, -597.12, 43.28)
		},

		Pharmacies = {
			vector3(0, 0, 0)
		},

		Vehicles = {
			{
				Spawner = vector3(337.22, -586.51, 28.8),
				InsideShop = vector3(311.62, -575.47, 94.48),
				Marker = { type = 36, x = 1.0, y = 1.0, z = 1.0, r = 0, g = 105, b = 0, a = 100, rotate = true },
				SpawnPoints = {
					{ coords = vector3(330.06, -588.02, 28.8), heading = 338.99, radius = 4.0 },
					{ coords = vector3(323.33, -586.39, 28.8), heading = 338.99, radius = 4.0 },
					{ coords = vector3(317.89, -578.77, 28.8), heading = 250.24, radius = 6.0 },
					{ coords = vector3(321.69, -570.52, 28.8), heading = 250.24, radius = 6.0 }
				}
			}
		},

		Helicopters = {
			{
				Spawner = vector3(339.07, -588.58, 74.16),
				InsideShop = vector3(311.62, -575.47, 94.48),
				Marker = { type = 34, x = 1.0, y = 1.0, z = 1.0, r = 0, g = 105, b = 0, a = 100, rotate = true },
				SpawnPoints = {
					{ coords = vector3(351.33, -587.83, 74.16), heading = 166.7, radius = 10.0 },
				}
			}
		},

		FastTravels = {}
	}
}

Config.AuthorizedVehicles = {

	zachranar = {
		{ model = 'emsroamer', label = 'Auto', price = 150},
		{ model = 'emsnspeedo', label = 'Sanitka', price = 150}
	},

	lzachranar = {},

	lekar = {
		{ model = 'emsroamer', label = 'Auto', price = 100},
		{ model = 'emsnspeedo', label = 'Sanitka', price = 200}
	},

	doktor = {
		{ model = 'emsroamer', label = 'Auto', price = 100},
		{ model = 'emsnspeedo', label = 'Sanitka', price = 200}
	},

	vzachranar = {
		{ model = 'emsroamer', label = 'Auto', price = 100},
		{ model = 'emsnspeedo', label = 'Sanitka', price = 200}
	},

	sdoktor = {
		{ model = 'emsroamer', label = 'Auto', price = 100},
		{ model = 'emsnspeedo', label = 'Sanitka', price = 200}
	},

	primar = {
		{ model = 'emsroamer', label = 'Auto', price = 100},
		{ model = 'emsnspeedo', label = 'Sanitka', price = 200}
	},

	vedec = {
		{ model = 'emsroamer', label = 'Auto', price = 100},
		{ model = 'emsnspeedo', label = 'Sanitka', price = 200}
	},

	viceboss = {
		{ model = 'emsroamer', label = 'Auto', price = 100},
		{ model = 'emsnspeedo', label = 'Sanitka', price = 200}
	},

	boss = {
		{ model = 'emsroamer', label = 'Auto', price = 100},
		{ model = 'emsnspeedo', label = 'Sanitka', price = 200}
	}

}

Config.AuthorizedHelicopters = {

	zachranar = {},

	lzachranar = {
		{ model = 'mh65c', label = 'Helikopt�ra', price = 1000 }
	},

	lekar = {},

	doktor = {},

	vzachranar = {
		{ model = 'mh65c', label = 'Helikopt�ra', price = 1000 }
	},

	sdoktor = {},

	primar = {},

	vedec = {},

	viceboss = {
		{ model = 'mh65c', label = 'Helikopt�ra', price = 1000 }
	},

	boss = {
		{ model = 'mh65c', label = 'Helikopt�ra', price = 1000 }
	}

}
