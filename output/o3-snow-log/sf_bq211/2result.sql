WITH fam_multi AS (
    SELECT "family_id"
    FROM PATENTS.PATENTS.PUBLICATIONS
    WHERE "application_number" IS NOT NULL
    GROUP BY "family_id"
    HAVING COUNT(DISTINCT "application_number") > 1
),
cn_granted AS (
    SELECT "family_id"
    FROM PATENTS.PATENTS.PUBLICATIONS
    WHERE "country_code" = 'CN'
      AND "grant_date" BETWEEN 20100101 AND 20231231
)
SELECT COUNT(*) AS "cn_granted_patents_with_multi_application_families"
FROM cn_granted
WHERE "family_id" IN (SELECT "family_id" FROM fam_multi);