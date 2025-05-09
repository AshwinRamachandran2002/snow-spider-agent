WITH fl_addresses AS (
    SELECT
        "ZIP",
        "NUMBER",
        "STREET",
        "STREET_TYPE",
        "LATITUDE"
    FROM "US_ADDRESSES__POI"."CYBERSYN"."US_ADDRESSES"
    WHERE "STATE" = 'FL'
),
largest_zip AS (
    SELECT "ZIP"
    FROM fl_addresses
    GROUP BY "ZIP"
    ORDER BY COUNT(*) DESC
    LIMIT 1
),
dedup AS (
    SELECT
        "NUMBER",
        "STREET",
        "STREET_TYPE",
        MAX("LATITUDE") AS "LATITUDE"
    FROM fl_addresses
    WHERE "ZIP" = (SELECT "ZIP" FROM largest_zip)
    GROUP BY "NUMBER", "STREET", "STREET_TYPE"
),
ranked AS (
    SELECT
        "NUMBER",
        "STREET",
        "STREET_TYPE",
        ROW_NUMBER() OVER (
            ORDER BY "LATITUDE" DESC NULLS LAST,
                     "NUMBER",
                     "STREET"
        ) AS rn
    FROM dedup
)
SELECT
    "NUMBER"      AS address_number,
    "STREET"      AS street_name,
    "STREET_TYPE" AS street_type
FROM ranked
WHERE rn <= 10;