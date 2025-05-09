WITH family_app_counts AS (
    SELECT 
        "family_id",
        COUNT(DISTINCT "application_number") AS app_cnt
    FROM PATENTS.PATENTS.PUBLICATIONS
    WHERE "family_id" IS NOT NULL
          AND "application_number" IS NOT NULL
    GROUP BY "family_id"
),
eligible_families AS (
    SELECT "family_id"
    FROM family_app_counts
    WHERE app_cnt > 1
),
cn_granted_2010_2023 AS (
    SELECT 
        "publication_number",
        "family_id"
    FROM PATENTS.PATENTS.PUBLICATIONS
    WHERE "country_code" = 'CN'
          AND "grant_date" BETWEEN 20100101 AND 20231231
          AND "family_id" IS NOT NULL
)
SELECT 
    COUNT(*) AS "num_patents_in_multi_application_families"
FROM cn_granted_2010_2023 cg
JOIN eligible_families ef
  ON cg."family_id" = ef."family_id";