WITH mc_party AS (   -- motorcycle-involved parties (drivers or passengers)
    SELECT DISTINCT 
           p."case_id",
           COALESCE(p."party_safety_equipment_1", '') AS se1,
           COALESCE(p."party_safety_equipment_2", '') AS se2
    FROM CALIFORNIA_TRAFFIC_COLLISION.CALIFORNIA_TRAFFIC_COLLISION."PARTIES" p
    WHERE p."statewide_vehicle_type" ILIKE '%motorcycle%'
),

helmet_cases AS (    -- at least one motorcycle party used a helmet
    SELECT DISTINCT "case_id"
    FROM mc_party
    WHERE se1 ILIKE '%helmet%' 
       OR se2 ILIKE '%helmet%'
),

no_helmet_cases AS ( -- none of the motorcycle parties used a helmet
    SELECT DISTINCT "case_id"
    FROM mc_party
    WHERE NOT (se1 ILIKE '%helmet%' OR se2 ILIKE '%helmet%')
      AND "case_id" NOT IN (SELECT "case_id" FROM helmet_cases)
),

helmet_stats AS (
    SELECT 
        'Helmet Used'         AS helmet_usage,
        COUNT(DISTINCT h."case_id")                               AS collision_total,
        SUM(COALESCE(c."motorcyclist_killed_count",0))            AS fatalities
    FROM helmet_cases h
    JOIN CALIFORNIA_TRAFFIC_COLLISION.CALIFORNIA_TRAFFIC_COLLISION."COLLISIONS" c
      ON h."case_id" = c."case_id"
),

no_helmet_stats AS (
    SELECT 
        'No Helmet'           AS helmet_usage,
        COUNT(DISTINCT n."case_id")                               AS collision_total,
        SUM(COALESCE(c."motorcyclist_killed_count",0))            AS fatalities
    FROM no_helmet_cases n
    JOIN CALIFORNIA_TRAFFIC_COLLISION.CALIFORNIA_TRAFFIC_COLLISION."COLLISIONS" c
      ON n."case_id" = c."case_id"
)

SELECT
    helmet_usage,
    collision_total,
    fatalities,
    ROUND( (fatalities / NULLIF(collision_total,0)) * 100, 4 )   AS fatality_rate_percentage
FROM (
    SELECT * FROM helmet_stats
    UNION ALL
    SELECT * FROM no_helmet_stats
)
ORDER BY helmet_usage;