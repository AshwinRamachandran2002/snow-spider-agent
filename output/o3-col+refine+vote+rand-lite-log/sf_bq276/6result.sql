/*  Comprehensive list of U.S. ports (Region 6585) impacted by named
    North-Atlantic storms (≥ 35 kt wind AND SSHS ≥ 0), with summary stats. */

WITH
/* 1)  Ports in Region-6585 that lie inside a U.S. state polygon */
ports_us AS (
    SELECT
        p."index_number",
        p."port_name",
        TO_GEOGRAPHY(p."port_geom") AS port_geo,
        p."port_geom",              -- keep raw WKB
        s."state_name"
    FROM NOAA_PORTS.GEO_INTERNATIONAL_PORTS."WORLD_PORT_INDEX"  p
    JOIN NOAA_PORTS.GEO_US_BOUNDARIES."STATES"                  s
      ON ST_CONTAINS(
             TO_GEOGRAPHY(s."state_geom"),
             TO_GEOGRAPHY(p."port_geom")
         )
    WHERE p."region_number" = '6585'
      AND p."country"       = 'US'
),

/* 2)  Named North-Atlantic storms satisfying wind / SSHS thresholds */
storms_na AS (
    SELECT
        h."sid",
        h."name",
        h."season"::NUMBER                         AS year,
        h."usa_sshs",
        h."usa_wind",
        TO_GEOGRAPHY( ST_POINT(h."longitude", h."latitude") ) AS storm_pt
    FROM NOAA_PORTS.NOAA_HURRICANES."HURRICANES" h
    WHERE h."basin"      = 'NA'
      AND h."name"      <> 'NOT_NAMED'
      AND h."usa_wind"   >= 35
      AND h."usa_sshs"   >= 0
      AND h."latitude"  IS NOT NULL
      AND h."longitude" IS NOT NULL
)

/* 3)  Spatial join & aggregation */
SELECT
    p."port_name",
    p."state_name",
    ARRAY_AGG(DISTINCT s.year)
        WITHIN GROUP (ORDER BY s.year)             AS years_affected,
    COUNT(DISTINCT s."sid")                        AS distinct_storms,
    ARRAY_AGG(DISTINCT s."name")
        WITHIN GROUP (ORDER BY s."name")           AS storm_names,
    AVG(s."usa_sshs")                              AS avg_category,
    AVG(s."usa_wind")                              AS avg_wind,
    p."port_geom",                                 -- WKB geometry of port
    ST_UNION_AGG(s.storm_pt)                       AS storms_geom
FROM ports_us p
JOIN storms_na s
  ON ST_DISTANCE(p.port_geo, s.storm_pt) <= 150000 -- 150 km (in metres)
GROUP BY
    p."port_name",
    p."state_name",
    p."port_geom"
ORDER BY
    distinct_storms DESC NULLS LAST,
    p."port_name";