WITH "families_multi_app" AS (
    SELECT 
        "family_id"
    FROM PATENTS.PATENTS.PUBLICATIONS
    GROUP BY "family_id"
    HAVING COUNT(DISTINCT "application_number") > 1
)
SELECT 
    COUNT(*) AS "patent_count"
FROM PATENTS.PATENTS.PUBLICATIONS AS p
JOIN "families_multi_app" AS f
      ON p."family_id" = f."family_id"
WHERE p."country_code" = 'CN'
  AND p."grant_date" BETWEEN 20100101 AND 20231231;