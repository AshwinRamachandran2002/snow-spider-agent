/*---------------------------------------------------------------------------
  U.S. ports (region 6585) intersecting (≤ 50 NM) named North-Atlantic storms
  with wind ≥ 35 kt and Saffir-Simpson class ≥ tropical-storm.  GEOGRAPHY
  objects are converted to WKT because Snowflake cannot GROUP BY GEOGRAPHY.
---------------------------------------------------------------------------*/
WITH ports AS (                           /* 1. Region-6585 ports            */
    SELECT
        w."index_number",
        w."port_name",
        TO_GEOGRAPHY(w."port_geom")            AS port_geog,
        ST_ASWKT(TO_GEOGRAPHY(w."port_geom"))  AS port_wkt        -- WKT text
    FROM NOAA_PORTS.GEO_INTERNATIONAL_PORTS."WORLD_PORT_INDEX" w
    WHERE w."region_number" = '6585'
),
ports_us AS (                               /* 2. Ports inside U.S. states    */
    SELECT
        p."index_number",
        p."port_name",
        s."state_name",
        p.port_wkt                            -- keep WKT only (for GROUP BY)
    FROM ports p
    JOIN NOAA_PORTS.GEO_US_BOUNDARIES."STATES" s
      ON ST_CONTAINS(
           TO_GEOGRAPHY(s."state_geom"),
           p.port_geog
         )
),
storms AS (                                 /* 3. Storms that meet criteria   */
    SELECT
        h."sid",
        h."season",
        h."name"                       AS storm_name,
        h."usa_wind",
        h."usa_sshs",
        ST_POINT(h."longitude", h."latitude")          AS storm_geog,
        ST_ASWKT(ST_POINT(h."longitude", h."latitude")) AS storm_wkt
    FROM NOAA_PORTS.NOAA_HURRICANES."HURRICANES" h
    WHERE h."basin"     = 'NA'
      AND h."usa_wind" >= 35
      AND h."usa_sshs" >= 0
      AND h."name"     NOT ILIKE '%NOT NAMED%'
),
port_storm AS (                             /* 4. Port / storm pairs ≤ 50 NM  */
    SELECT
        p."index_number",
        p."port_name",
        p."state_name",
        p.port_wkt,
        s."sid",
        s."season",
        s.storm_name,
        s."usa_sshs",
        s."usa_wind",
        s.storm_wkt
    FROM ports_us p
    JOIN storms   s
      ON ST_DWITHIN(
           TO_GEOGRAPHY(p.port_wkt),
           TO_GEOGRAPHY(s.storm_wkt),
           92600          -- metres ≈ 50 nautical miles
         )
)
/*----------------------------- 5. Final report ----------------------------*/
SELECT
    "index_number",
    "port_name",
    "state_name",
    ARRAY_AGG(DISTINCT "season")               AS storm_years,
    COUNT(DISTINCT "sid")                      AS storm_count,
    ARRAY_AGG(DISTINCT storm_name)             AS storm_names,
    AVG(DISTINCT "usa_sshs")                   AS avg_storm_category,
    AVG(DISTINCT "usa_wind")                   AS avg_wind_kt,
    TO_GEOGRAPHY(port_wkt)                     AS port_geometry,
    ARRAY_AGG(DISTINCT storm_wkt)              AS storm_geometries_wkt
FROM port_storm
GROUP BY
    "index_number",
    "port_name",
    "state_name",
    port_wkt
ORDER BY
    "index_number";