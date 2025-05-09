WITH "TopPatent" AS (
  SELECT 
    p."publication_number" AS "pub_num1",
    TRY_TO_DATE(p."filing_date"::VARCHAR, 'YYYYMMDD') AS "filing_date_A",
    EXTRACT(YEAR FROM TRY_TO_DATE(p."filing_date"::VARCHAR, 'YYYYMMDD')) AS "filing_year_A",
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
),
"PatentA" AS (
  SELECT 
    t."pub_num1",
    t."filing_date_A",
    t."filing_year_A",
    a_emb.VALUE::FLOAT AS "embedding_A_value",
    a_emb."INDEX" AS "embedding_index"
  FROM "TopPatent" t
  JOIN PATENTS_GOOGLE.PATENTS_GOOGLE.ABS_AND_EMB a
    ON t."pub_num1" = a."publication_number"
  , LATERAL FLATTEN(input => a."embedding_v1") a_emb
),
"PatentB" AS (
  SELECT 
    p."publication_number" AS "pub_num2",
    a_emb.VALUE::FLOAT AS "embedding_B_value",
    a_emb."INDEX" AS "embedding_index"
  FROM PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS p
  JOIN PATENTS_GOOGLE.PATENTS_GOOGLE.ABS_AND_EMB a
    ON p."publication_number" = a."publication_number"
  , LATERAL FLATTEN(input => a."embedding_v1") a_emb
  WHERE 
    TRY_TO_DATE(p."filing_date"::VARCHAR, 'YYYYMMDD') IS NOT NULL
    AND EXTRACT(YEAR FROM TRY_TO_DATE(p."filing_date"::VARCHAR, 'YYYYMMDD')) = (SELECT "filing_year_A" FROM "TopPatent")
    AND p."publication_number" <> (SELECT "pub_num1" FROM "TopPatent")
)
SELECT 
  a."pub_num1" AS "publication_number",
  b."pub_num2" AS "most_similar_publication_number",
  ROUND(SUM(a."embedding_A_value" * b."embedding_B_value"), 4) AS "similarity"
FROM "PatentA" a
JOIN "PatentB" b ON a."embedding_index" = b."embedding_index"
GROUP BY a."pub_num1", b."pub_num2"
ORDER BY "similarity" DESC NULLS LAST
LIMIT 1;