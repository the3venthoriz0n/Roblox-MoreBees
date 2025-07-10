local GameConfig = {}

-- ============================================================================
-- DEBUG SETTINGS
-- ============================================================================
GameConfig.DEBUG = false
GameConfig.LOG_LEVEL = "debug" -- "debug", "info", "warn", "error"
GameConfig.DEBUG_HONEY_DRIPS_VALUE = 100

-- ============================================================================
-- PLAYER SETTINGS
-- ============================================================================
GameConfig.DEFAULT_WALK_SPEED = 16
GameConfig.DEFAULT_MAX_HEALTH = 100

-- ============================================================================
-- BEE SPAWNING SETTINGS
-- ============================================================================
GameConfig.SWARM = false -- Set to true to enable bee swarming behavior
GameConfig.AUTO_SPAWN_INTERVAL = 1 -- Spawn a bee every 1 second
GameConfig.BASE_MIN_BEES = 30 -- Base minimum number of bees
GameConfig.BEES_PER_PLAYER = 5 -- Additional bees per player
GameConfig.MIN_SPAWN_INTERVAL = 1 -- Spawn every second when below minimum
GameConfig.MAX_SPAWN_INTERVAL = 10 -- Normal spawn interval when at or above minimum

-- ============================================================================
-- BEE BEHAVIOR SETTINGS
-- ============================================================================
GameConfig.MAX_CHASE_TIME = 5 -- seconds a bee can chase before getting tired
GameConfig.TIRED_SPEED_MULTIPLIER = 4 -- Multiplier for speed when tired (e.g., 1.5 means 1.5x slower)
GameConfig.AGRAVATION_RADIUS = 25 -- Bees will only attack if player is within 25 studs
GameConfig.WANDER_RADIUS = 100 -- How far bees can wander from the center

-- ============================================================================
-- BEE PHYSICS SETTINGS
-- ============================================================================
GameConfig.BODY_MOVER_MULTIPLIER = 2500 -- Multiply P and D values by this to work with smaller numbers
GameConfig.BODY_POSITION_P = 10 -- P value for BodyPosition (multiplied by BODY_MOVER_MULTIPLIER)
GameConfig.BODY_POSITION_D = 1 -- D value for BodyPosition (multiplied by BODY_MOVER_MULTIPLIER)
GameConfig.BODY_GYRO_P = 10 -- P value for BodyGyro (multiplied by BODY_MOVER_MULTIPLIER)
GameConfig.BODY_GYRO_D = 1 -- D value for BodyGyro (multiplied by BODY_MOVER_MULTIPLIER)

-- ============================================================================
-- BEE STATE VALUES
-- ============================================================================
GameConfig.BEE_ALIVE_VALUE = 1 -- Value for alive bee state
GameConfig.BEE_DEAD_VALUE = 0 -- Value for dead bee state

-- ============================================================================
-- HONEYDRIP SETTINGS
-- ============================================================================
GameConfig.MAX_HONEYDRIPS = 20 -- Maximum number of HoneyDrips allowed in workspace
GameConfig.BASE_DRIP_SPAWN_INTERVAL = 10 -- Base interval in seconds for drips to spawn
GameConfig.DRIP_SPAWN_DECREASE_PER_BEE = 0.5 -- How much interval decreases per alive bee
GameConfig.FLYING_BEE_DRIP_CHANCE = 25 -- 25% chance for a HoneyDrip to drop from a flying bee per check
GameConfig.FLYING_BEE_DRIP_CHECK_INTERVAL = 10 -- seconds between drop checks for a flying bee
GameConfig.HEAL_AMOUNT_HONEYDRIP = 25 -- Amount of health HoneyDrip restores
GameConfig.DEFAULT_HONEYDRIP_AMOUNT = 1 -- Default HoneyDrip amount if DripAmount object not found

-- ============================================================================
-- HONEYDRIP SPAWN SETTINGS
-- ============================================================================
GameConfig.BEEHIVE_SPAWN_OFFSET_X = 2 -- random X offset range for HoneyDrip spawning
GameConfig.BEEHIVE_SPAWN_OFFSET_Z = 2 -- random Z offset range for HoneyDrip spawning
GameConfig.BEEHIVE_SPAWN_Y = 0 -- Y position (ground level) for HoneyDrip spawning

-- ============================================================================
-- POWER-UP SETTINGS
-- ============================================================================
GameConfig.SPEED_BOOST_MULTIPLIER = 1.5 -- 50% speed increase
GameConfig.HEALTH_BOOST_AMOUNT = 50 -- Additional health points
GameConfig.BEE_SPAWN_COUNT = 10 -- Number of bees to spawn with power-up
GameConfig.BEE_SPAWN_COLOR = "Really red" -- Color of spawned bees

-- ============================================================================
-- COLLISION GROUPS
-- ============================================================================
GameConfig.PLAYER_COLLISION_GROUP = "PlayerGroup"
GameConfig.BEE_COLLISION_GROUP = "BeeGroup"
GameConfig.BEEHIVE_COLLISION_GROUP = "BeeHiveGroup"
GameConfig.CUBE_COLLISION_GROUP = "FlyingGroup"

-- ============================================================================
-- AUDIO SETTINGS
-- ============================================================================
GameConfig.BUZ_SOUND_COUNT = 2 -- Number of buz sound variations
GameConfig.STING_SOUND_COUNT = 5 -- Number of sting sound variations  
GameConfig.HONEYDRIP_SOUND_COUNT = 2 -- Number of honey drip sound variations
GameConfig.SOUND_VOLUME = 0.7 -- default volume for sounds

-- ============================================================================
-- VISUAL SETTINGS
-- ============================================================================
GameConfig.HONEYDRIP_TRANSPARENCY = 0 -- Transparency for HoneyDrip visibility
GameConfig.BEE_DEATH_TRANSPARENCY = 0.8 -- Transparency when bee dies
GameConfig.STAMINA_TEXT_BACKGROUND_TRANSPARENCY = 1 -- Background transparency for stamina text
GameConfig.STAMINA_TEXT_STROKE_TRANSPARENCY = 0 -- Text stroke transparency for stamina text

-- ============================================================================
-- VISUAL FEEDBACK SETTINGS
-- ============================================================================
GameConfig.HEAL_FLASH_DURATION = 0.1 -- seconds for heal flash effect
GameConfig.HEAL_FLASH_COLOR = "Bright green" -- color for heal flash
GameConfig.HONEYDRIP_PICKUP_DELAY = 0.1 -- delay before destroying HoneyDrip after pickup

-- ============================================================================
-- UI SETTINGS
-- ============================================================================
GameConfig.FEEDBACK_DISPLAY_TIME = 3 -- seconds to show purchase feedback

-- ============================================================================
-- TIMING SETTINGS
-- ============================================================================
GameConfig.SCORE_UPDATE_INTERVAL = 1 -- seconds between score updates

return GameConfig 