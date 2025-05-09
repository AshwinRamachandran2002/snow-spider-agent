WITH motorcycle_helmet AS (
    /* 1.  Summarise each collision (case_id) on motorcycle presence
           and whether any motorcycle party was / was not wearing a helmet  */
    SELECT
        case_id,

        /* Was there any motorcycle in this collision? */
        MAX( CASE 
                WHEN LOWER(statewide_vehicle_type) LIKE '%motorcycle%'
                THEN 1 ELSE 0 END )                                  AS has_motorcycle,

        /* Any motorcycle party NOT wearing a helmet? */
        MAX( CASE 
                WHEN LOWER(statewide_vehicle_type) LIKE '%motorcycle%'
                 AND ( (LOWER(COALESCE(party_safety_equipment_1,'')) LIKE '%helmet%'
                        AND LOWER(party_safety_equipment_1) LIKE '%not%')
                    OR (LOWER(COALESCE(party_safety_equipment_2,'')) LIKE '%helmet%'
                        AND LOWER(party_safety_equipment_2) LIKE '%not%') )
                THEN 1 ELSE 0 END )                                  AS no_helmet_flag,

        /* Any motorcycle party wearing a helmet (and not flagged “not”)   */
        MAX( CASE 
                WHEN LOWER(statewide_vehicle_type) LIKE '%motorcycle%'
                 AND ( (LOWER(COALESCE(party_safety_equipment_1,'')) LIKE '%helmet%'
                        AND LOWER(party_safety_equipment_1) NOT LIKE '%not%')
                    OR (LOWER(COALESCE(party_safety_equipment_2,'')) LIKE '%helmet%'
                        AND LOWER(party_safety_equipment_2) NOT LIKE '%not%') )
                THEN 1 ELSE 0 END )                                  AS helmet_flag
    FROM parties
    GROUP BY case_id
),

classified AS (
    /* 2.  Give each motorcycle collision its helmet‑usage category          */
    SELECT
        case_id,
        CASE
            WHEN no_helmet_flag = 1            THEN 'no helmet'
            WHEN helmet_flag   = 1             THEN 'helmet'
            ELSE NULL                               -- unknown / not classifiable
        END AS helmet_usage
    FROM motorcycle_helmet
    WHERE has_motorcycle = 1           -- keep only motorcycle collisions
)

/* 3.  Join to collisions table, aggregate fatalities & collisions,
       and compute fatality rate (percentage) for each helmet group         */
SELECT
    helmet_usage,
    ROUND( 100.0 * SUM( COALESCE(c.motorcyclist_killed_count,0) )
           / COUNT(DISTINCT c.case_id), 4 )  AS fatality_rate_percentage
FROM collisions AS c
JOIN classified  AS m
      ON c.case_id = m.case_id
WHERE m.helmet_usage IS NOT NULL            -- ignore unclassified
GROUP BY helmet_usage
ORDER BY helmet_usage;