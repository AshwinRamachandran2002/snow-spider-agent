SELECT
    "zip_code"
FROM
    FDA.FDIC_BANKS.LOCATIONS
WHERE
    "state" = 'FL'
GROUP BY
    "zip_code"
ORDER BY
    COUNT(DISTINCT "institution_name") DESC NULLS LAST
LIMIT 1;