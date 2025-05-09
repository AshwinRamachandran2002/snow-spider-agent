WITH storm_points AS (
    SELECT
        "sid",
        "iso_time",
        "latitude",
        "longitude",
        ROW_NUMBER() OVER (PARTITION BY "sid" ORDER BY "iso_time")     AS rn_first,
        ROW_NUMBER() OVER (PARTITION BY "sid" ORDER BY "iso_time" DESC) AS rn_last
    FROM NOAA_DATA.NOAA_HURRICANES.HURRICANES
    WHERE "season" = '2020'
      AND "basin"  = 'NA'          --  North Atlantic storms
), storm_start_end AS (
    SELECT
        "sid",
        MAX(CASE WHEN rn_first = 1 THEN "latitude"  END) AS start_lat,
        MAX(CASE WHEN rn_first = 1 THEN "longitude" END) AS start_lon,
        MAX(CASE WHEN rn_last  = 1 THEN "latitude"  END) AS end_lat,
        MAX(CASE WHEN rn_last  = 1 THEN "longitude" END) AS end_lon
    FROM storm_points
    GROUP BY "sid"
), storm_dist AS (
    SELECT
        "sid",
        end_lat,
        6371 * ACOS(
            LEAST(1, GREATEST(-1,
                SIN(RADIANS(start_lat)) * SIN(RADIANS(end_lat)) +
                COS(RADIANS(start_lat)) * COS(RADIANS(end_lat)) *
                COS(RADIANS(end_lon - start_lon))
            ))
        ) AS displacement_km
    FROM storm_start_end
)
SELECT end_lat  -- latitude of the final point
FROM storm_dist
ORDER BY displacement_km DESC NULLS LAST
OFFSET 1 ROW           -- skip the longest; get the second longest
FETCH NEXT 1 ROW ONLY;