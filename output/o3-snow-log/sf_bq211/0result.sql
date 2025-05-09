WITH families_with_multiple_apps AS (
    SELECT 
        "family_id"
    FROM "PATENTS"."PATENTS"."PUBLICATIONS"
    GROUP BY "family_id"
    HAVING COUNT(DISTINCT "application_number") > 1
),
cn_granted_2010_2023 AS (
    SELECT DISTINCT
        p."publication_number"
    FROM "PATENTS"."PATENTS"."PUBLICATIONS" AS p
    JOIN families_with_multiple_apps AS f
          ON p."family_id" = f."family_id"
    WHERE p."country_code" = 'CN'
      AND p."grant_date" BETWEEN 20100101 AND 20231231
)
SELECT COUNT(*) AS "num_patents"
FROM cn_granted_2010_2023;