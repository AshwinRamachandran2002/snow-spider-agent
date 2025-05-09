WITH named_hurricanes AS (           -- retain only named storms
    SELECT DISTINCT 
           "sid",
           TRIM("name") AS "name"
    FROM NOAA_DATA_PLUS.NOAA_HURRICANES.HURRICANES
    WHERE "name" IS NOT NULL
      AND TRIM("name") <> ''
),
hurricane_points AS (                -- create geography points, keep valid lat/long
    SELECT
        h."sid",
        nh."name",
        ST_POINT(h."longitude", h."latitude") AS pt
    FROM NOAA_DATA_PLUS.NOAA_HURRICANES.HURRICANES h
    JOIN named_hurricanes nh
      ON nh."sid" = h."sid"
    WHERE h."longitude" BETWEEN -180 AND 180
      AND h."latitude"  BETWEEN  -90  AND  90
      AND h."longitude" IS NOT NULL
      AND h."latitude"  IS NOT NULL
)
SELECT
    z."city"                                   AS "city",
    z."zip_code"                               AS "zip_code",
    z."state_code"                             AS "state",
    COUNT(DISTINCT hp."name")                  AS "count_of_hurricanes",
    LISTAGG(DISTINCT hp."name", ', ') 
        WITHIN GROUP (ORDER BY hp."name")      AS "hurricanes"
FROM NOAA_DATA_PLUS.GEO_US_BOUNDARIES.ZIP_CODES z
JOIN hurricane_points hp
  ON ST_WITHIN(hp.pt, TO_GEOGRAPHY(z."zip_code_geom"))
GROUP BY z."city", z."zip_code", z."state_code"
ORDER BY "count_of_hurricanes" DESC NULLS LAST,
         z."city";