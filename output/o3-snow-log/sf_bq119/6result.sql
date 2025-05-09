/*---------------------------------------------------------------
  1.  Select North-Atlantic (“NA”) storms from the 2020 season.
  2.  For each storm point, compute the great-circle segment
      length to the previous point (Haversine formula, km).
  3.  Accumulate the distance travelled for every storm track.
  4.  Rank storms by their total distance and keep the 3rd longest.
  5.  Return that storm’s track showing
           – latitude / longitude
           – cumulative distance (km)
           – maximum sustained wind speed (knots)
----------------------------------------------------------------*/
WITH points AS (
    SELECT
        "sid",
        "iso_time",
        "latitude",
        "longitude",
        /*  use USA best-track winds, common for Atlantic storms  */
        "usa_wind",
        LAG("latitude")  OVER (PARTITION BY "sid" ORDER BY "iso_time") AS prev_lat,
        LAG("longitude") OVER (PARTITION BY "sid" ORDER BY "iso_time") AS prev_lon
    FROM NOAA_DATA.NOAA_HURRICANES.HURRICANES
    WHERE "basin" = 'NA'
      AND "season" = '2020'
),
segments AS (
    SELECT
        "sid",
        "iso_time",
        "latitude",
        "longitude",
        "usa_wind",
        /*  Haversine distance between consecutive fixes (km)  */
        CASE
            WHEN prev_lat IS NULL THEN 0
            ELSE
                6371 * 2 * ASIN( SQRT(
                    POWER(SIN(RADIANS(("latitude"  - prev_lat ) / 2)), 2) +
                    COS(RADIANS("latitude")) * COS(RADIANS(prev_lat)) *
                    POWER(SIN(RADIANS(("longitude" - prev_lon) / 2)), 2)
                ))
        END AS segment_km
    FROM points
),
cum_dist AS (
    SELECT
        "sid",
        "iso_time",
        "latitude",
        "longitude",
        "usa_wind",
        segment_km,
        SUM(segment_km) OVER (
            PARTITION BY "sid"
            ORDER BY "iso_time"
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS cumulative_km
    FROM segments
),
totals AS (
    SELECT
        "sid",
        MAX(cumulative_km) AS total_km
    FROM cum_dist
    GROUP BY "sid"
),
ranked AS (
    SELECT
        "sid",
        total_km,
        DENSE_RANK() OVER (ORDER BY total_km DESC NULLS LAST) AS rk
    FROM totals
),
target AS (
    SELECT "sid"
    FROM ranked
    WHERE rk = 3                --  third-longest track
)
SELECT
    c."sid",
    c."iso_time",
    c."latitude",
    c."longitude",
    ROUND(c.cumulative_km, 2)      AS cumulative_distance_km,
    c."usa_wind"                   AS max_sustained_wind_kt
FROM cum_dist      AS c
JOIN target        AS t USING ("sid")
ORDER BY c."iso_time";