WITH multi_app_families AS (
    SELECT "family_id"
    FROM PATENTS.PATENTS.PUBLICATIONS
    GROUP BY "family_id"
    HAVING COUNT(DISTINCT "application_number") > 1
),
cn_granted_2010_2023 AS (
    SELECT "publication_number",
           "family_id"
    FROM PATENTS.PATENTS.PUBLICATIONS
    WHERE "country_code" = 'CN'
      AND "grant_date" BETWEEN 20100101 AND 20231231
)
SELECT COUNT(*) AS "patent_count"
FROM cn_granted_2010_2023 AS p
JOIN multi_app_families AS f
  ON p."family_id" = f."family_id";