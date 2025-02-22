-- Task: For United States utility patents under the B2 classification granted between 2010 and 2014, find the one with the most forward citations within a month of its filing date.
WITH "TopPatent" AS (
  SELECT 
    p."publication_number" AS "pub_num",
    TRY_TO_DATE(p."filing_date"::VARCHAR, 'YYYYMMDD') AS "filing_date",
    COUNT(DISTINCT f.value:"publication_number"::STRING) AS "forward_citations_within_30_days"
  FROM PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS p
  JOIN PATENTS_GOOGLE.PATENTS_GOOGLE.ABS_AND_EMB a
    ON p."publication_number" = a."publication_number"
  LEFT JOIN LATERAL FLATTEN(input => a."cited_by") f
  LEFT JOIN PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS c
    ON f.value:"publication_number"::STRING = c."publication_number"
  WHERE p."country_code" = 'US'
    AND p."kind_code" LIKE '%B2'
    AND p."grant_date" BETWEEN 20100101 AND 20141231
    AND TRY_TO_DATE(p."filing_date"::VARCHAR, 'YYYYMMDD') IS NOT NULL
    AND TRY_TO_DATE(c."filing_date"::VARCHAR, 'YYYYMMDD') IS NOT NULL
    AND DATEDIFF('day', TRY_TO_DATE(p."filing_date"::VARCHAR, 'YYYYMMDD'), TRY_TO_DATE(c."filing_date"::VARCHAR, 'YYYYMMDD')) BETWEEN 0 AND 30
  GROUP BY p."publication_number", p."filing_date"
  ORDER BY "forward_citations_within_30_days" DESC NULLS LAST
  LIMIT 1
)
SELECT * FROM "TopPatent";