WITH families_with_multiple_apps AS (
    SELECT
        "family_id"
    FROM
        PATENTS.PATENTS.PUBLICATIONS
    WHERE
        "application_number" IS NOT NULL
    GROUP BY
        "family_id"
    HAVING
        COUNT(DISTINCT "application_number") > 1
)

SELECT
    COUNT(*) AS "cn_granted_patents_2010_2023_with_multiple_family_applications"
FROM
    PATENTS.PATENTS.PUBLICATIONS AS p
JOIN
    families_with_multiple_apps AS f
    ON p."family_id" = f."family_id"
WHERE
    p."country_code" = 'CN'
    AND p."grant_date" BETWEEN 20100101 AND 20231231;