WITH points AS (
    SELECT
        "sid",
        "iso_time",
        "latitude",
        "longitude",
        LEAD("latitude")  OVER (PARTITION BY "sid" ORDER BY "iso_time") AS next_lat,
        LEAD("longitude") OVER (PARTITION BY "sid" ORDER BY "iso_time") AS next_lon
    FROM NOAA_DATA.NOAA_HURRICANES.HURRICANES
    WHERE "season" = '2020'
      AND "basin"  = 'NA'                  -- North Atlantic
),
distances AS (
    SELECT
        "sid",
        SUM(
            ST_DISTANCE(
                ST_MAKEPOINT("longitude", "latitude"),
                ST_MAKEPOINT(next_lon   , next_lat)
            )
        ) AS total_distance_m
    FROM points
    WHERE next_lat IS NOT NULL             -- skip last point of each track
    GROUP BY "sid"
),
second_sid AS (                            -- identify 2nd-longest track
    SELECT "sid"
    FROM (
        SELECT
            "sid",
            total_distance_m,
            ROW_NUMBER() OVER (ORDER BY total_distance_m DESC NULLS LAST) AS rn
        FROM distances
    )
    WHERE rn = 2
),
final_coord AS (                           -- final coordinate of that storm
    SELECT
        h."latitude"
    FROM NOAA_DATA.NOAA_HURRICANES.HURRICANES h
    JOIN second_sid s USING ("sid")
    WHERE h."season" = '2020'
    QUALIFY ROW_NUMBER() OVER (PARTITION BY h."sid" ORDER BY h."iso_time" DESC NULLS LAST) = 1
)
SELECT "latitude"
FROM final_coord;