WITH denmark AS (
  SELECT ST_GEOGRAPHYFROMWKB("geometry") AS denmark_geom
  FROM "GEO_OPENSTREETMAP"."GEO_OPENSTREETMAP"."PLANET_FEATURES" t, 
       LATERAL FLATTEN(INPUT => PARSE_JSON(t."all_tags")) f
  WHERE f.value:"key"::STRING = 'wikidata' AND f.value:"value"::STRING = 'Q35'
  LIMIT 1
),
highway_features AS (
  SELECT
    ST_GEOGRAPHYFROMWKB(t."geometry") AS geom_geog,
    f_highway.value:"value"::STRING AS highway_type
  FROM
    "GEO_OPENSTREETMAP"."GEO_OPENSTREETMAP"."PLANET_FEATURES" t,
    LATERAL FLATTEN(INPUT => PARSE_JSON(t."all_tags")) f_highway
  WHERE
    f_highway.value:"key"::STRING = 'highway'
)
SELECT
  hf.highway_type,
  ROUND(SUM(ST_LENGTH(ST_INTERSECTION(hf.geom_geog, denmark.denmark_geom))), 4) AS total_length_meters
FROM
  highway_features hf
  JOIN denmark ON ST_INTERSECTS(hf.geom_geog, denmark.denmark_geom)
GROUP BY
  hf.highway_type
ORDER BY
  total_length_meters DESC NULLS LAST
LIMIT 5;