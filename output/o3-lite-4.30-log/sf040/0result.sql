SELECT
    "NUMBER",
    "STREET",
    "STREET_TYPE"
FROM US_ADDRESSES__POI.CYBERSYN.US_ADDRESSES
WHERE "STATE" = 'FL'
  AND "ZIP" = (
        SELECT "ZIP"
        FROM (
              SELECT
                  "ZIP",
                  COUNT(*) AS address_cnt,
                  ROW_NUMBER() OVER (ORDER BY COUNT(*) DESC) AS rn
              FROM US_ADDRESSES__POI.CYBERSYN.US_ADDRESSES
              WHERE "STATE" = 'FL'
              GROUP BY "ZIP"
            )
        WHERE rn = 1
      )
ORDER BY
    "LATITUDE" DESC NULLS LAST,
    "NUMBER",
    "STREET"
LIMIT 10;