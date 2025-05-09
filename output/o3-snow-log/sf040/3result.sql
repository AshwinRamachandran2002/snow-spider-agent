WITH fl_addresses AS (
    SELECT 
        "NUMBER",
        "STREET",
        "STREET_TYPE",
        "LATITUDE",
        "ZIP"
    FROM US_ADDRESSES__POI.CYBERSYN.US_ADDRESSES
    WHERE "STATE" = 'FL'
), 
zip_counts AS (
    SELECT 
        "ZIP",
        COUNT(*) AS address_count
    FROM fl_addresses
    GROUP BY "ZIP"
), 
largest_zip AS (
    SELECT 
        "ZIP"
    FROM zip_counts
    ORDER BY address_count DESC NULLS LAST
    LIMIT 1
), 
addresses_in_largest_zip AS (
    SELECT 
        "NUMBER",
        "STREET",
        "STREET_TYPE",
        "LATITUDE"
    FROM fl_addresses
    WHERE "ZIP" IN (SELECT "ZIP" FROM largest_zip)
)
SELECT 
    "NUMBER"       AS "ADDRESS_NUMBER",
    "STREET"       AS "STREET_NAME",
    "STREET_TYPE"
FROM addresses_in_largest_zip
ORDER BY "LATITUDE" DESC NULLS LAST
LIMIT 10;