SELECT
       t."publication_number",
       COUNT(*) AS "sea_backward_citation_count"
FROM   PATENTS.PATENTS.PUBLICATIONS t,
       LATERAL FLATTEN(input => t."citation") f
WHERE  t."grant_date" BETWEEN 20100101 AND 20181231
  AND   REGEXP_LIKE(
          f.value:"category"::STRING,
          '(^|,)\\s*SEA\\s*(,|$)',
          'i'               -- case-insensitive
        )
GROUP  BY t."publication_number"
ORDER  BY t."publication_number";