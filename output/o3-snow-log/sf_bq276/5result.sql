/*-----------------------------------------------------------
  Ports (region 6585) inside U.S. states that were impacted
  (≤ 100 km) by named North-Atlantic storms (wind ≥ 35 kt,
   Saffir-Simpson ≥ TS).

  Returned per qualifying port:
    • port_name, state_name
    • array of distinct storm years
    • count of distinct storms
    • array of distinct storm names
    • avg Saffir-Simpson category
    • avg wind speed (kt)
    • port geometry  (GEOGRAPHY)
    • array of WKT geometries of the impacting storm fixes
-----------------------------------------------------------*/
WITH ports AS (                 -- candidate ports
  SELECT
      p."index_number",
      p."port_name",
      TO_GEOGRAPHY(p."port_geom") AS "port_geog"
  FROM NOAA_PORTS.GEO_INTERNATIONAL_PORTS."WORLD_PORT_INDEX" p
  WHERE p."region_number" = '6585'
),
states_containing AS (          -- ports located within a state
  SELECT
      pr."index_number",
      pr."port_name",
      pr."port_geog",
      s."state_name"
  FROM ports pr
  JOIN NOAA_PORTS.GEO_US_BOUNDARIES."STATES" s
    ON ST_CONTAINS(TO_GEOGRAPHY(s."state_geom"), pr."port_geog")
),
storms_near AS (                -- storm fixes within 100 km
  SELECT
      sc."index_number",
      h."sid",
      h."season",
      h."name",
      h."usa_wind",
      h."usa_sshs",
      ST_POINT(h."longitude", h."latitude")             AS "storm_geog",
      ST_ASTEXT(ST_POINT(h."longitude", h."latitude"))  AS "storm_wkt"
  FROM NOAA_PORTS.NOAA_HURRICANES."HURRICANES" h
  JOIN states_containing sc
    ON  h."basin"     = 'NA'
    AND h."name"      NOT ILIKE '%NOT%'   -- exclude “NOT_NAMED”
    AND h."usa_wind"  >= 35               -- ≥ 35 kt
    AND h."usa_sshs"  >= 0                -- ≥ TS
    AND ST_DISTANCE(
          ST_POINT(h."longitude", h."latitude"),
          sc."port_geog"
        ) <= 100000                       -- ≤ 100 km
),
agg AS (                       -- aggregate by port
  SELECT
      sc."index_number",
      sc."port_name",
      sc."state_name",
      ARRAY_AGG(DISTINCT storms_near."season")      AS "storm_years",
      COUNT(DISTINCT storms_near."sid")             AS "distinct_storms",
      ARRAY_AGG(DISTINCT storms_near."name")        AS "storm_names",
      ROUND(AVG(storms_near."usa_sshs"), 3)         AS "avg_category",
      ROUND(AVG(storms_near."usa_wind"), 3)         AS "avg_wind_kt",
      ARRAY_AGG(DISTINCT storms_near."storm_wkt")   AS "storm_geometries"
  FROM states_containing sc
  JOIN storms_near
    ON sc."index_number" = storms_near."index_number"
  GROUP BY
      sc."index_number",
      sc."port_name",
      sc."state_name"
)
SELECT
    a."port_name",
    a."state_name",
    a."storm_years",
    a."distinct_storms",
    a."storm_names",
    a."avg_category",
    a."avg_wind_kt",
    sc."port_geog"        AS "port_geometry",
    a."storm_geometries"
FROM agg a
JOIN states_containing sc
  ON a."index_number" = sc."index_number"
ORDER BY
    a."port_name";