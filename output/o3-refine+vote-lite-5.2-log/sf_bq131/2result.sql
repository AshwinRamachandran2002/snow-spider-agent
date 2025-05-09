WITH "DENMARK" AS (   -- multipolygon for Denmark (wikidata=Q35)
    SELECT
        ST_GEOGFROMWKB("geometry") AS "geom"
    FROM GEO_OPENSTREETMAP.GEO_OPENSTREETMAP."PLANET_FEATURES",
         LATERAL FLATTEN(INPUT => "all_tags") f
    WHERE  f.value:"key"::string  = 'wikidata'
       AND f.value:"value"::string = 'Q35'
    LIMIT 1                              -- there is only one national boundary
),

"BUS_STOPS" AS (      -- all bus‑stop points, together with their network tag
    SELECT
        ST_GEOGFROMWKB(pfp."geometry")                                                AS "geog",
        MAX(CASE WHEN f.value:"key"::string = 'network' THEN f.value:"value"::string END) AS "network"
    FROM GEO_OPENSTREETMAP.GEO_OPENSTREETMAP."PLANET_FEATURES_POINTS"  pfp,
         LATERAL FLATTEN(INPUT => pfp."all_tags") f
    GROUP BY pfp."geometry"
    HAVING MAX(CASE WHEN f.value:"key"::string = 'highway' THEN f.value:"value"::string END) = 'bus_stop'
)

SELECT MAX("stop_cnt") AS "num_bus_stops_of_largest_network"
FROM (
    SELECT
        "network",
        COUNT(*) AS "stop_cnt"
    FROM "BUS_STOPS",
         "DENMARK"
    WHERE ST_WITHIN("BUS_STOPS"."geog", "DENMARK"."geom")   -- only stops inside Denmark
      AND "network" IS NOT NULL                            -- require a network tag
    GROUP BY "network"
) ;