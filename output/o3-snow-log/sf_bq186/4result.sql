WITH trip_enriched AS (
    SELECT
        TO_CHAR(TO_TIMESTAMP_NTZ("start_date" / 1000000), 'YYYYMM')                       AS "year_month",
        "start_date",
        "duration_sec"
    FROM  SAN_FRANCISCO.SAN_FRANCISCO.BIKESHARE_TRIPS
    WHERE "start_date" IS NOT NULL
), trip_stats AS (
    SELECT
        "year_month",
        /* first and last via windowed FIRST_VALUE */
        FIRST_VALUE("duration_sec") OVER (PARTITION BY "year_month" ORDER BY "start_date" ASC)
            / 60.0                                                              AS "first_trip_min",
        FIRST_VALUE("duration_sec") OVER (PARTITION BY "year_month" ORDER BY "start_date" DESC)
            / 60.0                                                              AS "last_trip_min",
        /* high / low via windowed aggregations */
        MAX("duration_sec")  OVER (PARTITION BY "year_month") / 60.0             AS "max_trip_min",
        MIN("duration_sec")  OVER (PARTITION BY "year_month") / 60.0             AS "min_trip_min"
    FROM trip_enriched
)
SELECT
    "year_month",
    MIN("first_trip_min")   AS "first_trip_min",
    MIN("last_trip_min")    AS "last_trip_min",
    MAX("max_trip_min")     AS "max_trip_min",
    MIN("min_trip_min")     AS "min_trip_min"
FROM trip_stats
GROUP BY "year_month"
ORDER BY "year_month";