WITH multi_app_families AS (
    SELECT 
        "family_id"
    FROM PATENTS.PATENTS.PUBLICATIONS
    WHERE "country_code" = 'CN'
      AND "grant_date" BETWEEN 20100101 AND 20231231
    GROUP BY "family_id"
    HAVING COUNT(DISTINCT "application_number") > 1
)
SELECT 
    COUNT(*) AS "num_cn_grants_in_multi_app_families"
FROM PATENTS.PATENTS.PUBLICATIONS AS p
JOIN multi_app_families AS f
  ON p."family_id" = f."family_id"
WHERE p."country_code" = 'CN'
  AND p."grant_date" BETWEEN 20100101 AND 20231231;