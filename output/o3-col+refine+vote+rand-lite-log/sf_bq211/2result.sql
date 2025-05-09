WITH multi_app_families AS (
    SELECT "family_id"
    FROM PATENTS.PATENTS.PUBLICATIONS
    GROUP BY "family_id"
    HAVING COUNT(DISTINCT "application_number") > 1
)
SELECT 
    COUNT(*) AS "cn_patents_2010_2023_in_multi_app_families"
FROM PATENTS.PATENTS.PUBLICATIONS p
JOIN multi_app_families f
  ON p."family_id" = f."family_id"
WHERE p."country_code" = 'CN'
  AND p."grant_date" BETWEEN 20100101 AND 20231231;