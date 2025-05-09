WITH filtered AS (       -- only 2020 North-Atlantic hurricane fixes having coordinates & time
    SELECT
        "sid",
        "iso_time",
        "latitude",
        "longitude"
    FROM NOAA_DATA.NOAA_HURRICANES.HURRICANES
    WHERE "season" = '2020'
      AND "basin"  = 'NA'          -- North Atlantic basin
      AND "latitude"  IS NOT NULL
      AND "longitude" IS NOT NULL
      AND "iso_time"  IS NOT NULL
),

ordered AS (              -- successive points for every storm
    SELECT
        *,
        LAG("latitude")  OVER (PARTITION BY "sid" ORDER BY "iso_time")  AS prev_lat,
        LAG("longitude") OVER (PARTITION BY "sid" ORDER BY "iso_time")  AS prev_lon
    FROM filtered
),

distance AS (             -- segment distance (km) using haversine formula
    SELECT
        "sid",
        "iso_time",
        "latitude",
        "longitude",
        CASE
            WHEN prev_lat IS NULL THEN 0
            ELSE 6371 * 2 * ASIN(
                     SQRT(
                         POWER(SIN(RADIANS("latitude"  - prev_lat)/2),2) +
                         COS(RADIANS(prev_lat)) * COS(RADIANS("latitude")) *
                         POWER(SIN(RADIANS("longitude" - prev_lon)/2),2)
                     )
                 )
        END AS segment_km
    FROM ordered
),

totals AS (                -- total path length per storm
    SELECT
        "sid",
        SUM(segment_km) AS total_km
    FROM distance
    GROUP BY "sid"
),

ranked AS (                -- rank storms by travelled distance
    SELECT
        "sid",
        total_km,
        ROW_NUMBER() OVER (ORDER BY total_km DESC NULLS LAST) AS rnk
    FROM totals
),

second_sid AS (            -- the storm with the 2nd-longest track
    SELECT "sid"
    FROM ranked
    WHERE rnk = 2
),

final_point AS (           -- final (last) fix of that storm
    SELECT
        "latitude"
    FROM filtered
    WHERE "sid" IN (SELECT "sid" FROM second_sid)
    QUALIFY ROW_NUMBER() OVER (PARTITION BY "sid" ORDER BY "iso_time" DESC) = 1
)

SELECT "latitude"
FROM final_point;