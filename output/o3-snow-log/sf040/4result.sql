WITH fl_addresses AS (
    SELECT 
        "ZIP",
        "LATITUDE",
        "NUMBER",
        "STREET",
        "STREET_TYPE"
    FROM US_ADDRESSES__POI.CYBERSYN.US_ADDRESSES
    WHERE "STATE" = 'FL'          -- Florida addresses
),

largest_fl_zip AS (               -- Florida ZIP with the most addresses
    SELECT 
        "ZIP"
    FROM fl_addresses
    GROUP BY "ZIP"
    ORDER BY COUNT(*) DESC NULLS LAST
    LIMIT 1
),

ranked_addresses AS (             -- Rank addresses in that ZIP from north to south
    SELECT 
        fa."NUMBER",
        fa."STREET",
        fa."STREET_TYPE",
        ROW_NUMBER() OVER (ORDER BY fa."LATITUDE" DESC NULLS LAST) AS rn
    FROM fl_addresses fa
    JOIN largest_fl_zip lz
      ON fa."ZIP" = lz."ZIP"
)

SELECT 
    "NUMBER"         AS "ADDRESS_NUMBER",
    "STREET"         AS "STREET_NAME",
    "STREET_TYPE"
FROM ranked_addresses
WHERE rn <= 10                    -- Top 10 northernmost
ORDER BY rn;