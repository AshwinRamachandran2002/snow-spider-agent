-- Count CN-origin granted publications (2010-2023) that are in families
-- containing more than one distinct application
WITH cn_grants AS (
    SELECT
        "family_id",
        "publication_number",
        "application_number"
    FROM PATENTS.PATENTS.PUBLICATIONS
    WHERE "country_code" = 'CN'
      AND "grant_date" BETWEEN 20100101 AND 20231231
),
multi_app_families AS (
    SELECT
        "family_id"
    FROM cn_grants
    GROUP BY "family_id"
    HAVING COUNT(DISTINCT "application_number") > 1
)
SELECT
    COUNT(*) AS "cn_granted_publications_in_multi_application_families"
FROM cn_grants
WHERE "family_id" IN (SELECT "family_id" FROM multi_app_families);