WITH families_with_multiple_apps AS (
    SELECT
        "family_id"
    FROM "PATENTS"."PATENTS"."PUBLICATIONS"
    WHERE "family_id" IS NOT NULL
    GROUP BY "family_id"
    HAVING COUNT(DISTINCT "application_number") > 1
)
SELECT
    COUNT(*) AS "patent_count"
FROM "PATENTS"."PATENTS"."PUBLICATIONS"
WHERE "country_code" = 'CN'
  AND "grant_date" BETWEEN 20100101 AND 20231231
  AND "family_id" IN (SELECT "family_id" FROM families_with_multiple_apps);