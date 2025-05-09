/* -------------------------------------------------------------
   Ports in Region 6585 that are inside U.S. state boundaries and
   were struck (≤ 50 nmi) by NAMED North-Atlantic storms with
       • 1-min wind ≥ 35 kt
       • SSHS category ≥ 0  (≥ minimal tropical-storm)

   Returned per port:
     – port & state
     – distinct years hit
     – count of distinct storms
     – distinct storm names
     – avg SSHS category & wind
     – WKT of port point
     – WKT of MULTI-POINT made from all storm-centre positions
   ------------------------------------------------------------- */
WITH ports_us AS (      /* Region-6585 ports that fall in a U.S. state */
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
),
storms AS (             /* Named North-Atlantic storms meeting criteria */
    SELECT
        h."sid",
        h."name",
        h."iso_time",
        h."usa_wind",
        h."usa_sshs",
        h."latitude",
        h."longitude",
        TO_GEOGRAPHY('POINT(' || h."longitude" || ' ' || h."latitude" || ')') AS storm_geom
    FROM NOAA_PORTS.NOAA_HURRICANES."HURRICANES" h
    WHERE h."basin"     = 'NA'
      AND h."usa_wind"  >= 35
      AND h."usa_sshs"  >= 0
      AND h."name" NOT ILIKE 'NOT_NAMED'
)
SELECT
    p."port_name",
    p."state_name",

    ARRAY_SORT(
        ARRAY_AGG(
            DISTINCT YEAR(TO_TIMESTAMP_NTZ(s."iso_time" / 1e6))
        )
    )                           AS "years_hit",

    COUNT(DISTINCT s."sid")     AS "num_storms",

    ARRAY_SORT(
        ARRAY_AGG(DISTINCT s."name")
    )                           AS "storm_names",

    ROUND(AVG(s."usa_sshs"), 3) AS "avg_sshs_cat",
    ROUND(AVG(s."usa_wind"), 2) AS "avg_wind_kt",

    ST_AsText(TO_GEOGRAPHY(p."port_geom"))          AS "port_geom_wkt",

    ST_AsText(
        ST_UNION_AGG(s.storm_geom)                  -- union of all centre points
    )                           AS "storms_geom_wkt"

FROM ports_us p
JOIN storms  s
  ON ST_DISTANCE(
         TO_GEOGRAPHY(p."port_geom"),
         s.storm_geom
     ) <= 92600                -- 50 nautical miles ≈ 92 600 m

GROUP BY
    p."port_name",
    p."state_name",
    p."port_geom"

ORDER BY
    p."state_name",
    p."port_name";