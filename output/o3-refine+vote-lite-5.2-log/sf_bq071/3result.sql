WITH storms AS (   /* named hurricanes with valid coordinates */
    SELECT DISTINCT
           "name",
           "longitude" AS lon,
           "latitude"  AS lat
    FROM NOAA_DATA_PLUS.NOAA_HURRICANES.HURRICANES
    WHERE "name" IS NOT NULL
      AND "name" <> ''
      AND UPPER("name") <> 'UNNAMED'
      AND "longitude" BETWEEN -180 AND 180
      AND "latitude"  BETWEEN  -90 AND  90
), 

zips AS (          /* ZIP‑code polygons converted to GEOGRAPHY */
    SELECT
           "city",
           "zip_code",
           "state_code" AS "state",
           TO_GEOGRAPHY("zip_code_geom") AS geom
    FROM NOAA_DATA_PLUS.GEO_US_BOUNDARIES.ZIP_CODES
), 

storm_in_zip AS (  /* hurricanes whose points fall inside a ZIP polygon */
    SELECT DISTINCT
           z."city",
           z."zip_code",
           z."state",
           s."name"
    FROM storms s
    JOIN zips   z
      ON ST_WITHIN(
           ST_MAKEPOINT(s.lon , s.lat),   -- hurricane point (GEOGRAPHY)
           z.geom                         -- ZIP polygon (GEOGRAPHY)
         )
)

SELECT
       "city",
       "zip_code",
       "state",
       COUNT(DISTINCT "name")                                   AS "hurricane_count",
       LISTAGG(DISTINCT "name", ', ') 
         WITHIN GROUP (ORDER BY "name")                         AS "hurricanes"
FROM   storm_in_zip
GROUP  BY "city", "zip_code", "state"
ORDER  BY "hurricane_count" DESC NULLS LAST;