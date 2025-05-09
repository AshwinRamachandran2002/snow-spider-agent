/* ------------------------------------------------------------
   Build a crash-level modelling file (year 2016 only)
   label  = 1  →  >1 persons fatally injured (injury_severity = 4)
           0  →  otherwise
   Keep only crashes that involve more than one distinct person.
-------------------------------------------------------------*/
WITH person_agg AS (        /* persons per crash + fatal counts */
    SELECT
        "consecutive_number",
        COUNT(DISTINCT "person_number")                                          AS person_cnt,
        SUM(CASE WHEN "injury_severity" = 4 THEN 1 ELSE 0 END)                  AS fatal_cnt
    FROM
        NHTSA_TRAFFIC_FATALITIES.NHTSA_TRAFFIC_FATALITIES.PERSON_2016
    GROUP BY
        "consecutive_number"
    HAVING
        COUNT(DISTINCT "person_number") > 1                                      -- >1 person in crash
),
labelled AS (               /* derive binary label */
    SELECT
        "consecutive_number",
        CASE WHEN fatal_cnt > 1 THEN 1 ELSE 0 END                               AS label
    FROM person_agg
),
/* ----------  vehicle–level engineering ------------------------------------ */
vehicle_valid AS (          /* keep rows with usable speed & limit values   */
    SELECT
        "consecutive_number",
        "body_type",
        ABS("travel_speed" - "speed_limit")                                     AS speed_diff
    FROM
        NHTSA_TRAFFIC_FATALITIES.NHTSA_TRAFFIC_FATALITIES.VEHICLE_2016
    WHERE
        "travel_speed" BETWEEN 0 AND 151                      -- exclude codes 997-999, 152+
        AND "speed_limit" BETWEEN 0 AND 80                    -- exclude 98/99, 81+
),
vehicle_agg AS (            /* average diff & representative body_type      */
    SELECT
        "consecutive_number",
        MIN("body_type")                                       AS body_type,    -- representative
        AVG(speed_diff)                                        AS avg_speed_diff
    FROM vehicle_valid
    GROUP BY "consecutive_number"
),
vehicle_feat AS (           /* bucketise average speed difference           */
    SELECT
        "consecutive_number",
        body_type,
        CASE
            WHEN avg_speed_diff IS NULL THEN NULL
            ELSE LEAST(FLOOR(avg_speed_diff/20), 4)
        END                                                   AS speed_diff_level
    FROM vehicle_agg
),
/* ----------  accident-level core predictors ------------------------------ */
accident_base AS (
    SELECT
        "consecutive_number",
        "state_number",
        "number_of_drunk_drivers",
        "day_of_week",
        "hour_of_crash",
        CASE WHEN "work_zone" = 'None' THEN 0 ELSE 1 END      AS work_zone_flag
    FROM
        NHTSA_TRAFFIC_FATALITIES.NHTSA_TRAFFIC_FATALITIES.ACCIDENT_2016
)
/* ----------  final crash-level dataset ----------------------------------- */
SELECT
    l.label,
    a."state_number",
    v.body_type,
    a."number_of_drunk_drivers",
    a."day_of_week",
    a."hour_of_crash",
    a.work_zone_flag,
    v.speed_diff_level
FROM
    labelled         l
JOIN
    accident_base    a  USING ("consecutive_number")
LEFT JOIN
    vehicle_feat     v  USING ("consecutive_number");