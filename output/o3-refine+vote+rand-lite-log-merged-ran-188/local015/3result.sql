WITH motorcycle_parties AS (
    SELECT
        case_id,
        party_number_killed AS fatalities,
        CASE
            WHEN (party_safety_equipment_1 LIKE '%helmet%' 
                  OR party_safety_equipment_2 LIKE '%helmet%')
            THEN 1 ELSE 0
        END AS helmet_used
    FROM parties
    WHERE statewide_vehicle_type LIKE '%motorcycle%'
)
SELECT
    ROUND(
        100.0 * (SELECT IFNULL(SUM(fatalities),0) 
                 FROM   motorcycle_parties 
                 WHERE  helmet_used = 1) /
        (SELECT COUNT(DISTINCT case_id) 
         FROM   motorcycle_parties 
         WHERE  helmet_used = 1), 4
    ) AS fatality_rate_helmet_pct,
    ROUND(
        100.0 * (SELECT IFNULL(SUM(fatalities),0) 
                 FROM   motorcycle_parties 
                 WHERE  helmet_used = 0) /
        (SELECT COUNT(DISTINCT case_id) 
         FROM   motorcycle_parties 
         WHERE  helmet_used = 0), 4
    ) AS fatality_rate_no_helmet_pct;