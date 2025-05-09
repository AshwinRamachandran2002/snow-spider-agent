WITH phl_boundary AS (   -- Philadelphia city limits
    SELECT ST_GEOMFROMWKB("place_geom", 4326) AS geom
    FROM   GEO_OPENSTREETMAP_CENSUS_PLACES.GEO_US_CENSUS_PLACES.PLACES_PENNSYLVANIA
    WHERE  "place_name" = 'Philadelphia'
),

phl_amenities AS (       -- Target amenities inside Philadelphia
    SELECT  ROW_NUMBER() OVER (ORDER BY (SELECT NULL))          AS id,
            ST_GEOMFROMWKB(p."geometry", 4326)                 AS g,
            f.value:"value"::STRING                            AS amenity
    FROM    GEO_OPENSTREETMAP_CENSUS_PLACES.GEO_OPENSTREETMAP.PLANET_FEATURES_POINTS p,
            phl_boundary b,
            LATERAL FLATTEN( INPUT => p."all_tags") f
    WHERE   f.value:"key"::STRING   = 'amenity'
      AND   f.value:"value"::STRING IN ('library','place_of_worship','community_centre')
      AND   ST_CONTAINS(b.geom, ST_GEOMFROMWKB(p."geometry", 4326))
)

SELECT  a.amenity  AS amenity_a,
        b.amenity  AS amenity_b,
        ST_DISTANCE(a.g, b.g) AS shortest_distance_meters
FROM    phl_amenities a
JOIN    phl_amenities b
  ON    a.id < b.id
ORDER BY shortest_distance_meters
LIMIT 1;