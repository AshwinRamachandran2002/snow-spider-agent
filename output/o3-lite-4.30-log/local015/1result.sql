WITH motorcyclist AS (
    SELECT
        "case_id",
        COALESCE("party_number_killed", 0) AS deaths,
        CASE
            WHEN lower(COALESCE("party_safety_equipment_1", '')) LIKE '%helmet used%'
              OR lower(COALESCE("party_safety_equipment_2", '')) LIKE '%helmet used%'
            THEN 'helmet'
            ELSE 'no_helmet'
        END AS helmet_usage
    FROM "parties"
    WHERE lower("statewide_vehicle_type") LIKE '%motorcycle%'
),
stats AS (
    SELECT
        helmet_usage,
        SUM(deaths) AS total_deaths,
        COUNT(DISTINCT "case_id") AS total_collisions
    FROM motorcyclist
    GROUP BY helmet_usage
)
SELECT
    helmet_usage,
    ROUND(total_deaths * 100.0 / total_collisions, 4) AS fatality_rate_percent
FROM stats
ORDER BY helmet_usage;