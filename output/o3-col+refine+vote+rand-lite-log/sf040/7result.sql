/* Top 10 northern-most (highest latitude) unique addresses—
   by number / street / street type—
   within the Florida ZIP code that contains the greatest
   total count of addresses. */

WITH fl_zip_counts AS (
    SELECT
        "ZIP",
        COUNT(*) AS "address_cnt"
    FROM US_ADDRESSES__POI.CYBERSYN.US_ADDRESSES
    WHERE "STATE" = 'FL'
    GROUP BY "ZIP"
),
largest_zip AS (           -- Florida ZIP with the most addresses
    SELECT "ZIP"
    FROM fl_zip_counts
    ORDER BY "address_cnt" DESC NULLS LAST
    LIMIT 1
),
dedup AS (                  -- one record per unique address
    SELECT
        "NUMBER",
        "STREET",
        "STREET_TYPE",
        MAX("LATITUDE") AS "MAX_LAT"
    FROM US_ADDRESSES__POI.CYBERSYN.US_ADDRESSES
    WHERE "STATE" = 'FL'
      AND "ZIP" = (SELECT "ZIP" FROM largest_zip)
    GROUP BY
        "NUMBER",
        "STREET",
        "STREET_TYPE"
),
top10 AS (                  -- ten northern-most addresses
    SELECT *
    FROM dedup
    ORDER BY "MAX_LAT" DESC NULLS LAST
    LIMIT 10
)
SELECT
    "NUMBER",
    "STREET",
    "STREET_TYPE"
FROM top10
ORDER BY "MAX_LAT" DESC NULLS LAST;