WITH fl_zip_counts AS (  -- count addresses per Florida ZIP
    SELECT 
        "ZIP",
        COUNT(*) AS "address_cnt"
    FROM US_ADDRESSES__POI.CYBERSYN.US_ADDRESSES
    WHERE "STATE" = 'FL'
    GROUP BY "ZIP"
),
largest_zip AS (         -- identify the single largest‑count ZIP
    SELECT 
        "ZIP"
    FROM fl_zip_counts
    QUALIFY ROW_NUMBER() OVER (ORDER BY "address_cnt" DESC) = 1
),
fl_addresses_largest AS (  -- all addresses inside that ZIP
    SELECT
        a."NUMBER"       AS "address_number",
        a."STREET"       AS "street_name",
        a."STREET_TYPE"  AS "street_type",
        a."LATITUDE",
        a."LONGITUDE"
    FROM US_ADDRESSES__POI.CYBERSYN.US_ADDRESSES a
    JOIN largest_zip l
      ON a."ZIP" = l."ZIP"
    WHERE a."LATITUDE" IS NOT NULL
)
SELECT 
    "address_number",
    "street_name",
    "street_type"
FROM fl_addresses_largest
ORDER BY 
    "LATITUDE" DESC NULLS LAST,   -- northernmost first
    "LONGITUDE" DESC NULLS LAST   -- tie‑breaker: further east
LIMIT 10;