WITH denmark AS (
    SELECT
        ST_GEOGFROMWKB("geometry") AS geom
    FROM GEO_OPENSTREETMAP.GEO_OPENSTREETMAP."PLANET_RELATIONS"
    WHERE "visible" = TRUE
      AND "all_tags" ILIKE '%"wikidata"%Q35"%'
    LIMIT 1
)

SELECT
    f_tags.value:"value"::STRING                         AS "highway_type",
    SUM( ST_LENGTH( ST_GEOGFROMWKB(p."geometry") ) )     AS "total_length_m"
FROM GEO_OPENSTREETMAP.GEO_OPENSTREETMAP."PLANET_FEATURES" p,
     LATERAL FLATTEN(input => p."all_tags") f_tags,
     denmark d
WHERE p."feature_type" = 'lines'
  AND f_tags.value:"key"::STRING = 'highway'
  AND ST_WITHIN( ST_GEOGFROMWKB(p."geometry"), d.geom )
GROUP BY "highway_type"
ORDER BY "total_length_m" DESC NULLS LAST
LIMIT 5;