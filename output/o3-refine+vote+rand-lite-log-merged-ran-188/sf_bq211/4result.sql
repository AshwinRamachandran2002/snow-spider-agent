WITH multi_app_families AS (   -- families that have >1 distinct application numbers
    SELECT
        "family_id"
    FROM
        "PATENTS"."PATENTS"."PUBLICATIONS"
    GROUP BY
        "family_id"
    HAVING
        COUNT(DISTINCT "application_number") > 1
)

SELECT
    COUNT(*) AS "cn_patent_count"
FROM
    "PATENTS"."PATENTS"."PUBLICATIONS"  p
WHERE
    p."country_code" = 'CN'
    AND p."grant_date" BETWEEN 20100101 AND 20231231
    AND p."family_id" IN (SELECT "family_id" FROM multi_app_families);