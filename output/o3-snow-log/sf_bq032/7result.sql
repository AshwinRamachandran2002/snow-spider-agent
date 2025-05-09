WITH track AS (   -- 2020 North-Atlantic hurricane positions in chronological order
    SELECT
        "sid",
        "iso_time",
        "latitude",
        "longitude",
        LAG("latitude")  OVER (PARTITION BY "sid" ORDER BY "iso_time") AS "prev_lat",
        LAG("longitude") OVER (PARTITION BY "sid" ORDER BY "iso_time") AS "prev_lon"
    FROM NOAA_DATA.NOAA_HURRICANES.HURRICANES
    WHERE "season" = '2020'
      AND "basin"  = 'NA'
),
segments AS (     -- distance between successive fixes (Haversine, km)
    SELECT
        "sid",
        "iso_time",
        "latitude",
        CASE
            WHEN "prev_lat" IS NULL THEN 0
            ELSE
                2 * 6371 * ASIN( SQRT(
                        POWER(SIN( RADIANS( "latitude" - "prev_lat") / 2 ),2) +
                        COS( RADIANS("prev_lat") ) * COS( RADIANS("latitude") ) *
                        POWER(SIN( RADIANS( "longitude" - "prev_lon") / 2 ),2)
                    ))
        END AS "segment_km"
    FROM track
),
storm_distance AS (   -- total track length per hurricane
    SELECT "sid",
           SUM("segment_km") AS "total_km"
    FROM segments
    GROUP BY "sid"
),
final_fix AS (       -- final position (last time) for each hurricane
    SELECT s."sid",
           s."latitude" AS "final_lat"
    FROM segments s
    QUALIFY "iso_time" = MAX("iso_time") OVER (PARTITION BY "sid")
),
ranked AS (          -- rank storms by distance travelled
    SELECT
        f."sid",
        f."final_lat",
        ROW_NUMBER() OVER (ORDER BY d."total_km" DESC NULLS LAST) AS "rnum"
    FROM final_fix f
    JOIN storm_distance d USING ("sid")
)
SELECT "final_lat"   -- latitude of the 2nd-longest-track hurricane
FROM ranked
WHERE "rnum" = 2;