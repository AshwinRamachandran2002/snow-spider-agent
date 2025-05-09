WITH cn_grants_2010_2023 AS (
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
    FROM cn_grants_2010_2023
    GROUP BY "family_id"
    HAVING COUNT(DISTINCT "application_number") > 1
)
SELECT
    COUNT(*) AS "num_cn_patents_2010_2023_in_families_with_gt1_app"
FROM cn_grants_2010_2023
WHERE "family_id" IN (
    SELECT "family_id"
    FROM families_with_multiple_apps
);