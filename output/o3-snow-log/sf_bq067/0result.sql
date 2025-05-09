/*---------------------------------------------------------------
  Labeled crash-level dataset for 2016 FARS records – corrected
----------------------------------------------------------------*/
WITH person_agg AS (             /* persons & fatalities per crash */
    SELECT
        "state_number",
        "consecutive_number",
        COUNT(DISTINCT "person_number")                              AS person_cnt,
        SUM(CASE WHEN "injury_severity" = 4 THEN 1 ELSE 0 END)      AS fatal_cnt
    FROM NHTSA_TRAFFIC_FATALITIES.NHTSA_TRAFFIC_FATALITIES."PERSON_2016"
    GROUP BY "state_number", "consecutive_number"
),
vehicle_agg AS (                 /* representative body type & avg |speed-limit| */
    SELECT
        "state_number",
        "consecutive_number",
        MIN("body_type")                                            AS body_type,   -- choose a body type deterministically
        AVG(
            CASE
                WHEN "travel_speed" < 997          /* exclude 997-999 codes            */
                 AND "travel_speed" <= 151         /* keep speeds ≤151 mph             */
                 AND "speed_limit"  < 98           /* exclude 98-99 special codes      */
                 AND "speed_limit"  <= 80
                THEN ABS("travel_speed" - "speed_limit")
            END
        )                                                           AS avg_speed_diff
    FROM NHTSA_TRAFFIC_FATALITIES.NHTSA_TRAFFIC_FATALITIES."VEHICLE_2016"
    GROUP BY "state_number", "consecutive_number"
),
speed_bucket AS (                /* bucketize avg speed difference */
    SELECT
        "state_number",
        "consecutive_number",
        body_type,
        CASE
            WHEN avg_speed_diff IS NULL THEN NULL
            WHEN avg_speed_diff < 20  THEN 0
            WHEN avg_speed_diff < 40  THEN 1
            WHEN avg_speed_diff < 60  THEN 2
            WHEN avg_speed_diff < 80  THEN 3
            ELSE                          4
        END                                                         AS speed_diff_cat
    FROM vehicle_agg
),
accident_base AS (               /* crash-level predictors */
    SELECT
        "state_number",
        "consecutive_number",
        "number_of_drunk_drivers",
        "day_of_week",
        "hour_of_crash",
        CASE WHEN "work_zone" <> 'None' THEN 1 ELSE 0 END           AS work_zone_ind
    FROM NHTSA_TRAFFIC_FATALITIES.NHTSA_TRAFFIC_FATALITIES."ACCIDENT_2016"
)
SELECT
    ab."state_number",
    sb.body_type,
    ab."number_of_drunk_drivers",
    ab."day_of_week",
    ab."hour_of_crash",
    ab.work_zone_ind,
    sb.speed_diff_cat,
    CASE WHEN pa.fatal_cnt > 1 THEN 1 ELSE 0 END                    AS label
FROM accident_base  ab
JOIN person_agg     pa ON ab."state_number"      = pa."state_number"
                     AND ab."consecutive_number" = pa."consecutive_number"
LEFT JOIN speed_bucket sb ON ab."state_number"   = sb."state_number"
                         AND ab."consecutive_number" = sb."consecutive_number"
WHERE pa.person_cnt > 1;     /* keep only crashes involving >1 person */