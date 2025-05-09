WITH atlantic_2020 AS (   -- 2020 North-Atlantic hurricane track points
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
),                                          -- distance between successive points
leg_distances AS (
    SELECT
        "sid",
        "iso_time",
        COALESCE(
            ST_DISTANCE(
                ST_POINT( LAG("longitude") OVER (PARTITION BY "sid" ORDER BY "iso_time"),
                          LAG("latitude")  OVER (PARTITION BY "sid" ORDER BY "iso_time") ),
                ST_POINT( "longitude", "latitude")
            ), 0
        ) AS segment_meters
    FROM atlantic_2020
),                                          -- total travelled distance per storm
track_lengths AS (
    SELECT
        "sid",
        SUM(segment_meters) AS total_meters
    FROM leg_distances
    GROUP BY "sid"
),                                          -- storm with 2nd-longest track
second_longest AS (
    SELECT "sid"
    FROM track_lengths
    QUALIFY RANK() OVER (ORDER BY total_meters DESC NULLS LAST) = 2
),                                          -- final position of that storm
final_point AS (
    SELECT
        "latitude"
    FROM NOAA_DATA.NOAA_HURRICANES.HURRICANES h
    WHERE h."sid" IN (SELECT "sid" FROM second_longest)
      AND h."iso_time" = (
            SELECT MAX("iso_time")
            FROM NOAA_DATA.NOAA_HURRICANES.HURRICANES
            WHERE "sid" = h."sid"
      )
)
SELECT "latitude"
FROM final_point;