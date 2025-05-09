SELECT
  pub."publication_number",
  COUNT(*) AS "sea_backward_citation_count"
FROM PATENTS.PATENTS.PUBLICATIONS AS pub,
LATERAL FLATTEN(INPUT => pub."citation") AS cit
WHERE
      pub."grant_date" BETWEEN 20100101 AND 20181231
  AND cit.value:"category"::STRING = 'SEA'
GROUP BY
  pub."publication_number"
ORDER BY
  pub."publication_number";