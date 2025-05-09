WITH points AS (   -- every 2020 North-Atlantic track point
    SELECT
        "sid",
        "iso_time",                           -- epoch µs
        "latitude",
        "longitude",
        "usa_wind",                           -- max sustained wind (kt) from HURDAT2
        RADIANS("latitude")  AS lat_rad,
        RADIANS("longitude") AS lon_rad,
        ROW_NUMBER() OVER (PARTITION BY "sid" ORDER BY "iso_time") AS pt_order
    FROM NOAA_DATA.NOAA_HURRICANES.HURRICANES
    WHERE "season" = '2020'
      AND "basin"  = 'NA'                     -- North Atlantic
      AND "track_type" = 'main'               -- main (best) track
      AND "latitude"  IS NOT NULL
      AND "longitude" IS NOT NULL
),

segments AS (      -- distance between successive points (Haversine)
    SELECT
        p.*,
        CASE
            WHEN LAG(lat_rad) OVER (PARTITION BY "sid" ORDER BY pt_order) IS NULL THEN 0
            ELSE 6371 * ACOS(                            -- great-circle km
                     LEAST( 1 ,
                       COS(LAG(lat_rad) OVER (PARTITION BY "sid" ORDER BY pt_order))
                     * COS(lat_rad)
                     * COS(lon_rad
                           - LAG(lon_rad) OVER (PARTITION BY "sid" ORDER BY pt_order))
                     + SIN(LAG(lat_rad) OVER (PARTITION BY "sid" ORDER BY pt_order))
                     * SIN(lat_rad) ) )
        END AS segment_km
    FROM points p
),

cumulative AS (     -- running total distance for each storm
    SELECT
        "sid",
        "iso_time",
        "latitude",
        "longitude",
        "usa_wind",
        pt_order,
        SUM(segment_km)
            OVER (PARTITION BY "sid"
                  ORDER BY pt_order
                  ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_km
    FROM segments
),

storm_totals AS (   -- total travel distance per storm
    SELECT "sid",
           MAX(cumulative_km) AS total_km
    FROM   cumulative
    GROUP  BY "sid"
),

third_longest AS (  -- the storm with the 3rd-longest path
    SELECT  "sid"
    FROM    storm_totals
    ORDER BY total_km DESC NULLS LAST
    OFFSET 2 ROWS FETCH NEXT 1 ROWS ONLY
)

-- final output: every track point for that storm
SELECT
    c."sid"                                            AS storm_id,
    c."iso_time",                                      -- µs since 1970-01-01
    c."latitude",
    c."longitude",
    ROUND(c.cumulative_km,2)       AS cumulative_km,   -- distance travelled so far
    c."usa_wind"                    AS max_sustained_wind_knots
FROM   cumulative  c
JOIN   third_longest t
  ON   c."sid" = t."sid"
ORDER  BY c."iso_time";