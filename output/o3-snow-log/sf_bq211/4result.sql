WITH family_multiple_apps AS (
    /* families that have more than one distinct application */
    SELECT 
        "family_id"
    FROM PATENTS.PATENTS.PUBLICATIONS
    WHERE "application_number" IS NOT NULL
    GROUP BY "family_id"
    HAVING COUNT(DISTINCT "application_number") > 1
),
cn_granted_2010_2023 AS (
    /* CN patents granted between 2010-01-01 and 2023-12-31 */
    SELECT 
        "publication_number",
        "family_id"
    FROM PATENTS.PATENTS.PUBLICATIONS
    WHERE "country_code" = 'CN'
      AND "grant_date" BETWEEN 20100101 AND 20231231
      AND "grant_date" <> 0
)
SELECT 
    COUNT(*) AS "num_cn_granted_patents_with_family_gt1_app"
FROM cn_granted_2010_2023  cg
JOIN family_multiple_apps fa
  ON cg."family_id" = fa."family_id";