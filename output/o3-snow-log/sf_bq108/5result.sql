WITH jan_aug_crashes AS (          -- all Jan-Aug 2015 crashes with >1 distinct person
    SELECT 
        "state_number",
        "consecutive_number"
    FROM NHTSA_TRAFFIC_FATALITIES.NHTSA_TRAFFIC_FATALITIES.PERSON_2015
    WHERE "month_of_crash" BETWEEN 1 AND 8
    GROUP BY 
        "state_number",
        "consecutive_number"
    HAVING COUNT(DISTINCT "person_number") > 1
),
jan_aug_severe_crashes AS (        -- of the above, those with >1 person having severity = 4
    SELECT 
        "state_number",
        "consecutive_number"
    FROM NHTSA_TRAFFIC_FATALITIES.NHTSA_TRAFFIC_FATALITIES.PERSON_2015
    WHERE "month_of_crash" BETWEEN 1 AND 8
    GROUP BY 
        "state_number",
        "consecutive_number"
    HAVING COUNT(DISTINCT "person_number") > 1
       AND SUM(CASE WHEN "injury_severity" = 4 THEN 1 ELSE 0 END) > 1
)
SELECT 
    COUNT(*)                                                     AS "crashes_gt1_severe",
    ROUND( (COUNT(*) * 100.0) / NULLIF((SELECT COUNT(*) FROM jan_aug_crashes),0)
         , 4)                                                    AS "percent_with_gt1_severe"
FROM jan_aug_severe_crashes;