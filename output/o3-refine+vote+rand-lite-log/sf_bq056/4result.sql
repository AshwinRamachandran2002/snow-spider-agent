WITH ca_boundary AS (   -- California geometry
    SELECT ST_GEOMFROMWKB("state_geom") AS ca_geom
    FROM   GEO_OPENSTREETMAP_BOUNDARIES.GEO_US_BOUNDARIES.STATES
    WHERE  "state_fips_code" = '06'
),
ways_tagged AS (        -- OSM ways intersecting California + tag flags
    SELECT
        w."id"                                                   AS way_id,
        ST_GEOMFROMWKB(w."geometry")                             AS geom,
        ARRAY_AGG(DISTINCT TO_NUMBER(n.value:id))                AS node_ids,

        BOOLOR_AGG(                                              -- at least one wanted highway class
            IFF(t.value:key = 'highway'
                AND t.value:value IN ('motorway','trunk',
                                      'primary','secondary',
                                      'residential'),
                TRUE, FALSE)
        ) AS is_good_class,

        BOOLOR_AGG(                                              -- any bridge tag?
            IFF(t.value:key = 'bridge', TRUE, FALSE)
        ) AS has_bridge

    FROM GEO_OPENSTREETMAP_BOUNDARIES.GEO_OPENSTREETMAP.PLANET_WAYS w
         ,LATERAL FLATTEN(input => w."nodes")     n
         ,LATERAL FLATTEN(input => w."all_tags")  t
         ,ca_boundary cb
    WHERE ST_INTERSECTS(cb.ca_geom, ST_GEOMFROMWKB(w."geometry"))
    GROUP BY w."id", w."geometry"
),
roads_ca AS (           -- keep only desired roads, exclude bridges
    SELECT way_id, geom, node_ids
    FROM   ways_tagged
    WHERE  is_good_class = TRUE
      AND  has_bridge    = FALSE
),
pair_count AS (         -- count overlapping pairs without shared nodes
    SELECT COUNT(*) AS overlaps_without_shared_nodes
    FROM   roads_ca r1
    JOIN   roads_ca r2
           ON r1.way_id < r2.way_id                    -- unique pairs
          AND ST_INTERSECTS(r1.geom, r2.geom)          -- geometries overlap
          AND ARRAY_SIZE(
                  ARRAY_INTERSECTION(r1.node_ids, r2.node_ids)
              ) = 0                                    -- no shared nodes
)
SELECT overlaps_without_shared_nodes
FROM   pair_count;