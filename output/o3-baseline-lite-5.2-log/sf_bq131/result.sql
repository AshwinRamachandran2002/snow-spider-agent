WITH denmark AS (   -- Denmark multipolygon (wikidata = Q35)
    SELECT
        TO_GEOGRAPHY("geometry") AS geom
    FROM GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_FEATURES,
         LATERAL FLATTEN(INPUT => "all_tags") tag
    WHERE tag.value:"key"::string  = 'wikidata'
      AND tag.value:"value"::string = 'Q35'
    LIMIT 1
),
raw_bus_stops AS (  -- every point tagged highway=bus_stop that also carries a network tag
    SELECT
        TO_GEOGRAPHY(p."geometry")                          AS geom,
        net_tag.value:"value"::string                       AS network_name
    FROM GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_FEATURES_POINTS p,
         LATERAL FLATTEN(INPUT => p."all_tags") hw_tag,
         LATERAL FLATTEN(INPUT => p."all_tags") net_tag
    WHERE hw_tag.value:"key"::string  = 'highway'
      AND hw_tag.value:"value"::string = 'bus_stop'
      AND net_tag.value:"key"::string = 'network'
      AND p."geometry" IS NOT NULL
),
bus_stops_in_denmark AS (   -- keep only those stops lying inside the Denmark polygon
    SELECT
        rbs.network_name
    FROM raw_bus_stops rbs
    JOIN denmark d
      ON ST_CONTAINS(d.geom, rbs.geom)
)
SELECT
    network_name,
    COUNT(*) AS stop_count          -- number of bus‑stop points
FROM bus_stops_in_denmark
GROUP BY network_name
ORDER BY stop_count DESC NULLS LAST
LIMIT 1;