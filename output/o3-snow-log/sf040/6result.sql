WITH florida_zip_counts AS (
    SELECT
        "ZIP",
        COUNT(*) AS "ADDRESS_COUNT"
    FROM US_ADDRESSES__POI.CYBERSYN.US_ADDRESSES
    WHERE "STATE" = 'FL'
    GROUP BY "ZIP"
),
largest_fl_zip AS (
    SELECT "ZIP"
    FROM florida_zip_counts
    ORDER BY "ADDRESS_COUNT" DESC NULLS LAST
    LIMIT 1
)
SELECT
    ua."NUMBER",
    ua."STREET",
    ua."STREET_TYPE"
FROM US_ADDRESSES__POI.CYBERSYN.US_ADDRESSES ua
JOIN largest_fl_zip lz
  ON ua."ZIP" = lz."ZIP"
WHERE ua."STATE" = 'FL'
ORDER BY ua."LATITUDE" DESC NULLS LAST
LIMIT 10;