WITH ports AS (   -- all U.S. ports in region 6585
    SELECT
        p."index_number",
        p."port_name",
        TO_GEOGRAPHY(p."port_geom")                    AS port_geog
    FROM NOAA_PORTS.GEO_INTERNATIONAL_PORTS.WORLD_PORT_INDEX p
    WHERE p."region_number" = '6585'
      AND p."country"       = 'US'
),
ports_states AS (   -- attach the state that contains each port
    SELECT
        prt."index_number",
        prt."port_name",
        st."state_name",
        prt.port_geog,
        ST_ASWKT(prt.port_geog)                       AS port_wkt
    FROM ports prt
    JOIN NOAA_PORTS.GEO_US_BOUNDARIES.STATES st
      ON ST_CONTAINS(TO_GEOGRAPHY(st."state_geom"), prt.port_geog)
),
storms AS (   -- named NA‑basin storms with ≥35 kt wind & ≥TS category
    SELECT
        h."sid",
        h."name",
        h."season",
        h."usa_wind",
        h."usa_sshs",
        ST_MAKEPOINT(h."longitude", h."latitude")     AS storm_geog,
        ST_ASWKT(ST_MAKEPOINT(h."longitude", h."latitude")) AS storm_wkt
    FROM NOAA_PORTS.NOAA_HURRICANES.HURRICANES h
    WHERE h."basin"    = 'NA'
      AND h."usa_wind" >= 35
      AND h."usa_sshs" >= 0
      AND h."longitude" IS NOT NULL
      AND h."latitude"  IS NOT NULL
      AND h."name" IS NOT NULL
      AND h."name" NOT ILIKE 'NOT_NAMED%'            -- keep only named storms
)
SELECT
    ps."port_name"                                                    AS port_name,
    ps."state_name"                                                   AS state_name,
    LISTAGG(DISTINCT st."season", ', ')      WITHIN GROUP (ORDER BY st."season") AS years,
    COUNT(DISTINCT st."sid")                                         AS storm_count,
    LISTAGG(DISTINCT st."name",   ', ')      WITHIN GROUP (ORDER BY st."name")   AS storm_names,
    ROUND(AVG(st."usa_sshs"), 4)                                     AS avg_category,
    ROUND(AVG(st."usa_wind"), 4)                                     AS avg_wind_speed_knots,
    ps.port_wkt                                                      AS port_geometry,
    LISTAGG(DISTINCT st.storm_wkt, ', ')  WITHIN GROUP (ORDER BY st.storm_wkt)  AS storm_geometries
FROM ports_states ps
JOIN storms st
  ON ST_DISTANCE(ps.port_geog, st.storm_geog) <= 25000   -- within 25 km
GROUP BY
    ps."port_name",
    ps."state_name",
    ps.port_wkt
ORDER BY
    ps."port_name";