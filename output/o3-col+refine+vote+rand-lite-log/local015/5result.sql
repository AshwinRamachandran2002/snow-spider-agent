WITH motorcycle_collisions AS (          -- all crashes that involved a motorcycle
    SELECT
        case_id,
        COALESCE(motorcyclist_killed_count,0) AS killed
    FROM collisions
    WHERE motorcycle_collision = 1
),

helmet_used_collisions AS (              -- crashes where at least one motor-cycle party wore a helmet
    SELECT DISTINCT mc.case_id
    FROM   motorcycle_collisions mc
    JOIN   parties p
           ON p.case_id = mc.case_id
          AND p.statewide_vehicle_type LIKE '%motorcycle%'
    WHERE  (p.party_safety_equipment_1 LIKE '%helmet%used%'
            OR p.party_safety_equipment_2 LIKE '%helmet%used%')
),

helmet_not_used_collisions AS (          -- crashes where at least one motor-cycle party did NOT wear a helmet
    SELECT DISTINCT mc.case_id
    FROM   motorcycle_collisions mc
    JOIN   parties p
           ON p.case_id = mc.case_id
          AND p.statewide_vehicle_type LIKE '%motorcycle%'
    WHERE  (p.party_safety_equipment_1 LIKE '%helmet%not used%'
            OR p.party_safety_equipment_2 LIKE '%helmet%not used%')
),

stats AS (                               -- count collisions and fatalities for each group
    SELECT
        'helmet_used'  AS group_name,
        SUM(mc.killed) AS total_killed,
        COUNT(*)       AS total_collisions
    FROM motorcycle_collisions mc
    JOIN helmet_used_collisions h ON h.case_id = mc.case_id

    UNION ALL

    SELECT
        'helmet_not_used',
        SUM(mc.killed),
        COUNT(*)
    FROM motorcycle_collisions mc
    JOIN helmet_not_used_collisions h ON h.case_id = mc.case_id
)

SELECT
    group_name,
    ROUND(100.0 * total_killed / total_collisions, 4) AS fatality_rate_percentage
FROM stats;