WITH fl_addresses AS (   -- all addresses in Florida with usable coords & ZIP
    SELECT 
        "ADDRESS_ID",
        "ZIP",
        "LATITUDE",
        "NUMBER",
        "STREET",
        "STREET_TYPE"
    FROM US_ADDRESSES__POI.CYBERSYN.US_ADDRESSES
    WHERE "ID_STATE" = 'geoId/12'          -- Florida
      AND "ZIP" IS NOT NULL
      AND "LATITUDE" IS NOT NULL
), 
zip_counts AS (          -- count addresses per ZIP
    SELECT 
        "ZIP",
        COUNT(*) AS address_cnt
    FROM fl_addresses
    GROUP BY "ZIP"
), 
largest_zip AS (         -- ZIP with the most Florida addresses
    SELECT "ZIP"
    FROM zip_counts
    ORDER BY address_cnt DESC NULLS LAST
    LIMIT 1
), 
target_addresses AS (    -- all addresses inside that ZIP
    SELECT 
        fa."NUMBER",
        fa."STREET",
        fa."STREET_TYPE",
        fa."LATITUDE"
    FROM fl_addresses fa
    JOIN largest_zip l
      ON fa."ZIP" = l."ZIP"
)
SELECT                    -- 10 northern-most addresses in that ZIP
    "NUMBER",
    "STREET",
    "STREET_TYPE"
FROM target_addresses
ORDER BY "LATITUDE" DESC NULLS LAST
LIMIT 10;