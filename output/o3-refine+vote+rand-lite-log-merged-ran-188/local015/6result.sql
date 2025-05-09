WITH motorcycle_collisions AS (
    /* Flag each crash that involves at least one motorcycle party
       as ‘helmet_used’ if ANY motorcycle party shows “helmet” in either
       safety-equipment field, otherwise ‘no_helmet’. */
    SELECT
        p."case_id",
        MAX(
            CASE
                WHEN p."party_safety_equipment_1" LIKE '%helmet%'
                   OR p."party_safety_equipment_2" LIKE '%helmet%'
                THEN 1 ELSE 0
            END
        ) AS helmet_used
    FROM "parties" AS p
    WHERE p."statewide_vehicle_type" LIKE '%motorcycle%'
    GROUP BY p."case_id"
),
collision_counts AS (
    /* How many motorcycle collisions fall in each helmet category? */
    SELECT
        CASE WHEN helmet_used = 1 THEN 'helmet_used' ELSE 'no_helmet' END AS helmet_group,
        COUNT(*) AS collisions
    FROM motorcycle_collisions
    GROUP BY helmet_used
),
fatality_counts AS (
    /* Count motorcyclist fatalities (victims with degree = 'killed') in each category. */
    SELECT
        CASE WHEN mc.helmet_used = 1 THEN 'helmet_used' ELSE 'no_helmet' END AS helmet_group,
        COUNT(*) AS fatalities
    FROM "victims"  AS v
    JOIN "parties"  AS p
         ON v."case_id" = p."case_id"
        AND v."party_number" = p."party_number"
    JOIN motorcycle_collisions AS mc
         ON mc."case_id" = v."case_id"
    WHERE p."statewide_vehicle_type" LIKE '%motorcycle%'
      AND v."victim_degree_of_injury" = 'killed'
    GROUP BY mc.helmet_used
)
SELECT
    c.helmet_group,
    ROUND(COALESCE(f.fatalities,0) * 100.0 / c.collisions, 4) AS fatality_rate_percentage
FROM collision_counts AS c
LEFT JOIN fatality_counts AS f
       ON f.helmet_group = c.helmet_group;