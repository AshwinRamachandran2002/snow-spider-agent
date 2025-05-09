WITH hurricanes_filtered AS (
    SELECT DISTINCT
           "name"      AS hurricane_name,
           "latitude"  AS lat,
           "longitude" AS lon
    FROM NOAA_DATA_PLUS.NOAA_HURRICANES.HURRICANES
    WHERE "name" IS NOT NULL
      AND UPPER(TRIM("name")) NOT IN ('UNNAMED', 'NO NAME', 'UNKNOWN', 'NONAME')
      -- keep only valid coordinates
      AND "latitude" BETWEEN -90 AND 90
      AND "longitude" BETWEEN -180 AND 180
), 
zips AS (
    SELECT
        "zip_code",
        "city",
        "state_code",
        TO_GEOGRAPHY("zip_code_geom") AS zip_geom
    FROM NOAA_DATA_PLUS.GEO_US_BOUNDARIES.ZIP_CODES
)
SELECT
       z."city",
       z."zip_code",
       z."state_code" AS state,
       COUNT(DISTINCT h.hurricane_name) AS hurricane_count,
       ARRAY_TO_STRING(
           ARRAY_AGG(DISTINCT h.hurricane_name)
               WITHIN GROUP (ORDER BY h.hurricane_name),
           ', '
       ) AS hurricane_list
FROM zips z
JOIN hurricanes_filtered h
  ON ST_WITHIN(
         ST_MAKEPOINT(h.lon, h.lat),
         z.zip_geom
     )
GROUP BY
       z."city",
       z."zip_code",
       z."state_code"
HAVING COUNT(DISTINCT h.hurricane_name) > 0
ORDER BY
       hurricane_count DESC NULLS LAST,
       z."city",
       z."zip_code";