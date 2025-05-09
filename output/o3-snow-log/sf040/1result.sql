WITH fl_zip_counts AS (
    SELECT
        "ZIP",
        COUNT(*) AS "address_cnt"
    FROM US_ADDRESSES__POI.CYBERSYN.US_ADDRESSES
    WHERE "STATE" = 'FL'
      AND "ZIP" IS NOT NULL
    GROUP BY "ZIP"
),
largest_zip AS (
    SELECT "ZIP"
    FROM fl_zip_counts
    QUALIFY ROW_NUMBER() OVER (ORDER BY "address_cnt" DESC) = 1
),
fl_addresses_in_largest_zip AS (
    SELECT
        "NUMBER",
        "STREET",
        "STREET_TYPE",
        "LATITUDE"
    FROM US_ADDRESSES__POI.CYBERSYN.US_ADDRESSES
    WHERE "STATE" = 'FL'
      AND "ZIP" = (SELECT "ZIP" FROM largest_zip)
      AND "LATITUDE" IS NOT NULL
)
SELECT
    "NUMBER",
    "STREET",
    "STREET_TYPE"
FROM fl_addresses_in_largest_zip
ORDER BY "LATITUDE" DESC NULLS LAST
LIMIT 10;