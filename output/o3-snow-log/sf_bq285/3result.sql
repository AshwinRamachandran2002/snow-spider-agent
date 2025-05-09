SELECT "zip_code"
FROM (
    SELECT
        "zip_code",
        COUNT(DISTINCT "institution_name") AS "institution_count"
    FROM FDA.FDIC_BANKS.LOCATIONS
    WHERE "state" = 'FL'
    GROUP BY "zip_code"
)
ORDER BY "institution_count" DESC NULLS LAST
LIMIT 1;