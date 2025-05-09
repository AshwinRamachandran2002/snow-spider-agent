WITH denmark AS (   -- Denmark’s multipolygon boundary (wikidata = 'Q35')
    SELECT ST_GEOGFROMWKB("geometry") AS geog
    FROM   "GEO_OPENSTREETMAP"."GEO_OPENSTREETMAP"."PLANET_FEATURES",
           LATERAL FLATTEN(input => "all_tags") tag
    WHERE  tag.value:"key"::STRING  = 'wikidata'
      AND  tag.value:"value"::STRING = 'Q35'
      AND  "feature_type" = 'multipolygons'
    LIMIT 1
),
bus_stops AS (      -- bus-stop points located inside Denmark
    SELECT  p."osm_id",
            p."all_tags"
    FROM    "GEO_OPENSTREETMAP"."GEO_OPENSTREETMAP"."PLANET_FEATURES_POINTS"  p,
            denmark d,
            LATERAL FLATTEN(input => p."all_tags") h
    WHERE   h.value:"key"::STRING  = 'highway'
      AND   h.value:"value"::STRING ILIKE '%bus%stop%'
      AND   ST_CONTAINS(d.geog, ST_GEOGFROMWKB(p."geometry"))
),
networked AS (      -- extract the network tag for each stop
    SELECT  s."osm_id",
            n.value:"value"::STRING AS network_name
    FROM    bus_stops  s,
            LATERAL FLATTEN(input => s."all_tags") n
    WHERE   n.value:"key"::STRING = 'network'
)
SELECT
       COALESCE(network_name, '(no network tag)') AS "bus_network",
       COUNT(*)                                   AS "num_stops"
FROM   networked
GROUP  BY network_name
ORDER  BY "num_stops" DESC NULLS LAST
LIMIT 1;