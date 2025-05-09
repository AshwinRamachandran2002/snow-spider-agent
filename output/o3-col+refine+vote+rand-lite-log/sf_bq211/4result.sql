SELECT
  COUNT(*) AS "cn_patent_grants_2010_2023_multi_app_family"
FROM PATENTS.PATENTS.PUBLICATIONS p
WHERE p."country_code" = 'CN'
  AND p."grant_date" BETWEEN 20100101 AND 20231231
  AND p."family_id" IN (
        SELECT "family_id"
        FROM PATENTS.PATENTS.PUBLICATIONS
        WHERE "country_code" = 'CN'
          AND "grant_date" BETWEEN 20100101 AND 20231231
          AND "application_number" IS NOT NULL
          AND "application_number" <> ''
        GROUP BY "family_id"
        HAVING COUNT(DISTINCT "application_number") > 1
  );