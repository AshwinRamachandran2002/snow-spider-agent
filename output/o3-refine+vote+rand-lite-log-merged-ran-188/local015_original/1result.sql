WITH motorcyclist_parties AS (   -- every motorcyclist party & whether a helmet was / wasn’t worn
    SELECT
        "case_id",
        /* helmet worn if equipment mentions helmet and does NOT mention “not” */
        CASE
            WHEN (LOWER(COALESCE("party_safety_equipment_1",'')) LIKE '%helmet%' 
                  AND LOWER("party_safety_equipment_1") NOT LIKE '%not%')
              OR (LOWER(COALESCE("party_safety_equipment_2",'')) LIKE '%helmet%' 
                  AND LOWER("party_safety_equipment_2") NOT LIKE '%not%')
            THEN 1 ELSE 0
        END AS helmet_worn,
        /* helmet NOT worn if equipment string contains “helmet” together with “not”  */
        CASE
            WHEN LOWER(COALESCE("party_safety_equipment_1",'')) LIKE '%helmet%not%'
              OR (LOWER("party_safety_equipment_1") LIKE '%helmet%' 
                  AND LOWER("party_safety_equipment_1") LIKE '%not%')
              OR LOWER(COALESCE("party_safety_equipment_2",'')) LIKE '%helmet%not%'
              OR (LOWER("party_safety_equipment_2") LIKE '%helmet%' 
                  AND LOWER("party_safety_equipment_2") LIKE '%not%')
            THEN 1 ELSE 0
        END AS helmet_not_worn
    FROM "parties"
    WHERE LOWER(COALESCE("statewide_vehicle_type",'')) LIKE '%motorcycle%'   -- only motorcyclists
),

helmet_status_by_case AS (       -- roll up to one row per collision
    SELECT
        "case_id",
        MAX(helmet_worn)      AS has_helmet,     -- 1 if any motorcyclist wore a helmet
        MAX(helmet_not_worn)  AS no_helmet       -- 1 if any motorcyclist did NOT wear a helmet
    FROM motorcyclist_parties
    GROUP BY "case_id"
)

-- final fatality rates
SELECT
    'with_helmet' AS helmet_usage,
    ROUND(
        SUM(COALESCE(c."motorcyclist_killed_count",0)) * 100.0 / COUNT(*),
        4
    ) AS fatality_rate_pct
FROM "collisions" c
JOIN helmet_status_by_case h ON h."case_id" = c."case_id"
WHERE h.has_helmet = 1

UNION ALL

SELECT
    'without_helmet' AS helmet_usage,
    ROUND(
        SUM(COALESCE(c."motorcyclist_killed_count",0)) * 100.0 / COUNT(*),
        4
    ) AS fatality_rate_pct
FROM "collisions" c
JOIN helmet_status_by_case h ON h."case_id" = c."case_id"
WHERE h.no_helmet = 1;