WITH denmark AS (                 -- boundary of Denmark (wikidata = Q35)
    SELECT
        TO_GEOGRAPHY("geometry") AS geom
    FROM GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_FEATURES
    WHERE "feature_type" = 'multipolygons'
      AND "geometry" IS NOT NULL
      AND "all_tags" ILIKE '%"wikidata","value":"Q35"%'
    ORDER BY "osm_timestamp" DESC NULLS LAST
    LIMIT 1
),
bus_stops AS (                    -- bus stops that carry a 'network' tag inside Denmark
    SELECT
        net_tag.value:"value"::string AS network
    FROM GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_FEATURES_POINTS  pts ,
         denmark ,
         LATERAL FLATTEN ( INPUT => pts."all_tags" )           hw_tag ,
         LATERAL FLATTEN ( INPUT => pts."all_tags" )           net_tag
    WHERE hw_tag.value:"key"::string  = 'highway'
      AND hw_tag.value:"value"::string = 'bus_stop'
      AND net_tag.value:"key"::string  = 'network'
      AND pts."geometry" IS NOT NULL
      AND ST_CONTAINS( denmark.geom
                      , TO_GEOGRAPHY( pts."geometry" ) )
)
SELECT
    COUNT(*) AS "num_bus_stops"
FROM bus_stops
GROUP BY network
ORDER BY "num_bus_stops" DESC NULLS LAST
LIMIT 1;