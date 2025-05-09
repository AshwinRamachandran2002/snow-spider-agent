WITH motorcycle_cases AS (             -- collisions that involve motorcycles
    SELECT case_id
    FROM collisions
    WHERE motorcycle_collision = 1
),
motorcyclist_parties AS (              -- motorcyclists in those collisions and their helmet use
    SELECT
        p.case_id,
        COALESCE(p.party_number_killed,0) AS fatalities,
        CASE
             WHEN (
                     (LOWER(COALESCE(p.party_safety_equipment_1,'')) LIKE '%helmet%'
                      AND LOWER(p.party_safety_equipment_1) NOT LIKE '%not%')
                  OR (LOWER(COALESCE(p.party_safety_equipment_2,'')) LIKE '%helmet%'
                      AND LOWER(p.party_safety_equipment_2) NOT LIKE '%not%')
                  )
             THEN 'helmet'
             ELSE 'no_helmet'
        END AS helmet_status
    FROM parties p
    JOIN motorcycle_cases mc
      ON mc.case_id = p.case_id
    WHERE LOWER(COALESCE(p.statewide_vehicle_type,'')) LIKE '%motorcycl%'  -- only motorcyclists
),
totals AS (                            -- totals by helmet status
    SELECT
        helmet_status,
        SUM(fatalities)            AS total_fatalities,
        COUNT(DISTINCT case_id)    AS total_collisions
    FROM motorcyclist_parties
    GROUP BY helmet_status
)
SELECT
    helmet_status,
    ROUND(100.0 * total_fatalities / NULLIF(total_collisions,0), 4) AS fatality_rate_percentage
FROM totals;