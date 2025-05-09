WITH moto_parties AS (
    SELECT
        case_id,
        CASE
            WHEN party_safety_equipment_1 LIKE '%helmet not used%' 
              OR party_safety_equipment_2 LIKE '%helmet not used%' 
              THEN 'not_used'
            WHEN party_safety_equipment_1 LIKE '%helmet used%' 
              OR party_safety_equipment_2 LIKE '%helmet used%' 
              THEN 'used'
            ELSE NULL
        END AS helmet_status
    FROM parties
    WHERE statewide_vehicle_type LIKE '%motorcycle%'
),
used_cases AS (                        -- collisions with at least one helmeted motorcyclist
    SELECT DISTINCT case_id
    FROM moto_parties
    WHERE helmet_status = 'used'
),
not_used_cases AS (                    -- collisions with at least one un‑helmeted motorcyclist
    SELECT DISTINCT case_id
    FROM moto_parties
    WHERE helmet_status = 'not_used'
),
rates AS (
    SELECT
        'helmet_used'  AS helmet_usage,
        ROUND(SUM(c.motorcyclist_killed_count) * 100.0 /
              COUNT(DISTINCT c.case_id), 4) AS fatality_rate_percent
    FROM collisions AS c
    JOIN used_cases  AS u ON u.case_id = c.case_id
    WHERE c.motorcycle_collision = 1
    
    UNION ALL
    
    SELECT
        'helmet_not_used'  AS helmet_usage,
        ROUND(SUM(c.motorcyclist_killed_count) * 100.0 /
              COUNT(DISTINCT c.case_id), 4) AS fatality_rate_percent
    FROM collisions AS c
    JOIN not_used_cases AS n ON n.case_id = c.case_id
    WHERE c.motorcycle_collision = 1
)
SELECT helmet_usage, fatality_rate_percent
FROM rates
ORDER BY helmet_usage;