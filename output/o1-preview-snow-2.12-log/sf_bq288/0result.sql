WITH state_with_highest_assets AS (
    SELECT "state_name"
    FROM "FDA"."FDIC_BANKS"."INSTITUTIONS"
    WHERE "institution_name" ILIKE 'Bank%'
      AND "established_date" BETWEEN '1900-01-01' AND '2000-12-31'
      AND "total_assets" IS NOT NULL
    GROUP BY "state_name"
    ORDER BY SUM("total_assets") DESC NULLS LAST
    LIMIT 1
)
SELECT COUNT(*) AS "Total_number_of_banking_institutions"
FROM "FDA"."FDIC_BANKS"."INSTITUTIONS"
WHERE "state_name" = (SELECT "state_name" FROM state_with_highest_assets);