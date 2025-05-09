WITH motorcyclist_parties AS (        -- find motorcycle‐involved parties and tag helmet use
    SELECT
        p.case_id,
        MAX(                             -- 1 if ANY motorcyclist in the crash wore a helmet
            CASE
                WHEN (LOWER(COALESCE(p.party_safety_equipment_1,'')) LIKE '%helmet%'
                      AND LOWER(COALESCE(p.party_safety_equipment_1,'')) NOT LIKE '%no helmet%'
                      AND LOWER(COALESCE(p.party_safety_equipment_1,'')) NOT LIKE '%not%')
                  OR (LOWER(COALESCE(p.party_safety_equipment_2,'')) LIKE '%helmet%'
                      AND LOWER(COALESCE(p.party_safety_equipment_2,'')) NOT LIKE '%no helmet%'
                      AND LOWER(COALESCE(p.party_safety_equipment_2,'')) NOT LIKE '%not%')
                THEN 1 ELSE 0
            END
        )  AS has_helmet,

        MAX(                             -- 1 if ANY motorcyclist in the crash had no helmet
            CASE
                WHEN (LOWER(COALESCE(p.party_safety_equipment_1,'')) LIKE '%no helmet%'
                      OR  LOWER(COALESCE(p.party_safety_equipment_1,'')) LIKE '%helmet not%'
                      OR  LOWER(COALESCE(p.party_safety_equipment_1,'')) LIKE '%not worn%')
                  OR (LOWER(COALESCE(p.party_safety_equipment_2,'')) LIKE '%no helmet%'
                      OR  LOWER(COALESCE(p.party_safety_equipment_2,'')) LIKE '%helmet not%'
                      OR  LOWER(COALESCE(p.party_safety_equipment_2,'')) LIKE '%not worn%')
                THEN 1 ELSE 0
            END
        )  AS has_no_helmet
    FROM parties p
    WHERE LOWER(COALESCE(p.statewide_vehicle_type,'')) LIKE '%motorcycle%'   -- only motorcyclists
    GROUP BY p.case_id
),

helmet_status_per_collision AS (       -- explode to one row per (collision, helmet group)
    SELECT DISTINCT case_id, 'helmet_worn' AS helmet_usage
    FROM   motorcyclist_parties
    WHERE  has_helmet = 1

    UNION ALL

    SELECT DISTINCT case_id, 'no_helmet' AS helmet_usage
    FROM   motorcyclist_parties
    WHERE  has_no_helmet = 1
),

motorcycle_collisions AS (             -- keep only motorcycle collisions & fatal counts
    SELECT
        case_id,
        COALESCE(motorcyclist_killed_count,0) AS motorcyclist_killed_count
    FROM collisions
    WHERE motorcycle_collision = 1
)

SELECT
    h.helmet_usage,
    SUM(mc.motorcyclist_killed_count)                          AS total_motorcyclist_fatalities,
    COUNT(DISTINCT h.case_id)                                  AS total_collisions,
    ROUND(100.0 * SUM(mc.motorcyclist_killed_count)
                / COUNT(DISTINCT h.case_id), 4)                AS fatality_rate_percentage
FROM   helmet_status_per_collision h
JOIN   motorcycle_collisions mc
       ON mc.case_id = h.case_id
GROUP BY h.helmet_usage;