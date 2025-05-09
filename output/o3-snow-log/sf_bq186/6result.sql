WITH trips AS (
    /* add year-month key and convert trip duration to minutes */
    SELECT
        TO_CHAR(TO_TIMESTAMP_LTZ("start_date" / 1000000), 'YYYYMM')         AS "YEAR_MONTH",
        "start_date"                                                       AS "START_DATE",
        "duration_sec" / 60.0                                              AS "DURATION_MIN"
    FROM  SAN_FRANCISCO.SAN_FRANCISCO.BIKESHARE_TRIPS
),
stats AS (
    /* get first, last, highest and lowest trip duration (in minutes) per year-month */
    SELECT
        "YEAR_MONTH",
        FIRST_VALUE("DURATION_MIN")
            OVER (PARTITION BY "YEAR_MONTH"
                  ORDER BY "START_DATE" ASC
                  ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING)  AS "FIRST_TRIP_DURATION_MIN",
        FIRST_VALUE("DURATION_MIN")
            OVER (PARTITION BY "YEAR_MONTH"
                  ORDER BY "START_DATE" DESC
                  ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING)  AS "LAST_TRIP_DURATION_MIN",
        MAX("DURATION_MIN") OVER (PARTITION BY "YEAR_MONTH")                 AS "HIGHEST_TRIP_DURATION_MIN",
        MIN("DURATION_MIN") OVER (PARTITION BY "YEAR_MONTH")                 AS "LOWEST_TRIP_DURATION_MIN"
    FROM trips
)
SELECT DISTINCT
       "YEAR_MONTH",
       "FIRST_TRIP_DURATION_MIN",
       "LAST_TRIP_DURATION_MIN",
       "HIGHEST_TRIP_DURATION_MIN",
       "LOWEST_TRIP_DURATION_MIN"
FROM   stats
ORDER  BY "YEAR_MONTH";