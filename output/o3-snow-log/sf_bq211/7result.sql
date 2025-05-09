WITH cn_granted_2010_2023 AS (
    SELECT 
        "publication_number",
        "family_id"
    FROM PATENTS.PATENTS.PUBLICATIONS
    WHERE 
        "country_code" = 'CN'
        AND "grant_date" BETWEEN 20100101 AND 20231231
),
families_with_multiple_apps AS (
    SELECT 
        "family_id"
    FROM PATENTS.PATENTS.PUBLICATIONS
    GROUP BY "family_id"
    HAVING COUNT(DISTINCT "application_number") > 1
)
SELECT 
    COUNT(*) AS "num_cn_granted_patents_2010_2023_with_families_having_multiple_apps"
FROM cn_granted_2010_2023 cg
JOIN families_with_multiple_apps fa
  ON cg."family_id" = fa."family_id";