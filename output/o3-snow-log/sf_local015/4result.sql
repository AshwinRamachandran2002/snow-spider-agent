WITH motorcycle_parties AS (
    SELECT
        p."case_id",
        p."party_number_killed"                                            AS "fatalities",
        CASE
            WHEN (p."party_safety_equipment_1" ILIKE '%helmet used%' 
               OR  p."party_safety_equipment_2" ILIKE '%helmet used%')
                 THEN 'Helmet_Used'
            ELSE 'No_Helmet'
        END                                                               AS "helmet_group"
    FROM  "CALIFORNIA_TRAFFIC_COLLISION"."CALIFORNIA_TRAFFIC_COLLISION"."PARTIES"    p
    JOIN  "CALIFORNIA_TRAFFIC_COLLISION"."CALIFORNIA_TRAFFIC_COLLISION"."COLLISIONS" c
          ON p."case_id" = c."case_id"
    WHERE c."motorcycle_collision" = 1
      AND p."statewide_vehicle_type" ILIKE '%motorcycle%'
),
agg AS (
    SELECT
        "helmet_group",
        SUM("fatalities")                    AS "fatalities",
        COUNT(DISTINCT "case_id")            AS "collisions"
    FROM motorcycle_parties
    GROUP BY "helmet_group"
)
SELECT
    "helmet_group",
    "fatalities",
    "collisions",
    ROUND( ("fatalities" / NULLIF("collisions",0)) * 100 , 4)  AS "fatality_rate_percent"
FROM agg
ORDER BY "helmet_group";