/*  Count pairs of California roads (motorway | trunk | primary | secondary | residential)
    that geometrically overlap, share no common nodes, and are not tagged as bridges      */
WITH ca_geom AS (                     -- geometry for California
    SELECT "state_geom"
    FROM GEO_OPENSTREETMAP_BOUNDARIES.GEO_US_BOUNDARIES."STATES"
    WHERE "state_name" = 'California'
),
ca_roads AS (                         -- candidate roads inside California
    SELECT
        w."id",
        w."geometry",
        ARRAY_AGG(DISTINCT n.value:"id"::NUMBER)  AS nodes_arr
    FROM GEO_OPENSTREETMAP_BOUNDARIES.GEO_OPENSTREETMAP."PLANET_WAYS"  w
    CROSS JOIN ca_geom g
    LEFT  JOIN LATERAL FLATTEN(input => w."nodes")      n    -- explode nodes
    LEFT  JOIN LATERAL FLATTEN(input => w."all_tags")   t    -- explode tags
    WHERE ST_INTERSECTS( TO_GEOGRAPHY(w."geometry"),
                         TO_GEOGRAPHY(g."state_geom") )
    GROUP BY w."id", w."geometry"
    HAVING
        /* at least one desired highway tag … */
        MAX( IFF(
                t.value:"key"::STRING = 'highway'
                AND t.value:"value"::STRING IN
                    ('motorway','trunk','primary','secondary','residential'),
                1, 0) ) = 1
        /* … and absolutely no bridge tag                                    */
        AND MAX( IFF(
                t.value:"key"::STRING = 'bridge',
                1, 0) ) = 0
),
pairs AS (                           -- unordered overlapping pairs, no shared nodes
    SELECT
        a."id" AS road_id_a,
        b."id" AS road_id_b
    FROM ca_roads a
    JOIN ca_roads b
      ON a."id" < b."id"
     AND ST_INTERSECTS( TO_GEOGRAPHY(a."geometry"),
                        TO_GEOGRAPHY(b."geometry") )
     AND ARRAY_SIZE(
           ARRAY_INTERSECTION(a.nodes_arr, b.nodes_arr)
         ) = 0
)
SELECT COUNT(*) AS num_overlapping_pairs
FROM   pairs;