WITH
search_tokens AS (
  SELECT
    LOWER(t.value) AS token,
    1 / POWER(COALESCE(wf."frequency", 1), 0.4) AS weight
  FROM
    (SELECT 1) s
  CROSS JOIN LATERAL SPLIT_TO_TABLE(REGEXP_REPLACE('Epigenetics and cerebral organoids: promising directions in autism spectrum disorders', '[^\w\s]', ' '), ' ') t
  LEFT JOIN "WORD_VECTORS_US"."WORD_VECTORS_US"."WORD_FREQUENCIES" wf ON wf."word" = t.value
  WHERE t.value <> ''
),
article_tokens AS (
  SELECT
    n."id",
    n."date",
    n."title",
    LOWER(t.value) AS token,
    1 / POWER(COALESCE(wf."frequency", 1), 0.4) AS weight
  FROM "WORD_VECTORS_US"."WORD_VECTORS_US"."NATURE" n
  CROSS JOIN LATERAL SPLIT_TO_TABLE(REGEXP_REPLACE(n."title" || ' ' || n."abstract" || ' ' || n."keywords", '[^\w\s]', ' '), ' ') t
  LEFT JOIN "WORD_VECTORS_US"."WORD_VECTORS_US"."WORD_FREQUENCIES" wf ON wf."word" = t.value
  WHERE t.value <> ''
),
search_vector AS (
  SELECT
    token,
    SUM(weight) AS weight
  FROM search_tokens
  GROUP BY token
),
article_vectors AS (
  SELECT
    "id",
    "date",
    "title",
    token,
    SUM(weight) AS weight
  FROM article_tokens
  GROUP BY "id", "date", "title", token
),
dot_products AS (
  SELECT
    av."id",
    av."date",
    av."title",
    SUM(av.weight * sv.weight) AS dot_product
  FROM article_vectors av
  JOIN search_vector sv ON av.token = sv.token
  GROUP BY av."id", av."date", av."title"
),
article_magnitudes AS (
  SELECT
    "id",
    SQRT(SUM(weight * weight)) AS magnitude
  FROM article_vectors
  GROUP BY "id"
),
search_magnitude AS (
  SELECT
    SQRT(SUM(weight * weight)) AS magnitude
  FROM search_vector
)
SELECT
  dp."id",
  dp."date",
  dp."title",
  ROUND(dp.dot_product / NULLIF(am.magnitude * sm.magnitude, 0), 4) AS cosine_similarity_score
FROM dot_products dp
JOIN article_magnitudes am ON dp."id" = am."id"
CROSS JOIN search_magnitude sm
WHERE (am.magnitude * sm.magnitude) <> 0
ORDER BY cosine_similarity_score DESC NULLS LAST
LIMIT 10;