WITH family_application_counts AS (
    SELECT 
        "family_id",
        COUNT(DISTINCT "application_number") AS "distinct_applications"
    FROM PATENTS.PATENTS.PUBLICATIONS
    GROUP BY "family_id"
    HAVING COUNT(DISTINCT "application_number") > 1
),
cn_granted_2010_2023 AS (
    SELECT 
        "publication_number",
        "family_id"
    FROM PATENTS.PATENTS.PUBLICATIONS
    WHERE 
        "country_code" = 'CN'
        AND "grant_date" BETWEEN 20100101 AND 20231231
)
SELECT 
    COUNT(*) AS "num_cn_grants_in_families_with_multiple_applications"
FROM cn_granted_2010_2023 cg
JOIN family_application_counts fa
  ON cg."family_id" = fa."family_id";