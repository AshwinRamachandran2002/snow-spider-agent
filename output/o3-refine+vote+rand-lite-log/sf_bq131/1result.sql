WITH denmark AS (   ---------------------------------------------------------
-- Geometry of Denmark (latest version) taken from relation whose tag
--      wikidata = 'Q35'
---------------------------------------------------------------------------
    SELECT
        TO_GEOGRAPHY(r."geometry") AS geom
    FROM GEO_OPENSTREETMAP.GEO_OPENSTREETMAP."PLANET_RELATIONS"   r
         ,LATERAL FLATTEN(input => r."all_tags") tag
    WHERE tag.value:key   = 'wikidata'
      AND tag.value:value = 'Q35'
    ORDER BY r."osm_timestamp" DESC
    LIMIT 1
),
dk_points AS (      ---------------------------------------------------------
-- All point features located inside the Denmark multipolygon
---------------------------------------------------------------------------
    SELECT
        p."all_tags"                AS tags,
        d.geom                      AS dk_geom
    FROM GEO_OPENSTREETMAP.GEO_OPENSTREETMAP."PLANET_FEATURES_POINTS" p
         CROSS JOIN denmark d
    WHERE p."geometry" IS NOT NULL
      AND ST_WITHIN( TO_GEOGRAPHY(p."geometry"), d.geom )
),
bus_stops AS (      ---------------------------------------------------------
-- Among those points: pick the rows that are highway = bus_stop
-- and carry a   network = <network‑name>   tag.
---------------------------------------------------------------------------
    SELECT
        net_tag.value:value AS network_raw
    FROM dk_points
         ,LATERAL FLATTEN(input => dk_points.tags) hwy_tag
         ,LATERAL FLATTEN(input => dk_points.tags) net_tag
    WHERE hwy_tag.value:key   = 'highway'
      AND hwy_tag.value:value = 'bus_stop'
      AND net_tag.value:key   = 'network'
),
expanded_networks AS ( ------------------------------------------------------
-- Split possible multi‑value networks like  "A;B;C"  into separate rows
---------------------------------------------------------------------------
    SELECT
        TRIM(f.value::string) AS network
    FROM bus_stops,
         LATERAL FLATTEN(input => SPLIT(network_raw, ';')) f
    WHERE TRIM(f.value::string) <> ''
)
SELECT ----------------------------------------------------------------------
       network          AS "BUS_NETWORK",
       COUNT(*)         AS "NUM_BUS_STOPS"
FROM   expanded_networks
GROUP  BY network
ORDER  BY COUNT(*) DESC NULLS LAST, network
LIMIT 1;