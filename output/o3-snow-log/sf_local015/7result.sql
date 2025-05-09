/* ------------------------------------------------------------
   Motorcyclist fatality rate by helmet usage
   ------------------------------------------------------------ */

WITH motorcycle_parties AS (      -- all motorcycle parties and their helmet wording
    SELECT
        p."case_id",
        UPPER(
            COALESCE(p."party_safety_equipment_1", '') || ' ' ||
            COALESCE(p."party_safety_equipment_2", '')
        )                                       AS "equip_text"
    FROM CALIFORNIA_TRAFFIC_COLLISION.CALIFORNIA_TRAFFIC_COLLISION.PARTIES p
    WHERE p."statewide_vehicle_type" ILIKE '%motorcycle%'          -- keep only motorcycle parties
),

party_helmet_flag AS (            -- classify each party row
    SELECT
        "case_id",
        CASE
            WHEN "equip_text" LIKE '%HELMET%NOT%USED%' THEN 'no_helmet'
            WHEN "equip_text" LIKE '%HELMET%USED%'     THEN 'helmet_worn'
            ELSE 'unknown'
        END AS "party_helmet_status"
    FROM motorcycle_parties
),

case_helmet_status AS (           -- reduce to one status per collision
    SELECT
        "case_id",
        CASE
            WHEN MAX(IFF("party_helmet_status" = 'no_helmet',     1, 0)) = 1 THEN 'no_helmet'
            WHEN MAX(IFF("party_helmet_status" = 'helmet_worn',  1, 0)) = 1 THEN 'helmet_worn'
            ELSE 'unknown'
        END AS "helmet_status"
    FROM party_helmet_flag
    GROUP BY "case_id"
)

SELECT
    chs."helmet_status",
    SUM(COALESCE(c."motorcyclist_killed_count", 0))          AS "motorcyclist_fatalities",
    COUNT(*)                                                 AS "total_motorcycle_collisions",
    ROUND(
        (SUM(COALESCE(c."motorcyclist_killed_count", 0)) / 
         NULLIF(COUNT(*), 0)) * 100, 4)                      AS "fatality_rate_percent"
FROM case_helmet_status                 chs
JOIN CALIFORNIA_TRAFFIC_COLLISION.CALIFORNIA_TRAFFIC_COLLISION.COLLISIONS c
     ON c."case_id" = chs."case_id"
WHERE chs."helmet_status" IN ('helmet_worn', 'no_helmet')     -- only the two requested groups
  AND c."motorcycle_collision" > 0                            -- ensure motorcycle collision
GROUP BY chs."helmet_status";