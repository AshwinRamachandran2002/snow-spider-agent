WITH target_embedding AS (
  SELECT t."publication_number", f.value::FLOAT AS "embedding_value", f."INDEX" AS idx
  FROM PATENTS_GOOGLE.PATENTS_GOOGLE.ABS_AND_EMB t,
       LATERAL FLATTEN(input => t."embedding_v1") f
  WHERE t."publication_number" = 'US-9741766-B2'
),
same_year_patents AS (
  SELECT p."publication_number", a."embedding_v1"
  FROM PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS p
  JOIN PATENTS_GOOGLE.PATENTS_GOOGLE.ABS_AND_EMB a
    ON p."publication_number" = a."publication_number"
  WHERE SUBSTR(CAST(p."filing_date" AS STRING), 1, 4) = (
    SELECT SUBSTR(CAST("filing_date" AS STRING), 1, 4)
    FROM PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS
    WHERE "publication_number" = 'US-9741766-B2'
  )
    AND a."embedding_v1" IS NOT NULL
    AND p."publication_number" <> 'US-9741766-B2'
),
flattened_embeddings AS (
  SELECT syp."publication_number", f.value::FLOAT AS "embedding_value", f."INDEX" AS idx
  FROM same_year_patents syp,
       LATERAL FLATTEN(input => syp."embedding_v1") f
),
dot_products AS (
  SELECT fe."publication_number",
         ROUND(SUM(fe."embedding_value" * te."embedding_value"), 4) AS similarity
  FROM flattened_embeddings fe
  JOIN target_embedding te ON fe.idx = te.idx
  GROUP BY fe."publication_number"
)
SELECT "publication_number"
FROM dot_products
ORDER BY similarity DESC NULLS LAST
LIMIT 5;