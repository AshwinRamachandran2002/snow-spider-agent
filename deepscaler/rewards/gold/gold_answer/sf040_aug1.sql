-- Task: List the zip codes and their areas in Florida. Limit the result to the top 100 entries.
WITH zip_areas AS (
    SELECT
        geo."GEO_ID",
        geo."GEO_NAME" AS zip,
        states."RELATED_GEO_NAME" AS state,
        countries."RELATED_GEO_NAME" AS country,
        ST_AREA(TRY_TO_GEOGRAPHY(value)) AS area
    FROM US_ADDRESSES__POI.CYBERSYN."GEOGRAPHY_INDEX" AS geo
    JOIN US_ADDRESSES__POI.CYBERSYN."GEOGRAPHY_RELATIONSHIPS" AS states
        ON (geo."GEO_ID" = states."GEO_ID" AND states."RELATED_LEVEL" = 'State')
    JOIN US_ADDRESSES__POI.CYBERSYN."GEOGRAPHY_RELATIONSHIPS" AS countries
        ON (geo."GEO_ID" = countries."GEO_ID" AND countries."RELATED_LEVEL" = 'Country')
    JOIN US_ADDRESSES__POI.CYBERSYN."GEOGRAPHY_CHARACTERISTICS" AS chars
        ON (geo."GEO_ID" = chars."GEO_ID" AND chars."RELATIONSHIP_TYPE" = 'coordinates_geojson')
    WHERE geo."LEVEL" = 'CensusZipCodeTabulationArea'
)
SELECT zip, area
FROM zip_areas
WHERE state = 'Florida' AND country = 'United States'
ORDER BY area DESC
LIMIT 100;