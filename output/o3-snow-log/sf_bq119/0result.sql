WITH atlantic_2020 AS (          -- 1. points for North-Atlantic season 2020
    SELECT
        "sid",
        "iso_time",
        "latitude",
        "longitude",
        "usa_wind"                      -- 1-min sustained wind (knots)
    FROM NOAA_DATA.NOAA_HURRICANES.HURRICANES
    WHERE "basin" = 'NA'
      AND "season" = '2020'
      AND "track_type" = 'main'        -- main best-track positions only
      AND "latitude" IS NOT NULL
      AND "longitude" IS NOT NULL
), track_segments AS (                 -- 2. distance between successive points
    SELECT
        a.*,
        ST_DISTANCE(                   -- metres -> divide by 1000 for km
            TO_GEOGRAPHY('POINT('||"longitude"||' '||"latitude"||')'),
            TO_GEOGRAPHY('POINT('||
                         LAG("longitude") OVER (PARTITION BY "sid"
                                                ORDER BY "iso_time")||' '||
                         LAG("latitude")  OVER (PARTITION BY "sid"
                                                ORDER BY "iso_time")||')')
        )/1000        AS segment_km
    FROM atlantic_2020 a
), cumulative_track AS (               -- 3. cumulative distance along the track
    SELECT
        "sid",
        "iso_time",
        "latitude",
        "longitude",
        "usa_wind",
        COALESCE(segment_km,0)                  AS segment_km,
        SUM(COALESCE(segment_km,0))
          OVER (PARTITION BY "sid"
                ORDER BY "iso_time"
                ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cum_km
    FROM track_segments
), storm_totals AS (                   -- 4. total path length for each storm
    SELECT
        "sid",
        MAX(cum_km) AS total_km
    FROM cumulative_track
    GROUP BY "sid"
), third_longest AS (                  -- 5. pick the storm ranked 3rd longest
    SELECT "sid"
    FROM (
        SELECT
            "sid",
            total_km,
            DENSE_RANK() OVER (ORDER BY total_km DESC NULLS LAST) AS rnk
        FROM storm_totals
    )
    WHERE rnk = 3
)
-- 6. final output: every position of the selected storm
SELECT
    c."sid"                                           AS storm_id,
    TO_TIMESTAMP(c."iso_time"/1e6)                    AS position_time,
    c."latitude",
    c."longitude",
    ROUND(c.cum_km,2)                                 AS cumulative_distance_km,
    c."usa_wind"                                      AS max_sustained_wind_knots
FROM cumulative_track  c
JOIN third_longest      t  ON c."sid" = t."sid"
ORDER BY c."iso_time";