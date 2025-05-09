WITH motorcycle_parties AS (
    /* Select every motorcycle‑involved party together with helmet usage info */
    SELECT
        p.case_id,
        COALESCE(p.party_number_killed,0)                                                          AS killed,
        CASE
            /* Any mention of “helmet” without “not” = helmet worn */
            WHEN (LOWER(p.party_safety_equipment_1) LIKE '%helmet%' AND
                  LOWER(p.party_safety_equipment_1) NOT LIKE '%not%')
              OR (LOWER(p.party_safety_equipment_2) LIKE '%helmet%' AND
                  LOWER(p.party_safety_equipment_2) NOT LIKE '%not%')
            THEN 'helmet_used'
            ELSE 'helmet_not_used'
        END                                                                                        AS helmet_group
    FROM parties     p
    JOIN collisions  c  ON c.case_id = p.case_id
    /* keep only motorcycle collisions & motorcycle parties */
    WHERE c.motorcycle_collision = 1
      AND LOWER(p.statewide_vehicle_type) LIKE '%motorcycle%'
),
group_totals AS (
    /* Aggregate fatalities and collisions for each helmet group */
    SELECT
        helmet_group,
        SUM(killed)                    AS total_fatalities,
        COUNT(DISTINCT case_id)        AS total_collisions
    FROM motorcycle_parties
    GROUP BY helmet_group
)
SELECT
    helmet_group,
    ROUND(100.0 * total_fatalities / total_collisions, 4) AS fatality_rate_percent
FROM group_totals
ORDER BY helmet_group;