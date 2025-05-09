WITH moto_parties AS (
    SELECT
        case_id,
        party_number_killed AS fatalities,
        CASE
            WHEN (party_safety_equipment_1 LIKE '%helmet%not used%' 
                  OR party_safety_equipment_2 LIKE '%helmet%not used%')
            THEN 'no_helmet'
            WHEN (party_safety_equipment_1 LIKE '%helmet%used%' 
                  OR party_safety_equipment_2 LIKE '%helmet%used%')
            THEN 'helmet'
            ELSE NULL
        END AS helmet_usage
    FROM parties
    WHERE statewide_vehicle_type LIKE '%motorcycle%'
),
filtered AS (
    SELECT *
    FROM moto_parties
    WHERE helmet_usage IS NOT NULL
),
agg AS (
    SELECT
        helmet_usage,
        SUM(fatalities)        AS total_fatalities,
        COUNT(DISTINCT case_id) AS total_collisions
    FROM filtered
    GROUP BY helmet_usage
)
SELECT
    helmet_usage,
    ROUND(100.0 * total_fatalities / total_collisions, 4) AS fatality_rate_percent
FROM agg
ORDER BY helmet_usage;