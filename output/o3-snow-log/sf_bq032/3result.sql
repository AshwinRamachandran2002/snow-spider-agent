WITH base AS (  -- 2020 North-Atlantic hurricane track points
    SELECT
        "sid",
        "iso_time",
        "latitude",
        "longitude"
    FROM NOAA_DATA.NOAA_HURRICANES.HURRICANES
    WHERE "season" = '2020'
      AND "basin"  = 'NA'
      AND "latitude"  IS NOT NULL
      AND "longitude" IS NOT NULL
      AND "iso_time"  IS NOT NULL
),
seg AS (        -- distance (m) between successive points for each storm
    SELECT
        "sid",
        ST_DISTANCE(
            ST_POINT("longitude","latitude"),
            ST_POINT(
                LAG("longitude") OVER (PARTITION BY "sid" ORDER BY "iso_time"),
                LAG("latitude")  OVER (PARTITION BY "sid" ORDER BY "iso_time")
            )
        ) AS seg_m
    FROM base
),
tot_dist AS (   -- total distance (km) travelled by each storm
    SELECT
        "sid",
        SUM(COALESCE(seg_m,0))/1000 AS total_km
    FROM seg
    GROUP BY "sid"
),
second_longest AS (  -- storm with the 2nd-longest track
    SELECT "sid"
    FROM (
        SELECT
            "sid",
            total_km,
            ROW_NUMBER() OVER (ORDER BY total_km DESC NULLS LAST) AS rk
        FROM tot_dist
    )
    WHERE rk = 2
),
final_point AS (     -- last reported point for that storm
    SELECT
        b."latitude",
        ROW_NUMBER() OVER (ORDER BY b."iso_time" DESC) AS rn
    FROM base b
    JOIN second_longest s
      ON b."sid" = s."sid"
)
SELECT "latitude"
FROM   final_point
WHERE  rn = 1;