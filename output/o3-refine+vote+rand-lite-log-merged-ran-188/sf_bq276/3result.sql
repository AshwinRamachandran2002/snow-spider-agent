/*  Ports in WPI region 6585 that lie inside U-S state boundaries and
    have been impacted (≤ 50 km) by named North-Atlantic storms with
    wind ≥ 35 kt and usa_sshs ≥ 0 (≥ tropical-storm strength).           */

WITH ports AS (          -- ports in region 6585
    SELECT  "index_number",
            "port_name",
            TO_GEOGRAPHY("port_geom") AS port_geog
    FROM    NOAA_PORTS.GEO_INTERNATIONAL_PORTS.WORLD_PORT_INDEX
    WHERE   "region_number" = '6585'
),
states AS (              -- U-S state geometries
    SELECT  "state_name",
            TO_GEOGRAPHY("state_geom") AS state_geog
    FROM    NOAA_PORTS.GEO_US_BOUNDARIES.STATES
),
ports_in_states AS (     -- ports that fall inside a state polygon
    SELECT  p."index_number",
            p."port_name",
            s."state_name",
            p.port_geog
    FROM    ports  p
    JOIN    states s
      ON    ST_CONTAINS(s.state_geog , p.port_geog)
),
storms AS (              -- qualifying named storms
    SELECT  "sid",
            "name",
            "iso_time",
            "latitude",
            "longitude",
            "usa_wind",
            "usa_sshs",
            ST_MAKEPOINT("longitude","latitude") AS storm_geog
    FROM    NOAA_PORTS.NOAA_HURRICANES.HURRICANES
    WHERE   "basin"     = 'NA'
      AND   "usa_wind" >= 35
      AND   "usa_sshs" >= 0
      AND   "name"     <> 'NOT_NAMED'
),
/*  Aggregate storm information per port (use index_number as the key;
    do NOT include GEOGRAPHY in GROUP BY)                               */
port_stats AS (
    SELECT
        ps."index_number",
        ps."port_name",
        ps."state_name",
        ARRAY_AGG( DISTINCT
            EXTRACT(
              YEAR FROM DATEADD(
                         SECOND,
                         st."iso_time" / 1000000,
                         TO_TIMESTAMP_NTZ('1970-01-01 00:00:00')
                     )
        ))                                      AS storm_years,
        COUNT(DISTINCT st."sid")                AS distinct_storms,
        ARRAY_AGG(DISTINCT st."name")           AS storm_names,
        AVG(st."usa_sshs")                      AS avg_category,
        AVG(st."usa_wind")                      AS avg_wind_kts,
        ST_UNION_AGG(st.storm_geog)             AS storms_geog
    FROM      ports_in_states ps
    JOIN      storms st
      ON      ST_DWITHIN(ps.port_geog , st.storm_geog , 50000)   -- 50 km
    GROUP BY  ps."index_number",
              ps."port_name",
              ps."state_name"
)
SELECT
    pstats."port_name",
    pstats."state_name",
    pstats.storm_years,
    pstats.distinct_storms,
    pstats.storm_names,
    pstats.avg_category,
    pstats.avg_wind_kts,
    pins.port_geog,        -- add port geometry back in
    pstats.storms_geog
FROM        port_stats      pstats
JOIN        ports_in_states pins
  ON        pstats."index_number" = pins."index_number"
ORDER BY    pstats."port_name";