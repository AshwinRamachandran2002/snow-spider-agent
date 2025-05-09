WITH motorcyclist_parties AS (           -- motorcyclists + their helmet status
    SELECT
        p.case_id,
        /* 1 = helmet worn, 0 = helmet NOT worn, NULL = unknown/other */
        CASE
            WHEN (LOWER(IFNULL(p.party_safety_equipment_1,'')) LIKE '%helmet%' 
                  AND LOWER(IFNULL(p.party_safety_equipment_1,'')) NOT LIKE '%not%')
              OR (LOWER(IFNULL(p.party_safety_equipment_2,'')) LIKE '%helmet%' 
                  AND LOWER(IFNULL(p.party_safety_equipment_2,'')) NOT LIKE '%not%')
            THEN 1
            WHEN (LOWER(IFNULL(p.party_safety_equipment_1,'')) LIKE '%helmet%' 
                  AND LOWER(IFNULL(p.party_safety_equipment_1,'')) LIKE '%not%')
              OR (LOWER(IFNULL(p.party_safety_equipment_2,'')) LIKE '%helmet%' 
                  AND LOWER(IFNULL(p.party_safety_equipment_2,'')) LIKE '%not%')
            THEN 0
            ELSE NULL
        END AS helmet_worn
    FROM parties p
    WHERE LOWER(IFNULL(p.statewide_vehicle_type,'')) LIKE '%motorcycle%'   -- only motorcyclists
),

helmet_status_per_collision AS (         -- collision‑level helmet flag
    SELECT
        case_id,
        CASE
            WHEN MAX(helmet_worn) = 1 THEN 1          -- at least one motorcyclist wore a helmet
            WHEN MAX(helmet_worn) = 0 THEN 0          -- none wore a helmet (at least one known “not worn”)
            ELSE NULL                                 -- helmet use unknown
        END AS helmet_worn
    FROM motorcyclist_parties
    GROUP BY case_id
),

motorcycle_collisions AS (               -- collisions involving motorcycles
    SELECT
        c.case_id,
        COALESCE(c.motorcyclist_killed_count,0) AS motorcyclist_killed_count
    FROM collisions c
    WHERE c.motorcycle_collision = 1
),

combined AS (                            -- bring everything together
    SELECT
        mc.case_id,
        hs.helmet_worn,
        mc.motorcyclist_killed_count
    FROM motorcycle_collisions mc
    LEFT JOIN helmet_status_per_collision hs
           ON mc.case_id = hs.case_id
),

filtered AS (                            -- keep collisions with known helmet status
    SELECT * 
    FROM combined 
    WHERE helmet_worn IS NOT NULL
)

SELECT
    ROUND(
        100.0 * SUM(CASE WHEN helmet_worn = 1 THEN motorcyclist_killed_count END) /
        NULLIF(COUNT(DISTINCT CASE WHEN helmet_worn = 1 THEN case_id END), 0), 4
    ) AS helmet_worn_fatality_rate_percent,
    
    ROUND(
        100.0 * SUM(CASE WHEN helmet_worn = 0 THEN motorcyclist_killed_count END) /
        NULLIF(COUNT(DISTINCT CASE WHEN helmet_worn = 0 THEN case_id END), 0), 4
    ) AS helmet_not_worn_fatality_rate_percent
FROM filtered;