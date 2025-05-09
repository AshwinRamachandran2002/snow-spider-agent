SELECT "zip_code"
FROM (
    SELECT
        "zip_code",
        COUNT(*) AS "institution_count"
    FROM FDA.FDIC_BANKS.INSTITUTIONS
    WHERE "state_name" = 'Florida'
    GROUP BY "zip_code"
    ORDER BY "institution_count" DESC NULLS LAST
    LIMIT 1
);