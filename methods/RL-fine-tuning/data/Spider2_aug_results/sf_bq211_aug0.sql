-- Task: Determine the number of patents granted in China between January 1, 2010 and December 31, 2023, that are part of patent families with more than one distinct application number in total.
SELECT COUNT(*) AS "number_of_patents"
FROM PATENTS.PATENTS.PUBLICATIONS
WHERE "country_code" = 'CN' 
  AND "grant_date" BETWEEN 20100101 AND 20231231
  AND "family_id" IN (
    SELECT "family_id"
    FROM PATENTS.PATENTS.PUBLICATIONS
    GROUP BY "family_id"
    HAVING COUNT(DISTINCT "application_number") > 1
  );