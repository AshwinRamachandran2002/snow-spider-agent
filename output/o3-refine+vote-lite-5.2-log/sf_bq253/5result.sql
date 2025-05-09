WITH qgeom AS (   -- geometry of the multipolygon whose wikidata tag = Q1095
    SELECT ST_UNION_AGG( ST_GEOGFROMWKB(pf."geometry") ) AS geom
    FROM GEO_OPENSTREETMAP.GEO_OPENSTREETMAP."PLANET_FEATURES"  pf,
         LATERAL FLATTEN( INPUT => pf."all_tags") tag
    WHERE tag.value:"key"::string   = 'wikidata'
      AND tag.value:"value"::string = 'Q1095'
      AND pf."geometry" IS NOT NULL
),

relations AS (    -- candidate relations: have a name, but no wikidata tag
    SELECT
        r."id",
        MAX( CASE WHEN t.value:"key"::string = 'name'
                  THEN t.value:"value"::string END ) AS name,
        MAX( CASE WHEN t.value:"key"::string = 'wikidata'
                  THEN 1 ELSE 0 END )               AS has_wikidata,
        r."geometry"                                AS geom_wkb
    FROM GEO_OPENSTREETMAP.GEO_OPENSTREETMAP."PLANET_RELATIONS" r,
         LATERAL FLATTEN( INPUT => r."all_tags") t
    WHERE r."geometry" IS NOT NULL
    GROUP BY r."id", r."geometry"
    HAVING name IS NOT NULL
       AND has_wikidata = 0
),

rel_in_area AS (  -- relations that intersect the Q1095 geometry
    SELECT r.*
    FROM relations r, qgeom
    WHERE ST_INTERSECTS( ST_GEOGFROMWKB(r.geom_wkb), qgeom.geom )
),

features AS (     -- planet features, marking whether each has a wikidata tag
    SELECT
        pf."geometry"                                  AS geom_wkb,
        MAX( CASE WHEN ft.value:"key"::string = 'wikidata'
                  THEN 1 ELSE 0 END )  AS has_wikidata
    FROM GEO_OPENSTREETMAP.GEO_OPENSTREETMAP."PLANET_FEATURES" pf,
         LATERAL FLATTEN( INPUT => pf."all_tags") ft
    WHERE pf."geometry" IS NOT NULL
    GROUP BY pf."geometry"
),

relation_counts AS (   -- count how many features each relation intersects
    SELECT
        r.name,
        COUNT(*)                     AS feature_count,
        SUM(f.has_wikidata)          AS wiki_feature_count
    FROM rel_in_area r
    JOIN features   f
      ON ST_INTERSECTS( ST_GEOGFROMWKB(r.geom_wkb),
                        ST_GEOGFROMWKB(f.geom_wkb) )
    GROUP BY r.name
    HAVING wiki_feature_count >= 1   -- at least one intersecting feature has wikidata
)

SELECT name
FROM relation_counts
ORDER BY feature_count DESC NULLS LAST, name
LIMIT 1;