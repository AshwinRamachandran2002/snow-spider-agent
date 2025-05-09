WITH atlantic_2020 AS (     -- 2020 North-Atlantic hurricane fixes
    SELECT
        "sid",
        "iso_time",
        "latitude",
        "longitude",
        "usa_wind"                          AS "wind_kt"
    FROM NOAA_DATA.NOAA_HURRICANES.HURRICANES
    WHERE "season" = '2020'
      AND "basin"  = 'NA'
      AND "latitude"  IS NOT NULL
      AND "longitude" IS NOT NULL
      AND "iso_time" IS NOT NULL
),
track_with_prev AS (        -- add previous-point coordinates
    SELECT
        "sid",
        "iso_time",
        "latitude",
        "longitude",
        "wind_kt",
        LAG("latitude")  OVER (PARTITION BY "sid" ORDER BY "iso_time") AS "prev_lat",
        LAG("longitude") OVER (PARTITION BY "sid" ORDER BY "iso_time") AS "prev_lon"
    FROM atlantic_2020
),
track_segment AS (          -- segment length (km) via Haversine
    SELECT
        "sid",
        "iso_time",
        "latitude",
        "longitude",
        "wind_kt",
        COALESCE(
            2 * 6371 * ASIN(
                SQRT(
                    POWER(SIN(RADIANS("latitude"  - "prev_lat")/2),2) +
                    COS(RADIANS("latitude")) *
                    COS(RADIANS("prev_lat")) *
                    POWER(SIN(RADIANS("longitude" - "prev_lon")/2),2)
                )
            ),
            0
        ) AS "segment_km"
    FROM track_with_prev
),
track_cum AS (              -- cumulative distance per storm
    SELECT
        "sid",
        "iso_time",
        "latitude",
        "longitude",
        "wind_kt",
        "segment_km",
        SUM("segment_km") OVER (PARTITION BY "sid"
                                ORDER BY "iso_time"
                                ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS "cum_km"
    FROM track_segment
),
totals AS (                  -- total distance of each storm
    SELECT
        "sid",
        MAX("cum_km") AS "total_km"
    FROM track_cum
    GROUP BY "sid"
),
third_longest AS (           -- the 3rd-longest 2020 Atlantic storm
    SELECT "sid"
    FROM totals
    QUALIFY ROW_NUMBER() OVER (ORDER BY "total_km" DESC NULLS LAST) = 3
)
SELECT
    t."sid"                                    AS "storm_id",
    TO_TIMESTAMP_NTZ(t."iso_time"/1000000)     AS "timestamp_utc",
    t."latitude"                               AS "lat_deg",
    t."longitude"                              AS "lon_deg",
    ROUND(t."cum_km", 2)                       AS "cumulative_distance_km",
    t."wind_kt"                                AS "max_sustained_wind_kt"
FROM track_cum  t
JOIN third_longest s
  ON t."sid" = s."sid"
ORDER BY t."iso_time";