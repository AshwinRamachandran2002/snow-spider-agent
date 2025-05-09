/* 1) Filter all Florida addresses (ID_STATE = 'geoId/12')
   2) Find the ZIP code with the most addresses (“largest” by count)
   3) Within that ZIP, return the 10 addresses with the highest latitude
      (northern‑most), showing address number, street name, and street type       */

WITH fl_addresses AS (
    SELECT
        a."ID_ZIP",
        a."LATITUDE",
        a."NUMBER",
        a."STREET",
        a."STREET_TYPE"
    FROM "US_ADDRESSES__POI"."CYBERSYN"."US_ADDRESSES" a
    WHERE a."ID_STATE" = 'geoId/12'            -- Florida
      AND a."ID_ZIP"  IS NOT NULL
      AND a."LATITUDE" IS NOT NULL
),

zip_counts AS (                           -- count addresses per FL ZIP
    SELECT
        "ID_ZIP",
        COUNT(*) AS "ADDRESS_COUNT"
    FROM fl_addresses
    GROUP BY "ID_ZIP"
),

largest_zip AS (                          -- pick the ZIP with the most addresses
    SELECT "ID_ZIP"
    FROM zip_counts
    ORDER BY "ADDRESS_COUNT" DESC, "ID_ZIP"
    LIMIT 1
)

SELECT
    fa."NUMBER"       AS "ADDRESS_NUMBER",
    fa."STREET"       AS "STREET_NAME",
    fa."STREET_TYPE"  AS "STREET_TYPE"
FROM fl_addresses fa
JOIN largest_zip lz
  ON fa."ID_ZIP" = lz."ID_ZIP"
ORDER BY
    fa."LATITUDE" DESC NULLS LAST,        -- northern‑most first
    fa."NUMBER"
LIMIT 10;