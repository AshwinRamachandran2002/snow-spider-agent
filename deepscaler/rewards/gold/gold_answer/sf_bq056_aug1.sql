-- Task: How many roads classified as motorway, trunk, primary, secondary, or residential in California do not have a bridge tag?

WITH california AS (
    SELECT ST_GEOMFROMWKB("state_geom", 4326) AS "state_geom"
    FROM GEO_OPENSTREETMAP_BOUNDARIES.GEO_US_BOUNDARIES.STATES
    WHERE "state_name" = 'California'
),
ways_with_tags AS (
    SELECT t."id", t."geometry", t."nodes",
        OBJECT_AGG(tag.value:"key"::VARCHAR, tag.value:"value") AS "tags"
    FROM GEO_OPENSTREETMAP_BOUNDARIES.GEO_OPENSTREETMAP.PLANET_WAYS t,
         LATERAL FLATTEN(input => t."all_tags") tag
    GROUP BY t."id", t."geometry", t."nodes"
),
filtered_ways AS (
    SELECT w."id", w."geometry", w."nodes"
    FROM ways_with_tags w, california
    WHERE w."tags":highway::STRING IN ('motorway', 'trunk', 'primary', 'secondary', 'residential')
      AND w."tags":bridge IS NULL
      AND ST_INTERSECTS(
            ST_GEOMFROMWKB(w."geometry", 4326), 
            california."state_geom"
          )
)
SELECT COUNT(*) AS "number_of_roads"
FROM filtered_ways;