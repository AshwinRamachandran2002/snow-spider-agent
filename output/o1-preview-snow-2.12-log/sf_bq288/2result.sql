WITH TopState AS (
    SELECT "state_name"
    FROM (
        SELECT "state_name", SUM("total_assets") AS "total_assets_sum"
        FROM FDA.FDIC_BANKS.INSTITUTIONS
        WHERE "institution_name" LIKE 'Bank%'
          AND "established_date" BETWEEN '1900-01-01' AND '2000-12-31'
        GROUP BY "state_name"
        ORDER BY "total_assets_sum" DESC NULLS LAST
        LIMIT 1
    )
)
SELECT COUNT(DISTINCT "fdic_certificate_number") AS "Total_number_of_banking_institutions"
FROM FDA.FDIC_BANKS.INSTITUTIONS
WHERE "state_name" = (SELECT "state_name" FROM TopState);