/* -------------------------------------------------------------
   Build a labeled accident-level data set (2016 only) containing:
     • label  : 1 if >1 persons in the crash have injury_severity = 4, else 0
     • state_number
     • body_type          (taken from the vehicle with the lowest vehicle_number)
     • number_of_drunk_drivers
     • day_of_week
     • hour_of_crash
     • work_zone_ind      (1 if work_zone ≠ 'None', else 0)
     • speed_diff_bucket  (average |travel_speed–speed_limit| per crash,
                           computed only for valid numeric speeds, then bucketed:
                             0:[0,20)  1:[20,40)  2:[40,60)  3:[60,80)  4:≥80 )
   The final data set includes only crashes that involve >1 distinct persons.
---------------------------------------------------------------- */
WITH person_agg AS (   -- persons and fatalities per crash
    SELECT  "state_number",
            "consecutive_number",
            COUNT(*)                                              AS person_cnt,
            SUM(CASE WHEN "injury_severity" = 4 THEN 1 ELSE 0 END) AS fatal_cnt
    FROM    NHTSA_TRAFFIC_FATALITIES.NHTSA_TRAFFIC_FATALITIES.PERSON_2016
    GROUP BY "state_number", "consecutive_number"
    HAVING  COUNT(*) > 1                                         -- >1 distinct person
),                                                             -- ---------------------
labelled AS (              -- derive 0/1 label from fatal_cnt
    SELECT  "state_number",
            "consecutive_number",
            CASE WHEN fatal_cnt > 1 THEN 1 ELSE 0 END           AS label
    FROM    person_agg
),                                                             -- ---------------------
vehicle_primary AS (        -- body_type from the first-listed vehicle
    SELECT  "state_number",
            "consecutive_number",
            "body_type"
    FROM   (
        SELECT  "state_number",
                "consecutive_number",
                "vehicle_number",
                "body_type",
                ROW_NUMBER() OVER (PARTITION BY "state_number","consecutive_number"
                                   ORDER BY "vehicle_number")   AS rn
        FROM    NHTSA_TRAFFIC_FATALITIES.NHTSA_TRAFFIC_FATALITIES.VEHICLE_2016
    )
    WHERE  rn = 1
),                                                             -- ---------------------
speed_stats AS (            -- avg |speed–limit| per crash (valid speeds only)
    SELECT  "state_number",
            "consecutive_number",
            AVG(ABS("travel_speed" - "speed_limit"))            AS avg_speed_diff
    FROM    NHTSA_TRAFFIC_FATALITIES.NHTSA_TRAFFIC_FATALITIES.VEHICLE_2016
    WHERE   "travel_speed" NOT IN (997,998,999)                -- exclude special codes
      AND   "speed_limit"  NOT IN (98,99)
      AND   "travel_speed" <= 151
      AND   "speed_limit"  <= 80
    GROUP BY "state_number", "consecutive_number"
),                                                             -- ---------------------
speed_bucket AS (           -- convert average difference to 0–4 bucket
    SELECT  "state_number",
            "consecutive_number",
            CASE
                WHEN avg_speed_diff IS NULL        THEN NULL
                WHEN avg_speed_diff <  20          THEN 0
                WHEN avg_speed_diff <  40          THEN 1
                WHEN avg_speed_diff <  60          THEN 2
                WHEN avg_speed_diff <  80          THEN 3
                ELSE                                   4
            END                                               AS speed_diff_bucket
    FROM    speed_stats
),                                                             -- ---------------------
accident_core AS (          -- needed predictors from the accident file
    SELECT  "state_number",
            "consecutive_number",
            "number_of_drunk_drivers",
            "day_of_week",
            "hour_of_crash",
            CASE WHEN "work_zone" <> 'None' THEN 1 ELSE 0 END  AS work_zone_ind
    FROM    NHTSA_TRAFFIC_FATALITIES.NHTSA_TRAFFIC_FATALITIES.ACCIDENT_2016
)                                                              -- ---------------------
SELECT  lbl.label,
        acc."state_number",
        vp."body_type",
        acc."number_of_drunk_drivers",
        acc."day_of_week",
        acc."hour_of_crash",
        acc.work_zone_ind,
        sb.speed_diff_bucket
FROM    labelled           lbl
JOIN    accident_core      acc ON acc."state_number"      = lbl."state_number"
                              AND acc."consecutive_number" = lbl."consecutive_number"
LEFT JOIN vehicle_primary  vp  ON vp."state_number"       = lbl."state_number"
                              AND vp."consecutive_number"  = lbl."consecutive_number"
LEFT JOIN speed_bucket     sb  ON sb."state_number"       = lbl."state_number"
                              AND sb."consecutive_number"  = lbl."consecutive_number";