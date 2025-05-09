WITH "institution_counts" AS (
    SELECT 
        "zip_code",
        COUNT(DISTINCT "institution_name") AS "institution_cnt"
    FROM FDA.FDIC_BANKS.LOCATIONS
    WHERE 
        "state" = 'FL'
        AND "zip_code" IS NOT NULL
    GROUP BY 
        "zip_code"
)
SELECT 
    "zip_code"
FROM 
    "institution_counts"
ORDER BY 
    "institution_cnt" DESC NULLS LAST
LIMIT 1;