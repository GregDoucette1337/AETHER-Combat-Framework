local Config = {}

Config.AllowPvP = false
Config.AirJump = { Cooldown = 0, UpwardSpeed = 68 }
Config.AirDash = { Cooldown = 1.6, Speed = 105, Duration = 0.23 }
Config.Slide = { Cooldown = 2.8, Speed = 72, Duration = 0.62 }
Config.Blink = { Cooldown = 5.5, Range = 29, WallPadding = 4 }
Config.GravityWell = { Cooldown = 12, Range = 78, Radius = 17,
	Duration = 3.6, PulseEvery = 0.6, PulseDamage = 11, MaxTargetsPerPulse = 8 }
Config.MeteorBarrage = { Cooldown = 20, Range = 85, Count = 6,
	Spread = 14, Warning = 0.43, Interval = 0.46, Radius = 8,
	Damage = 27, FinalRadius = 16, FinalDamage = 48 }

return Config
