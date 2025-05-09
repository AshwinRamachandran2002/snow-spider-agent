/* patents granted in CN (China) between 2010‑01‑01 and 2023‑12‑31
   whose simple‑family owns more than one distinct application        */

SELECT COUNT(*) AS "patent_count"
FROM PATENTS.PATENTS.PUBLICATIONS p
WHERE p."country_code" = 'CN'
  AND p."grant_date" BETWEEN 20100101 AND 20231231
  AND p."family_id" IN (
        SELECT "family_id"
        FROM PATENTS.PATENTS.PUBLICATIONS
        WHERE "application_number" IS NOT NULL
        GROUP BY "family_id"
        HAVING COUNT(DISTINCT "application_number") > 1
      );