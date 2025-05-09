WITH families_with_multiple_apps AS (
    SELECT 
        "family_id"
    FROM PATENTS.PATENTS.PUBLICATIONS
    WHERE "application_number" IS NOT NULL
    GROUP BY "family_id"
    HAVING COUNT(DISTINCT "application_number") > 1
),
cn_granted_2010_2023 AS (
    SELECT 
        "publication_number",
        "family_id"
    FROM PATENTS.PATENTS.PUBLICATIONS
    WHERE "country_code" = 'CN'
      AND "grant_date" BETWEEN 20100101 AND 20231231
)
SELECT 
    COUNT(*) AS "num_patents"
FROM cn_granted_2010_2023 cg
JOIN families_with_multiple_apps f
  ON cg."family_id" = f."family_id";