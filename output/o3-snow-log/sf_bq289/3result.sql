WITH "PHILADELPHIA" AS (   -- polygon of Philadelphia, Pennsylvania, with SRID set
    SELECT ST_SETSRID(ST_GEOMFROMWKB("place_geom"), 4326) AS "geom"
    FROM GEO_OPENSTREETMAP_CENSUS_PLACES.GEO_US_CENSUS_PLACES.US_NATIONAL_PLACES
    WHERE "place_name" = 'Philadelphia'
      AND "state_name" = 'Pennsylvania'
),
"AMENITIES" AS (           -- libraries, places of worship, community centres inside the city
    SELECT
        ROW_NUMBER() OVER (ORDER BY (SELECT NULL))                         AS "amenity_id",
        ST_SETSRID(ST_GEOMFROMWKB(p."geometry"), 4326)                    AS "geom"
    FROM GEO_OPENSTREETMAP_CENSUS_PLACES.GEO_OPENSTREETMAP.PLANET_FEATURES_POINTS p,
         LATERAL FLATTEN(INPUT => p."all_tags")                            f,
         "PHILADELPHIA"                                                    ph
    WHERE f.value:"key"::string   = 'amenity'
      AND f.value:"value"::string IN ('library',
                                      'place_of_worship',
                                      'community_centre',
                                      'community_center')
      AND ST_CONTAINS(
              ph."geom",
              ST_SETSRID(ST_GEOMFROMWKB(p."geometry"), 4326)
          )
)
SELECT
    MIN(
        ST_DISTANCE(
            TO_GEOGRAPHY(a."geom"),
            TO_GEOGRAPHY(b."geom")
        )
    ) AS "shortest_distance_meters"
FROM "AMENITIES" a
JOIN "AMENITIES" b
  ON b."amenity_id" > a."amenity_id";