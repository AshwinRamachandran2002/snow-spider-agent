WITH moto_parties AS (
    -- Identify motorcycle parties and whether a helmet is recorded in either safety-equipment field
    SELECT DISTINCT
           case_id,
           CASE
               WHEN LOWER(COALESCE(party_safety_equipment_1, '')) LIKE '%helmet%'
                 OR LOWER(COALESCE(party_safety_equipment_2, '')) LIKE '%helmet%'
               THEN 1          -- helmet used
               ELSE 0          -- no helmet recorded
           END AS helmet_flag
    FROM parties
    WHERE LOWER(statewide_vehicle_type) LIKE '%motorcycle%'
),
collision_helmet AS (
    -- Classify each collision: 1 = at least one helmeted motorcyclist, 0 = none
    SELECT
        case_id,
        MAX(helmet_flag) AS helmet_used
    FROM moto_parties
    GROUP BY case_id
),
merged AS (
    -- Attach the helmet classification to the collision record and bring in fatality count
    SELECT
        c.case_id,
        ch.helmet_used,
        COALESCE(c.motorcyclist_killed_count, 0) AS killed
    FROM collisions AS c
    JOIN collision_helmet AS ch
      ON c.case_id = ch.case_id
)
-- Calculate fatality rate = (total motorcyclist deaths) / (collisions) * 100
SELECT
    helmet_used,                              -- 1 = helmet, 0 = no helmet
    COUNT(*)                       AS collisions_in_group,
    SUM(killed)                    AS killed_total,
    ROUND(100.0 * SUM(killed) / COUNT(*), 4) AS fatality_rate_pct
FROM merged
GROUP BY helmet_used
ORDER BY helmet_used DESC;