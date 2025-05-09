WITH port_state AS (
    /*--------------------------------------------------------------------
      U.S. ports in Region 6585 that fall inside a state boundary
    --------------------------------------------------------------------*/
    SELECT
        p."index_number",
        p."port_name",
        p."port_geom",
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
filtered_storms AS (
    /*--------------------------------------------------------------------
      Named North-Atlantic storms with wind ≥35 kt and SSA ≥0
    --------------------------------------------------------------------*/
    SELECT *
    FROM NOAA_PORTS.NOAA_HURRICANES."HURRICANES"
    WHERE "basin"     = 'NA'
      AND "usa_wind" >= 35
      AND "usa_sshs" >= 0
      AND "name" IS NOT NULL
      AND "name" <> 'NOT_NAMED'
)

SELECT
    ps."port_name",
    ps."state_name",
    ARRAY_AGG(DISTINCT h."season")                                 AS "storm_years",
    COUNT(DISTINCT h."sid")                                        AS "num_distinct_storms",
    ARRAY_AGG(DISTINCT h."name")                                   AS "storm_names",
    AVG(DISTINCT h."usa_sshs")                                     AS "avg_sshs_cat",
    AVG(h."usa_wind")                                              AS "avg_wind_kts",
    ps."port_geom"                                                 AS "port_geom",
    ARRAY_AGG(
        DISTINCT ST_ASWKT(
            TO_GEOGRAPHY(ST_MAKEPOINT(h."longitude", h."latitude"))
        )
    )                                                              AS "storm_geometries_wkt"
FROM   port_state      ps
JOIN   filtered_storms h
  ON ST_DWITHIN(
       TO_GEOGRAPHY(ps."port_geom"),
       ST_MAKEPOINT(h."longitude", h."latitude"),
       92600          -- 50 nm in metres
     )
GROUP BY
    ps."port_name",
    ps."state_name",
    ps."port_geom"
ORDER BY
    ps."port_name";