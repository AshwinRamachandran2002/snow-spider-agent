WITH phila AS (   -- Philadelphia city polygon
    SELECT
        TO_GEOGRAPHY("place_geom") AS city_geom
    FROM GEO_OPENSTREETMAP_CENSUS_PLACES.GEO_US_CENSUS_PLACES.US_NATIONAL_PLACES
    WHERE UPPER("state_name") = 'PENNSYLVANIA'
      AND UPPER("place_name") LIKE 'PHILADELPHIA%'
    LIMIT 1
),
raw_amenities AS (   -- all candidate amenities
    SELECT
        TO_GEOGRAPHY(PFP."geometry") AS amen_geom
    FROM GEO_OPENSTREETMAP_CENSUS_PLACES.GEO_OPENSTREETMAP.PLANET_FEATURES_POINTS PFP,
         LATERAL FLATTEN(INPUT => PFP."all_tags") f
    WHERE UPPER(f.value:"key"::string) = 'AMENITY'
      AND UPPER(f.value:"value"::string) IN ('LIBRARY',
                                            'PLACE_OF_WORSHIP',
                                            'COMMUNITY_CENTRE',
                                            'COMMUNITY CENTER')
),
amenities AS (        -- amenities that lie inside Philadelphia
    SELECT
        ROW_NUMBER() OVER (
            ORDER BY ST_X(ra.amen_geom), ST_Y(ra.amen_geom)
        ) AS id,
        ra.amen_geom AS geog
    FROM raw_amenities ra
    CROSS JOIN phila p
    WHERE ST_CONTAINS(p.city_geom, ra.amen_geom)
)
SELECT
    MIN(ST_DISTANCE(a1.geog, a2.geog)) AS "SHORTEST_DISTANCE_METERS"
FROM amenities a1
JOIN amenities a2
  ON a1.id < a2.id;