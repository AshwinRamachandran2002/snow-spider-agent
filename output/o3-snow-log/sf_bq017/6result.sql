WITH denmark AS (   -- Denmark administrative boundary (wikidata = Q35)
    SELECT ST_GEOGFROMWKB("geometry") AS geom
    FROM   GEO_OPENSTREETMAP.GEO_OPENSTREETMAP."PLANET_RELATIONS"
    WHERE  "id" = 50046                         -- relation 50046 = Denmark
),

dk_highways AS (
    SELECT
        tag.value:"value"::STRING                         AS highway_type,
        ST_Length( ST_GEOGFROMWKB(pf."geometry") )        AS metres
    FROM   GEO_OPENSTREETMAP.GEO_OPENSTREETMAP."PLANET_FEATURES" pf,
           LATERAL FLATTEN( INPUT => pf."all_tags" ) tag,
           denmark d
    WHERE  pf."feature_type" IN ('lines', 'multilinestrings')
      AND  tag.value:"key"::STRING = 'highway'
      AND  ST_Intersects( d.geom , ST_GEOGFROMWKB( pf."geometry") )
)

SELECT
       highway_type,
       ROUND( SUM(metres) / 1000 , 1 ) AS total_length_km
FROM   dk_highways
GROUP  BY highway_type
ORDER  BY total_length_km DESC NULLS LAST
LIMIT  5;