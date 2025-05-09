WITH ports AS (  -- U.S. ports in region 6585
    SELECT
        "port_name",
        TO_GEOGRAPHY("port_geom") AS port_geog
    FROM NOAA_PORTS.GEO_INTERNATIONAL_PORTS.WORLD_PORT_INDEX
    WHERE "region_number" = '6585'
      AND "country"       = 'US'
),

ports_in_state AS (      -- ports that lie within a U.S. state polygon
    SELECT
        p."port_name",
        st."state_name",
        p.port_geog,
        ST_ASWKT(p.port_geog) AS port_wkt   -- text version for grouping / output
    FROM ports p
    JOIN NOAA_PORTS.GEO_US_BOUNDARIES.STATES st
      ON ST_CONTAINS(TO_GEOGRAPHY(st."state_geom"), p.port_geog)
),

named_storms AS (        -- North‑Atlantic named storms (≥ 35 kts & ≥ minimal TS)
    SELECT DISTINCT
        "sid",
        "name",
        "season",
        "usa_wind",
        "usa_sshs",
        ST_POINT("longitude", "latitude") AS storm_geog
    FROM NOAA_PORTS.NOAA_HURRICANES.HURRICANES
    WHERE "basin"     = 'NA'
      AND "usa_wind" >= 35
      AND "usa_sshs" >= 0
      AND "name" IS NOT NULL
      AND "name" <> 'NOT_NAMED'
      AND "longitude" IS NOT NULL
      AND "latitude"  IS NOT NULL
)

SELECT
    pis."port_name",
    pis."state_name",
    ARRAY_TO_STRING(
        ARRAY_AGG(DISTINCT CAST(ns."season" AS STRING)
        ) WITHIN GROUP (ORDER BY CAST(ns."season" AS STRING)),
        ', '
    )                                                   AS years,
    COUNT(DISTINCT ns."sid")                            AS storm_count,
    ARRAY_TO_STRING(
        ARRAY_AGG(DISTINCT ns."name"
        ) WITHIN GROUP (ORDER BY ns."name"),
        ', '
    )                                                   AS storm_names,
    ROUND(AVG(ns."usa_sshs"), 4)                        AS avg_category,
    ROUND(AVG(ns."usa_wind"), 4)                        AS avg_wind_speed_knots,
    pis.port_wkt                                        AS port_geometry,
    ARRAY_TO_STRING(
        ARRAY_AGG(DISTINCT ST_ASWKT(ns.storm_geog)
        ) WITHIN GROUP (ORDER BY ST_ASWKT(ns.storm_geog)),
        '; '
    )                                                   AS storm_geometries
FROM ports_in_state  pis
JOIN named_storms    ns
  ON ST_DISTANCE(pis.port_geog, ns.storm_geog) <= 100000  -- within 100 km
GROUP BY
    pis."port_name",
    pis."state_name",
    pis.port_wkt
ORDER BY
    pis."port_name";