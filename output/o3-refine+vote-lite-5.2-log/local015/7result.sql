WITH motorcycle_collisions AS (
    -- keep only crashes that involved a motorcycle
    SELECT
        c."case_id",
        COALESCE(c."motorcyclist_killed_count",0) AS motorcyclist_killed
    FROM "collisions" c
    WHERE c."motorcycle_collision" = 1
),
helmet_flag AS (
    -- decide whether a helmet was reported in any party in the crash
    SELECT
        mc."case_id",
        mc.motorcyclist_killed,
        CASE
            WHEN MAX(
                   CASE
                       WHEN lower(COALESCE(p."party_safety_equipment_1",'')) LIKE '%helmet%' 
                         OR lower(COALESCE(p."party_safety_equipment_2",'')) LIKE '%helmet%'
                       THEN 1 ELSE 0
                   END
                 ) = 1 THEN 1
            ELSE 0
        END                                 AS helmet_used
    FROM motorcycle_collisions mc
    LEFT JOIN "parties" p
           ON p."case_id" = mc."case_id"
    GROUP BY mc."case_id"
),
summary AS (
    -- aggregate by helmet usage
    SELECT
        helmet_used,
        COUNT(*)                                   AS total_collisions,
        SUM(motorcyclist_killed)                   AS total_motorcyclist_killed
    FROM helmet_flag
    GROUP BY helmet_used
)
-- final fatality rates
SELECT
    CASE WHEN helmet_used = 1 THEN 'helmet_used'
         ELSE 'no_helmet' END                    AS helmet_usage,
    ROUND(
        CAST(total_motorcyclist_killed AS FLOAT) 
        / total_collisions * 100, 4
    )                                            AS fatality_rate_percentage
FROM summary;