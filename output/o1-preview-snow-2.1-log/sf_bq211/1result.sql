SELECT COUNT(*) AS "number_of_patents"
FROM PATENTS.PATENTS.PUBLICATIONS AS P
WHERE
  P."country_code" = 'CN'
  AND P."grant_date" BETWEEN 20100101 AND 20231231
  AND P."family_id" IN (
    SELECT "family_id"
    FROM PATENTS.PATENTS.PUBLICATIONS
    GROUP BY "family_id"
    HAVING COUNT(DISTINCT "application_number") > 1
  );