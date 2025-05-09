/* Five highway types with the greatest total length inside Denmark */
WITH dk AS (  -- Denmark multipolygon (wikidata = Q35)
    SELECT TO_GEOGRAPHY(r."geometry") AS geom
    FROM GEO_OPENSTREETMAP.GEO_OPENSTREETMAP."PLANET_RELATIONS" r,
         LATERAL FLATTEN(input => r."all_tags") tag
    WHERE tag.value:"key"::STRING  = 'wikidata'
      AND tag.value:"value"::STRING = 'Q35'
    LIMIT 1
),
hw_lengths AS (  -- length of every highway segment inside Denmark
    SELECT
        tag.value:"value"::STRING                      AS "highway_type",
        ST_LENGTH(TO_GEOGRAPHY(f."geometry"))          AS "length_m"
    FROM GEO_OPENSTREETMAP.GEO_OPENSTREETMAP."PLANET_FEATURES" f,
         LATERAL FLATTEN(input => f."all_tags") tag,
         dk
    WHERE f."geometry" IS NOT NULL
      AND f."feature_type" = 'lines'
      AND tag.value:"key"::STRING = 'highway'
      AND ST_INTERSECTS(TO_GEOGRAPHY(f."geometry"), dk.geom)
)
SELECT
    "highway_type",
    SUM("length_m") AS "total_length_m"
FROM hw_lengths
GROUP BY "highway_type"
ORDER BY "total_length_m" DESC NULLS LAST
LIMIT 5;