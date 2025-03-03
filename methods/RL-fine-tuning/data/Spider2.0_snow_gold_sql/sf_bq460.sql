WITH stopwords AS (
  SELECT 'a' AS "word"
  UNION ALL SELECT 'an'
  UNION ALL SELECT 'the'
  UNION ALL SELECT 'and'
  UNION ALL SELECT 'or'
  UNION ALL SELECT 'in'
  UNION ALL SELECT 'on'
  UNION ALL SELECT 'at'
  UNION ALL SELECT 'of'
  UNION ALL SELECT 'to'
  UNION ALL SELECT 'is'
  UNION ALL SELECT 'are'
  UNION ALL SELECT 'was'
  UNION ALL SELECT 'were'
  UNION ALL SELECT 'be'
  UNION ALL SELECT 'been'
  UNION ALL SELECT 'have'
  UNION ALL SELECT 'has'
  UNION ALL SELECT 'had'
  UNION ALL SELECT 'that'
  UNION ALL SELECT 'this'
  UNION ALL SELECT 'for'
  UNION ALL SELECT 'with'
  UNION ALL SELECT 'as'
  UNION ALL SELECT 'by'
  UNION ALL SELECT 'from'
  UNION ALL SELECT 'we'
  UNION ALL SELECT 'not'
  UNION ALL SELECT 'which'
  UNION ALL SELECT 'can'
  UNION ALL SELECT 'all'
  UNION ALL SELECT 'also'
  UNION ALL SELECT 'these'
  UNION ALL SELECT 'but'
  UNION ALL SELECT 'their'
  UNION ALL SELECT 'other'
  UNION ALL SELECT 'new'
  UNION ALL SELECT 'more'
  UNION ALL SELECT 'such'
  UNION ALL SELECT 'our'
  UNION ALL SELECT 'some'
  UNION ALL SELECT 'one'
  UNION ALL SELECT 'may'
  UNION ALL SELECT 'than'
  UNION ALL SELECT 'they'
  UNION ALL SELECT 'it'
  UNION ALL SELECT 'up'
  UNION ALL SELECT 'will'
  UNION ALL SELECT 'them'
  UNION ALL SELECT 'there'
  UNION ALL SELECT 'if'
  UNION ALL SELECT 'no'
  UNION ALL SELECT 'so'
  UNION ALL SELECT 'what'
  UNION ALL SELECT 'about'
  UNION ALL SELECT 'when'
),
article_words AS (
  SELECT
    "id",
    "date",
    "title",
    LOWER(TRIM(token.VALUE)) AS "word"
  FROM "WORD_VECTORS_US"."WORD_VECTORS_US"."NATURE",
  LATERAL FLATTEN(input => SPLIT(REGEXP_REPLACE("body", '[^a-zA-Z0-9 ]', ' '), ' ')) AS token
),
filtered_words AS (
  SELECT
    aw."id",
    aw."date",
    aw."title",
    aw."word"
  FROM article_words aw
  LEFT JOIN stopwords sw ON aw."word" = sw."word"
  WHERE sw."word" IS NULL AND aw."word" <> ''
),
word_vectors AS (
  SELECT
    fw."id",
    fw."date",
    fw."title",
    fw."word",
    wf."frequency",
    gv."vector"
  FROM filtered_words fw
  JOIN "WORD_VECTORS_US"."WORD_VECTORS_US"."WORD_FREQUENCIES" wf
    ON fw."word" = wf."word"
  JOIN "WORD_VECTORS_US"."WORD_VECTORS_US"."GLOVE_VECTORS" gv
    ON fw."word" = gv."word"
),
flattened_vectors AS (
  SELECT
    "id",
    "date",
    "title",
    f.INDEX AS "index",
    (f.VALUE / POWER("frequency", 0.4)) AS "weighted_element"
  FROM word_vectors,
  LATERAL FLATTEN(input => "vector") AS f
),
article_aggregated_vectors AS (
  SELECT
    "id",
    "date",
    "title",
    "index",
    SUM("weighted_element") AS "aggregate_element"
  FROM flattened_vectors
  GROUP BY "id", "date", "title", "index"
),
article_vectors AS (
  SELECT
    "id",
    "date",
    "title",
    ARRAY_AGG("aggregate_element") WITHIN GROUP (ORDER BY "index") AS "aggregate_vector"
  FROM article_aggregated_vectors
  GROUP BY "id", "date", "title"
),
article_vectors_with_norms AS (
  SELECT
    av."id",
    av."date",
    av."title",
    av."aggregate_vector",
    SQRT(SUM(POWER(f.VALUE, 2))) AS "norm"
  FROM article_vectors av,
  LATERAL FLATTEN(input => av."aggregate_vector") AS f
  GROUP BY av."id", av."date", av."title", av."aggregate_vector"
),
normalized_article_vectors AS (
  SELECT
    av."id",
    av."date",
    av."title",
    ARRAY_AGG(f.VALUE / av."norm") WITHIN GROUP (ORDER BY f.INDEX) AS "normalized_vector"
  FROM article_vectors_with_norms av,
  LATERAL FLATTEN(input => av."aggregate_vector") AS f
  GROUP BY av."id", av."date", av."title", av."norm"
),
target_article_vector AS (
  SELECT
    *
  FROM normalized_article_vectors
  WHERE "id" = '8a78ef2d-d5f7-4d2d-9b47-5adb25cbd373'
),
target_vector_elements AS (
  SELECT
    f.INDEX AS "index",
    f.VALUE AS "value"
  FROM target_article_vector,
  LATERAL FLATTEN(input => "normalized_vector") AS f
),
all_vectors_elements AS (
  SELECT
    nav."id",
    nav."date",
    nav."title",
    f.INDEX AS "index",
    f.VALUE AS "value"
  FROM normalized_article_vectors nav,
  LATERAL FLATTEN(input => nav."normalized_vector") AS f
),
cosine_similarities AS (
  SELECT
    ave."id",
    ave."date",
    ave."title",
    SUM(ave."value" * tve."value") AS "cosine_similarity"
  FROM all_vectors_elements ave
  JOIN target_vector_elements tve ON ave."index" = tve."index"
  GROUP BY ave."id", ave."date", ave."title"
)
SELECT
  cs."id" AS "ID",
  cs."date" AS "Date",
  cs."title" AS "Title",
  ROUND(cs."cosine_similarity", 4) AS "Cosine_Similarity"
FROM cosine_similarities cs
WHERE cs."id" <> '8a78ef2d-d5f7-4d2d-9b47-5adb25cbd373'
ORDER BY cs."cosine_similarity" DESC NULLS LAST
LIMIT 10;