/* 1) find all 2020 North-Atlantic tracks */
WITH filtered AS (
    SELECT
        "sid",
        "iso_time",
        "latitude",
        "longitude",
        "usa_wind"
    FROM NOAA_DATA.NOAA_HURRICANES.HURRICANES
    WHERE "season" = '2020'
      AND "basin"  = 'NA'
      AND "latitude"  IS NOT NULL
      AND "longitude" IS NOT NULL
),
/* 2) compute great-circle segment distance between consecutive fixes */
distances AS (
    SELECT
        f.*,
        LAG("latitude")  OVER (PARTITION BY "sid" ORDER BY "iso_time") AS prev_lat,
        LAG("longitude") OVER (PARTITION BY "sid" ORDER BY "iso_time") AS prev_lon,
        CASE
            WHEN LAG("latitude") OVER (PARTITION BY "sid" ORDER BY "iso_time") IS NULL THEN 0
            ELSE
                2 * 6371 * ASIN(
                    SQRT(
                          POWER(SIN(RADIANS(f."latitude"  - prev_lat)/2),2)
                        + COS(RADIANS(prev_lat))
                          * COS(RADIANS(f."latitude"))
                          * POWER(SIN(RADIANS(f."longitude" - prev_lon)/2),2)
                    )
                )
        END AS segment_km
    FROM filtered f
),
/* 3) total path length per storm */
totals AS (
    SELECT
        "sid",
        SUM(segment_km) AS total_km
    FROM distances
    GROUP BY "sid"
),
/* 4) the storm with the 3rd-longest path */
third_longest AS (
    SELECT "sid"
    FROM totals
    ORDER BY total_km DESC NULLS LAST
    LIMIT 1 OFFSET 2         -- third longest
),
/* 5) cumulative travel distance for that storm */
selected AS (
    SELECT
        d."sid",
        d."iso_time",
        d."latitude",
        d."longitude",
        SUM(d.segment_km) OVER (PARTITION BY d."sid"
                                ORDER BY d."iso_time"
                                ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_km,
        d."usa_wind"
    FROM distances d
    JOIN third_longest t
      ON d."sid" = t."sid"
)
/* 6) final ordered output */
SELECT
    "sid",
    "iso_time",
    "latitude",
    "longitude",
    ROUND(cumulative_km,2)            AS "cumulative_distance_km",
    "usa_wind"                        AS "max_sustained_wind_knots"
FROM selected
ORDER BY "iso_time";