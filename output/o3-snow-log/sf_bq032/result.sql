WITH atlantic_2020 AS (         -- 1. 2020 North-Atlantic track points
    SELECT
        "sid",
        "iso_time",
        "latitude",
        "longitude",
        TO_GEOGRAPHY('POINT(' || "longitude" || ' ' || "latitude" || ')') AS geom
    FROM NOAA_DATA.NOAA_HURRICANES.HURRICANES
    WHERE "basin"  = 'NA'
      AND "season" = '2020'
      AND "latitude"  IS NOT NULL
      AND "longitude" IS NOT NULL
      AND "iso_time" IS NOT NULL
), 
segment_distances AS (          -- 2. distance between successive points
    SELECT
        "sid",
        "iso_time",
        "latitude",
        "longitude",
        CASE
            WHEN LAG("latitude")  OVER (PARTITION BY "sid" ORDER BY "iso_time") IS NULL
                 OR LAG("longitude") OVER (PARTITION BY "sid" ORDER BY "iso_time") IS NULL
            THEN 0
            ELSE ST_DISTANCE(
                     geom,
                     TO_GEOGRAPHY(
                       'POINT(' ||
                       LAG("longitude") OVER (PARTITION BY "sid" ORDER BY "iso_time") || ' ' ||
                       LAG("latitude")  OVER (PARTITION BY "sid" ORDER BY "iso_time") || ')'
                     )
                 )
        END AS segment_m
    FROM atlantic_2020
), 
storm_totals AS (               -- 3. total kilometres per storm
    SELECT
        "sid",
        SUM(segment_m)/1000 AS total_km
    FROM segment_distances
    GROUP BY "sid"
), 
ranked_storms AS (              -- 4. rank by distance
    SELECT
        "sid",
        total_km,
        ROW_NUMBER() OVER (ORDER BY total_km DESC NULLS LAST) AS rn
    FROM storm_totals
), 
second_longest_sid AS (         -- 5. SID of 2nd-longest storm
    SELECT "sid"
    FROM   ranked_storms
    WHERE  rn = 2
), 
final_point AS (                -- 6. final (latest) point of that storm
    SELECT
        "latitude"
    FROM   atlantic_2020
    WHERE  "sid" IN (SELECT "sid" FROM second_longest_sid)
    QUALIFY "iso_time" = MAX("iso_time") OVER (PARTITION BY "sid")
)
-- 7. latitude of the final coordinates
SELECT "latitude"
FROM   final_point;