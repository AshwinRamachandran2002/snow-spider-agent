WITH /* 1. U.S. ports in REGION_NUMBER = 6585 */
us_ports AS (
    SELECT
        "index_number",
        "port_name",
        "port_geom",                         -- WKB (BINARY)
        TO_GEOGRAPHY("port_geom") AS port_geog
    FROM NOAA_PORTS.GEO_INTERNATIONAL_PORTS.WORLD_PORT_INDEX
    WHERE "region_number" = '6585'
      AND "country"      = 'US'
),
/* 2.  Add state info */
ports_in_states AS (
    SELECT
        p.*,
        st."state_name"
    FROM us_ports p
    JOIN NOAA_PORTS.GEO_US_BOUNDARIES.STATES st
      ON ST_CONTAINS( TO_GEOGRAPHY(st."state_geom"), p.port_geog )
),
/* 3.  North‑Atlantic storms ≥35 kt, ≥TS */
atl_storm_points AS (
    SELECT
        h."sid",
        h."name"        AS storm_name,
        h."season"      AS storm_year,
        h."usa_sshs"    AS storm_cat,
        h."usa_wind"    AS wind_kt,
        ST_POINT(h."longitude", h."latitude") AS storm_geog
    FROM NOAA_PORTS.NOAA_HURRICANES.HURRICANES h
    WHERE h."basin"     = 'NA'
      AND h."usa_wind" >= 35
      AND h."usa_sshs" >= 0
      AND h."name" IS NOT NULL
      AND UPPER(h."name") NOT LIKE 'NOT_NAMED%'
),
/* 4.  Storm centres within 100 NM (~185 200 m) of each port */
port_storm_hits AS (
    SELECT
        p."index_number",
        s."sid",
        s.storm_name,
        s.storm_year,
        s.storm_cat,
        s.wind_kt,
        s.storm_geog
    FROM ports_in_states p
    JOIN atl_storm_points s
      ON ST_DISTANCE(p.port_geog, s.storm_geog) <= 185200
)

/* 5.  Final aggregation */
SELECT
    p."port_name"                                      AS port_name,
    p."state_name"                                     AS state_name,
    ARRAY_AGG(DISTINCT h.storm_year)                   AS distinct_years,
    COUNT(DISTINCT h."sid")                            AS total_distinct_storms,
    ARRAY_AGG(DISTINCT h.storm_name)                   AS distinct_storm_names,
    ROUND(AVG(h.storm_cat), 2)                         AS avg_storm_category,
    ROUND(AVG(h.wind_kt),  2)                          AS avg_wind_speed_kt,
    p."port_geom"                                      AS port_geometry_wkb,
    ARRAY_AGG(DISTINCT ST_ASBINARY(h.storm_geog))      AS storm_geometries_wkb
FROM ports_in_states p
JOIN port_storm_hits h
  ON p."index_number" = h."index_number"
GROUP BY
    p."port_name",
    p."state_name",
    p."port_geom"
ORDER BY
    port_name;