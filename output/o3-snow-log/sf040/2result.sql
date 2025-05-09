WITH "FL_ADDRESSES" AS (  -- all Florida addresses
    SELECT 
        "ADDRESS_ID",
        "ID_ZIP",
        "LATITUDE",
        "NUMBER",
        "STREET",
        "STREET_TYPE"
    FROM US_ADDRESSES__POI.CYBERSYN.US_ADDRESSES
    WHERE "STATE" = 'FL'
),
"ZIP_COUNTS" AS (        -- largest FL ZIP by # of addresses
    SELECT 
        "ID_ZIP",
        COUNT(*) AS "ADDRESS_COUNT"
    FROM "FL_ADDRESSES"
    GROUP BY "ID_ZIP"
    ORDER BY "ADDRESS_COUNT" DESC
    LIMIT 1
),
"TARGET_ADDRESSES" AS (  -- addresses within that largest ZIP
    SELECT f.*
    FROM "FL_ADDRESSES" f
    JOIN "ZIP_COUNTS" z
      ON f."ID_ZIP" = z."ID_ZIP"
)
SELECT 
    "NUMBER",
    "STREET",
    "STREET_TYPE"
FROM "TARGET_ADDRESSES"
ORDER BY "LATITUDE" DESC NULLS LAST
LIMIT 10;