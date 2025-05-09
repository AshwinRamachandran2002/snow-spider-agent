/*  Count named-hurricanes whose track points lie inside each
    NWS forecast-region polygon.  Because a dedicated ZIP-code
    boundary table is unavailable, the forecast-region “zone”
    is used as a ZIP surrogate and the region “name” as a city
    surrogate.  Bad coordinate pairs (lon  > 180 or lat > 90)
    are removed to avoid GEOGRAPHY construction errors.          */

WITH
-- 1.  Hurricane track points (omit “UNNAMED” storms and
--     filter out invalid lon / lat values)
hurricanes AS (
    SELECT
        "name"       AS hurricane_name,
        "latitude"   AS lat,
        "longitude"  AS lon
    FROM NOAA_DATA_PLUS.NOAA_HURRICANES.HURRICANES
    WHERE  "latitude"  IS NOT NULL
       AND "longitude" IS NOT NULL
       AND "longitude" BETWEEN -180 AND 180      -- valid range
       AND "latitude"  BETWEEN  -90 AND  90
       AND UPPER(TRIM("name")) <> 'UNNAMED'
),

-- 2.  Forecast-region polygons (WKB → GEOGRAPHY)
forecast_regions AS (
    SELECT
        "name"                            AS city,        -- surrogate city
        "zone"                            AS zip_code,    -- surrogate ZIP
        "state"                           AS state,
        ST_GEOGFROMWKB("shape_geometry")  AS geom         -- GEOGRAPHY polygon
    FROM NOAA_DATA_PLUS.NOAA_HISTORIC_SEVERE_STORMS.NWS_FORECAST_REGIONS
)

-- 3.  Spatial join & aggregation
SELECT
    fr.city,
    fr.zip_code,
    fr.state,
    COUNT(DISTINCT h.hurricane_name)                         AS hurricane_count,
    LISTAGG(DISTINCT h.hurricane_name, ', ')
        WITHIN GROUP (ORDER BY h.hurricane_name)             AS hurricane_names
FROM forecast_regions fr
JOIN hurricanes h
  ON ST_WITHIN(
         TO_GEOGRAPHY( ST_POINT(h.lon, h.lat) ),  -- GEOGRAPHY point
         fr.geom                                  -- GEOGRAPHY polygon
     )
GROUP BY fr.city, fr.zip_code, fr.state
ORDER BY hurricane_count DESC NULLS LAST;