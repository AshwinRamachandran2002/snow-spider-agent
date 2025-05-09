SELECT
    loc."zip_code"
FROM
    FDA.FDIC_BANKS.LOCATIONS AS loc
JOIN
    FDA.GEO_US_BOUNDARIES.ZIP_CODES AS z
    ON loc."zip_code" = z."zip_code"
WHERE
    z."state_code" = 'FL'
GROUP BY
    loc."zip_code"
ORDER BY
    COUNT(DISTINCT loc."institution_name") DESC NULLS LAST
LIMIT 1;