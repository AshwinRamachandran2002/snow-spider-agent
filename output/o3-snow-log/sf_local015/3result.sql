/*  Fatality-rate of motorcycle collisions split by helmet usage  */
WITH moto_collisions AS (          -- one row per motorcycle collision
    SELECT
        c."case_id",
        c."motorcyclist_killed_count"                                          AS moto_killed,
        /* 1 = at least one motorcycle party used a helmet (and “not used” not mentioned),
           0 = no motorcycle party with a confirmed helmet-use record          */
        MAX(
            CASE
                 WHEN ( (p."party_safety_equipment_1" ILIKE '%helmet%' 
                          AND p."party_safety_equipment_1" NOT ILIKE '%not used%' )
                        OR
                        (p."party_safety_equipment_2" ILIKE '%helmet%' 
                          AND p."party_safety_equipment_2" NOT ILIKE '%not used%' ) )
                 THEN 1
                 ELSE 0
            END
        )                                                                       AS helmet_used
    FROM   CALIFORNIA_TRAFFIC_COLLISION.CALIFORNIA_TRAFFIC_COLLISION."COLLISIONS"  c
    JOIN   CALIFORNIA_TRAFFIC_COLLISION.CALIFORNIA_TRAFFIC_COLLISION."PARTIES"     p
           ON c."case_id" = p."case_id"
    WHERE  p."statewide_vehicle_type" ILIKE '%motorcycle%'
    GROUP  BY c."case_id", c."motorcyclist_killed_count"
),
agg AS (                                  -- aggregate by helmet-usage group
    SELECT
        helmet_used,                                   -- 1 = helmet worn, 0 = not worn
        COUNT(*)                               AS total_collisions,
        SUM(moto_killed)                       AS total_motorcyclist_fatalities
    FROM   moto_collisions
    GROUP  BY helmet_used
)
SELECT
    helmet_used,
    total_collisions,
    total_motorcyclist_fatalities,
    ROUND(100.0 * total_motorcyclist_fatalities / NULLIF(total_collisions,0), 4) 
        AS fatality_rate_percent
FROM   agg
ORDER BY helmet_used DESC NULLS LAST;