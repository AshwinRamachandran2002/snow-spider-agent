/*  Latest bike-share ride (2014-2017) for each region  */
WITH trips AS (   -----------------------------------------------------------------
    SELECT
        "trip_id",
        "duration_sec",
        TO_TIMESTAMP_LTZ("start_date", 6)                 AS start_ts,   -- µs → TIMESTAMP
        "start_station_id",
        "start_station_name",
        "member_gender",
        "start_station_latitude"      AS lat,
        "start_station_longitude"     AS lon
    FROM   SAN_FRANCISCO_PLUS.SAN_FRANCISCO_BIKESHARE.BIKESHARE_TRIPS
    WHERE  TO_TIMESTAMP_LTZ("start_date", 6)
           BETWEEN '2014-01-01' AND '2017-12-31 23:59:59'
),
trip_plus_station AS ( -------------------------------------------------------------
    SELECT
        t.*,
        si."region_id"
    FROM trips t
    LEFT JOIN SAN_FRANCISCO_PLUS.SAN_FRANCISCO_BIKESHARE.BIKESHARE_STATION_INFO si
           ON si."station_id" = t."start_station_id"::TEXT
),
trip_with_region AS (  -------------------------------------------------------------
    SELECT
        ps.*,
        /* 1) use region name from lookup; 2) otherwise infer by lat/lon */
        COALESCE( rg."name",
                  CASE
                      /* San Francisco bounding box */
                      WHEN lat BETWEEN 37.60 AND 37.90
                       AND lon BETWEEN -122.52 AND -122.35 THEN 'San Francisco'
                      /* Oakland bounding box */
                      WHEN lat BETWEEN 37.70 AND 37.90
                       AND lon BETWEEN -122.35 AND -122.15 THEN 'Oakland'
                      /* San Jose bounding box */
                      WHEN lat BETWEEN 37.20 AND 37.50
                       AND lon BETWEEN -122.10 AND -121.70 THEN 'San Jose'
                      ELSE NULL
                  END
        ) AS region_name
    FROM trip_plus_station ps
    LEFT JOIN SAN_FRANCISCO_PLUS.SAN_FRANCISCO_BIKESHARE.BIKESHARE_REGIONS rg
           ON rg."region_id" = ps."region_id"
    WHERE   /* keep only rows for which we could resolve a region */
        COALESCE( rg."name",
                  CASE
                      WHEN lat BETWEEN 37.60 AND 37.90 AND lon BETWEEN -122.52 AND -122.35 THEN 'San Francisco'
                      WHEN lat BETWEEN 37.70 AND 37.90 AND lon BETWEEN -122.35 AND -122.15 THEN 'Oakland'
                      WHEN lat BETWEEN 37.20 AND 37.50 AND lon BETWEEN -122.10 AND -121.70 THEN 'San Jose'
                      ELSE NULL
                  END
        ) IS NOT NULL
)
SELECT
    region_name                    AS "region_name",
    "trip_id"                      AS "trip_id",
    "duration_sec"                 AS "ride_duration_sec",
    start_ts                       AS "start_time",
    "start_station_name"           AS "starting_station",
    "member_gender"                AS "rider_gender"
FROM trip_with_region
QUALIFY ROW_NUMBER() OVER (PARTITION BY region_name
                           ORDER BY start_ts DESC NULLS LAST) = 1
ORDER BY region_name;