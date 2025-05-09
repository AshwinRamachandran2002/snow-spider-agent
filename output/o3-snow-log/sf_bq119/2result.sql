/* 3rd-longest-track North-Atlantic hurricane in 2020
   with cumulative travel distance (km) and wind speed               */

WITH na2020 AS (             -- 1. 2020 North-Atlantic storm fixes
    SELECT
        "sid",
        "iso_time",          -- micro-seconds UTC
        "latitude",
        "longitude",
        "usa_wind"           -- sustained wind (kt)
    FROM NOAA_DATA.NOAA_HURRICANES.HURRICANES
    WHERE "season" = '2020'
      AND "basin"  = 'NA'
      AND "latitude"  IS NOT NULL
      AND "longitude" IS NOT NULL
),

distances AS (                -- 2. great-circle segment length (km)
    SELECT
        n."sid",
        n."iso_time",
        n."latitude",
        n."longitude",
        n."usa_wind",
        ST_DISTANCE(
            ST_POINT(n."longitude", n."latitude"),
            ST_POINT(
                LEAD(n."longitude") OVER (PARTITION BY n."sid"
                                          ORDER BY n."iso_time"),
                LEAD(n."latitude")  OVER (PARTITION BY n."sid"
                                          ORDER BY n."iso_time")
            )
        ) / 1000        AS segment_km          -- metres → km
    FROM na2020 n
),

storm_ranks AS (              -- 3. rank storms by total track length
    SELECT
        "sid",
        SUM(segment_km) AS total_km,
        ROW_NUMBER() OVER (ORDER BY SUM(segment_km) DESC NULLS LAST) AS rnk
    FROM distances
    GROUP BY "sid"
),

target AS (                   -- 4. fixes for the 3rd-longest storm
    SELECT d.*,
           SUM(COALESCE(d.segment_km,0))
               OVER (PARTITION BY d."sid"
                     ORDER BY d."iso_time")    AS cumulative_km
    FROM distances d
    JOIN storm_ranks s
      ON d."sid" = s."sid"
     AND s.rnk   = 3
)

-- 5. final output -----------------------------------------------------
SELECT
    "sid"                                       AS storm_id,
    TO_TIMESTAMP_NTZ("iso_time"/1000000)        AS obs_time,
    "latitude",
    "longitude",
    ROUND(cumulative_km,2)                      AS cumulative_distance_km,
    "usa_wind"                                  AS sustained_wind_knots
FROM target
ORDER BY obs_time;