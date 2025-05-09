WITH cn_granted_2010_2023 AS (
    SELECT 
        "family_id",
        "application_number",
        "publication_number"
    FROM PATENTS.PATENTS.PUBLICATIONS
    WHERE "country_code" = 'CN'
      AND "grant_date" BETWEEN 20100101 AND 20231231
),
families_with_multiple_apps AS (
    SELECT 
        "family_id"
    FROM cn_granted_2010_2023
    GROUP BY "family_id"
    HAVING COUNT(DISTINCT "application_number") > 1
)
SELECT 
    COUNT(*) AS "cn_granted_patents_in_multi_app_families"
FROM cn_granted_2010_2023 p
JOIN families_with_multiple_apps f
  ON p."family_id" = f."family_id";