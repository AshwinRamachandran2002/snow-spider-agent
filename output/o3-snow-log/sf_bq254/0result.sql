WITH q191 AS (   -- Estonia (Q191) multipolygon
  SELECT
      TO_GEOGRAPHY("geometry")              AS geom ,
      ST_ENVELOPE(TO_GEOGRAPHY("geometry")) AS bbox
  FROM GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_FEATURES
  WHERE "feature_type" = 'multipolygons'
    AND "all_tags" ILIKE '%"wikidata","value":"Q191"%'
  LIMIT 1
),
candidates AS (  -- multipolygons in the same area, lacking a wikidata tag
  SELECT
      pf."osm_way_id",
      TO_GEOGRAPHY(pf."geometry") AS geom,
      pf."all_tags"
  FROM GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_FEATURES pf
  CROSS JOIN q191
  WHERE pf."feature_type" = 'multipolygons'
    AND pf."all_tags" NOT ILIKE '%"wikidata"%'
    AND ST_WITHIN( ST_CENTROID(TO_GEOGRAPHY(pf."geometry")) , q191.bbox )
),
points_in_bbox AS (  -- points in the same bounding box
  SELECT
      TO_GEOGRAPHY(pfp."geometry") AS geom
  FROM GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_FEATURES_POINTS pfp
  CROSS JOIN q191
  WHERE ST_WITHIN( TO_GEOGRAPHY(pfp."geometry") , q191.bbox )
),
scored AS (  -- count points inside each candidate polygon
  SELECT
      c."osm_way_id",
      c."all_tags",
      COUNT(*) AS pts_inside
  FROM candidates c
  JOIN points_in_bbox p
    ON ST_WITHIN(p.geom , c.geom)
  GROUP BY c."osm_way_id", c."all_tags"
),
named AS (   -- extract the name tag
  SELECT
      s."osm_way_id",
      f.value:"value"::STRING AS name,
      s.pts_inside
  FROM scored s,
       LATERAL FLATTEN(input => s."all_tags") f
  WHERE f.value:"key"::STRING = 'name'
)
SELECT
    "osm_way_id",
    name,
    pts_inside
FROM named
ORDER BY pts_inside DESC NULLS LAST
LIMIT 2;