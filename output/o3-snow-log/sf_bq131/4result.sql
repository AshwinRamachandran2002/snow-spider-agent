/* 1️⃣  Denmark multipolygon (wikidata = Q35) ----------------------------*/
WITH denmark AS (
    SELECT
        TO_GEOGRAPHY("geometry") AS geom
    FROM GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_FEATURES pf ,
         LATERAL FLATTEN( INPUT => pf."all_tags") tag
    WHERE tag.value:key::string   = 'wikidata'
      AND tag.value:value::string = 'Q35'
      AND pf."feature_type"       = 'multipolygons'
    LIMIT 1
)

/* 2️⃣  Explode tags for every point -----------------------------------*/
, point_tags AS (
    SELECT
        p."osm_id",
        TO_GEOGRAPHY(p."geometry")           AS geom,
        t.value:key::string                  AS k,
        t.value:value::string                AS v
    FROM GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_FEATURES_POINTS p ,
         LATERAL FLATTEN( INPUT => p."all_tags") t
    WHERE p."geometry" IS NOT NULL
)

/* 3️⃣  Re-assemble the tags per point ---------------------------------*/
, bus_points AS (
    SELECT
        "osm_id",
        ANY_VALUE(geom)                                            AS geom,   -- keep one geometry
        MAX( CASE WHEN k='network'          THEN v END )           AS network,
        MAX( CASE WHEN k='highway'          THEN v END )           AS highway,
        MAX( CASE WHEN k='public_transport' THEN v END )           AS pt_mode
    FROM point_tags
    GROUP BY "osm_id"
)

/* 4️⃣  Retain only bus-stop–like points having a network --------------*/
, bus_stops AS (
    SELECT *
    FROM   bus_points
    WHERE  network IS NOT NULL
       AND (  highway = 'bus_stop'
           OR pt_mode IN ( 'platform','stop_position','stop','station' ) )
)

/* 5️⃣  Keep only those inside Denmark ---------------------------------*/
, dk_stops AS (
    SELECT bs.network
    FROM   bus_stops bs ,
           denmark   dk
    WHERE  ST_CONTAINS( dk.geom , bs.geom )
)

/* 6️⃣  Count per network and return the maximum -----------------------*/
SELECT MAX(cnt) AS "BUS_STOP_COUNT_WITHIN_TOP_NETWORK"
FROM (
      SELECT network , COUNT(*) AS cnt
      FROM   dk_stops
      GROUP  BY network
) ;