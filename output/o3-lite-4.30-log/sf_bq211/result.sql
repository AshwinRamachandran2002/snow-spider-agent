WITH cn_grants_2010_2023 AS (           -- Chinese patents granted 2010‑2023
    SELECT
        "family_id",
        "publication_number"
    FROM PATENTS.PATENTS.PUBLICATIONS
    WHERE "country_code" = 'CN'
      AND "grant_date" BETWEEN 20100101 AND 20231231
),
families_with_multiple_apps AS (        -- families having >1 distinct applications
    SELECT "family_id"
    FROM PATENTS.PATENTS.PUBLICATIONS
    WHERE "application_number" IS NOT NULL
    GROUP BY "family_id"
    HAVING COUNT(DISTINCT "application_number") > 1
)
SELECT COUNT(*) AS patent_count         -- final answer
FROM cn_grants_2010_2023
WHERE "family_id" IN (SELECT "family_id" FROM families_with_multiple_apps);