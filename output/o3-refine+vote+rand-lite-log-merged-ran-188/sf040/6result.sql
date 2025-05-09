WITH fl_zip_rank AS (   -- rank Florida ZIP codes by address count
    SELECT
        "ZIP",
        COUNT(*)                          AS "address_cnt",
        ROW_NUMBER() OVER (ORDER BY COUNT(*) DESC) AS "rn"
    FROM US_ADDRESSES__POI.CYBERSYN.US_ADDRESSES
    WHERE "STATE" = 'FL'
    GROUP BY "ZIP"
)

SELECT
    ua."NUMBER"       AS "address_number",
    ua."STREET"       AS "street_name",
    ua."STREET_TYPE"  AS "street_type"
FROM US_ADDRESSES__POI.CYBERSYN.US_ADDRESSES ua
JOIN fl_zip_rank zr
      ON ua."ZIP" = zr."ZIP"
WHERE zr."rn" = 1                       -- keep only Florida's largest ZIP
ORDER BY ua."LATITUDE" DESC NULLS LAST  -- northern-most first
LIMIT 10;