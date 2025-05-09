WITH
citations_within_month AS (
  SELECT
    p."publication_number" AS pub_num1,
    TRY_TO_DATE(p."filing_date"::VARCHAR, 'YYYYMMDD') AS filing_date1,
    COUNT(DISTINCT f.value:"publication_number"::STRING) AS citation_count
  FROM
    PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS p
    JOIN PATENTS_GOOGLE.PATENTS_GOOGLE.ABS_AND_EMB ae ON p."publication_number" = ae."publication_number",
    LATERAL FLATTEN(input => ae."cited_by") f
    JOIN PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS p2 ON p2."publication_number" = f.value:"publication_number"::STRING
  WHERE
    p."country_code" = 'US'
    AND p."kind_code" LIKE '%B2%'
    AND p."grant_date" BETWEEN 20100101 AND 20141231
    AND TRY_TO_DATE(p."filing_date"::VARCHAR, 'YYYYMMDD') IS NOT NULL
    AND TRY_TO_DATE(p2."filing_date"::VARCHAR, 'YYYYMMDD') IS NOT NULL
    AND DATEDIFF(
      'day',
      TRY_TO_DATE(p."filing_date"::VARCHAR, 'YYYYMMDD'),
      TRY_TO_DATE(p2."filing_date"::VARCHAR, 'YYYYMMDD')
    ) BETWEEN 0 AND 30
  GROUP BY
    p."publication_number",
    TRY_TO_DATE(p."filing_date"::VARCHAR, 'YYYYMMDD')
),
max_citation_patent AS (
  SELECT
    pub_num1 AS publication_number,
    filing_date1,
    citation_count
  FROM
    citations_within_month
  ORDER BY
    citation_count DESC NULLS LAST
  LIMIT
    1
),
base_patent AS (
  SELECT
    m.publication_number,
    m.filing_date1,
    m.citation_count,
    ae1."embedding_v1" AS embedding1,
    YEAR(m.filing_date1) AS filing_year
  FROM
    max_citation_patent m
    JOIN PATENTS_GOOGLE.PATENTS_GOOGLE.ABS_AND_EMB ae1 ON m.publication_number = ae1."publication_number"
),
same_year_patents AS (
  SELECT
    p."publication_number" AS pub_num2,
    TRY_TO_DATE(p."filing_date"::VARCHAR, 'YYYYMMDD') AS filing_date2,
    ae2."embedding_v1" AS embedding2
  FROM
    PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS p
    JOIN PATENTS_GOOGLE.PATENTS_GOOGLE.ABS_AND_EMB ae2 ON p."publication_number" = ae2."publication_number"
  WHERE
    YEAR(TRY_TO_DATE(p."filing_date"::VARCHAR, 'YYYYMMDD')) = (
      SELECT
        filing_year
      FROM
        base_patent
    )
    AND p."publication_number" != (
      SELECT
        publication_number
      FROM
        base_patent
    )
    AND TRY_TO_DATE(p."filing_date"::VARCHAR, 'YYYYMMDD') IS NOT NULL
    AND ae2."embedding_v1" IS NOT NULL
)
SELECT
  b.publication_number,
  s.pub_num2 AS most_similar_publication_number,
  ROUND(SUM(b_emb.VALUE::FLOAT * s_emb.VALUE::FLOAT), 4) AS similarity
FROM
  base_patent b
  CROSS JOIN same_year_patents s
  CROSS JOIN TABLE(FLATTEN(input => b.embedding1)) AS b_emb
  CROSS JOIN TABLE(FLATTEN(input => s.embedding2)) AS s_emb
WHERE
  b_emb.SEQ = s_emb.SEQ
GROUP BY
  b.publication_number,
  s.pub_num2
ORDER BY
  similarity DESC NULLS LAST
LIMIT
  1;