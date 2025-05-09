/* -----------------------------------------------------------------------
   Average Citi-Bike trips on rainy vs. non-rainy 2016 days in NYC.
   ‑ Pick the single closest GHCN station within 50 km of (40.7128-74.0060)
     that has un-flagged 2016 precipitation data.
   ‑ A day is “rainy” when precipitation > 5 mm (raw value/10 > 5).
   ---------------------------------------------------------------------*/
WITH ----------------------------------------------------------------------------
/* 1.  Compute great-circle distance (km) of every GHCN station to NYC */
station_dist AS (
    SELECT
        s."id",
        s."name",
        s."latitude",
        s."longitude",
        /* Haversine formula (Earth radius ≈ 6 371 km) */
        6371 * 2 * ASIN(
            SQRT(
                POWER(SIN(RADIANS(s."latitude"  - 40.7128) / 2), 2) +
                COS(RADIANS(40.7128)) * COS(RADIANS(s."latitude")) *
                POWER(SIN(RADIANS(s."longitude" + 74.0060) / 2), 2)
            )
        )                                        AS "dist_km"
    FROM NEW_YORK_GHCN.GHCN_D.GHCND_STATIONS s
    WHERE s."latitude"  IS NOT NULL
      AND s."longitude" IS NOT NULL
), ------------------------------------------------------------------------------
/* 2.  Among stations ≤50 km away, keep only those that actually have
       valid (un-flagged) 2016 precipitation measurements */
stations_with_data AS (
    SELECT DISTINCT
           d."id",
           sd."dist_km"
    FROM station_dist sd
    JOIN NEW_YORK_GHCN.GHCN_D.GHCND_2016 d
         ON d."id" = sd."id"
        AND d."element" = 'PRCP'
        AND d."qflag"  IS NULL
    WHERE sd."dist_km" <= 50
), ------------------------------------------------------------------------------
/* 3.  Pick the single nearest qualifying station */
nearest_station AS (
    SELECT "id"
    FROM   stations_with_data
    ORDER  BY "dist_km"
    LIMIT  1
), ------------------------------------------------------------------------------
/* 4.  Daily precipitation for that station, with rainy-day flag */
precip_2016 AS (
    SELECT
        d."date"                                   AS "trip_date",
        d."value" / 10.0                           AS "prcp_mm",
        CASE WHEN d."value" / 10.0 > 5 THEN 1 ELSE 0 END AS "is_rainy"
    FROM NEW_YORK_GHCN.GHCN_D.GHCND_2016 d
    JOIN nearest_station ns ON ns."id" = d."id"
    WHERE d."element" = 'PRCP'
      AND d."qflag"  IS NULL
), ------------------------------------------------------------------------------
/* 5.  Daily Citi-Bike trip counts (start-times are micro-second epoch) */
trips_2016 AS (
    SELECT
        TO_DATE( TO_TIMESTAMP_NTZ("starttime" / 1000000) ) AS "trip_date",
        COUNT(*)                                           AS "trips"
    FROM NEW_YORK_GHCN.NEW_YORK.CITIBIKE_TRIPS
    /* 2016-01-01 00:00:00  to  2017-01-01 00:00:00 UTC  */
    WHERE "starttime" BETWEEN 1451606400000000 AND 1483228800000000
    GROUP BY 1
), ------------------------------------------------------------------------------
/* 6.  Join trips to weather */
daily_join AS (
    SELECT
        t."trip_date",
        t."trips",
        p."is_rainy"
    FROM trips_2016  t
    JOIN precip_2016 p ON p."trip_date" = t."trip_date"
) ------------------------------------------------------------------------------
/* 7.  Final comparison */
SELECT
    CASE WHEN "is_rainy" = 1 THEN 'Rainy' ELSE 'Non-Rainy' END AS "day_type",
    AVG("trips")                                              AS "avg_daily_trips"
FROM daily_join
GROUP BY "is_rainy"
ORDER BY "day_type";