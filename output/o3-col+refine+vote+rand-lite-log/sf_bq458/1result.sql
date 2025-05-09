WITH
/* 1. Tokenise BODY text ---------------------------------------------------- */
tokens AS (
    SELECT
        n."id"    AS article_id,
        n."date"  AS article_date,
        n."title" AS article_title,
        LOWER(TRIM(tok.value::STRING)) AS token
    FROM WORD_VECTORS_US.WORD_VECTORS_US.NATURE n,
         LATERAL SPLIT_TO_TABLE(
             REGEXP_REPLACE(LOWER(n."body"), '[^a-z0-9 ]', ' '),
             ' '
         ) tok
),
/* 2. Remove stop-words, blanks and pure numbers ---------------------------- */
filtered_tokens AS (
    SELECT article_id, token
    FROM tokens
    WHERE token <> ''
      AND token NOT REGEXP '^[0-9]+$'
      AND token NOT IN (
          'the','of','and','in','to','a','with','for','is','on','that','by','an','as','are',
          'at','from','this','be','or','it','was','were','which','we','also','can','these',
          'have','has','had','not','our','their','its','than','may','but','such','they',
          'been','into','use','using','used','between','both','other','more','most',
          'however','about','over','during','one','two','three'
      )
),
/* 3. Attach frequency & GloVe vector --------------------------------------- */
word_info AS (
    SELECT
        ft.article_id,
        gv."vector"            AS vec,
        wf."frequency"         AS freq
    FROM filtered_tokens ft
    JOIN WORD_VECTORS_US.WORD_VECTORS_US.GLOVE_VECTORS    gv
         ON gv."word" = ft.token
    JOIN WORD_VECTORS_US.WORD_VECTORS_US.WORD_FREQUENCIES wf
         ON wf."word" = ft.token
),
/* 4. Weight vectors and flatten to (article_id, dim, contrib) -------------- */
weighted_dims AS (
    SELECT
        wi.article_id,
        v.index::INT                          AS dim,
        (v.value::FLOAT) / POWER(wi.freq, 0.4) AS contrib
    FROM word_info wi,
         LATERAL FLATTEN(input => wi.vec) v
),
/* 5. Sum contributions per article & dimension ----------------------------- */
article_raw_vec AS (
    SELECT
        article_id,
        dim,
        SUM(contrib) AS value
    FROM weighted_dims
    GROUP BY article_id, dim
),
/* 6. Compute L2 norm for each article -------------------------------------- */
norms AS (
    SELECT
        article_id,
        SQRT(SUM(value * value)) AS norm
    FROM article_raw_vec
    GROUP BY article_id
),
/* 7. Normalise each component --------------------------------------------- */
article_norm_dims AS (
    SELECT
        rv.article_id,
        rv.dim,
        CASE WHEN n.norm = 0 THEN 0 ELSE rv.value / n.norm END AS norm_value
    FROM article_raw_vec rv
    JOIN norms n ON n.article_id = rv.article_id
),
/* 8. Assemble ordered array of components ---------------------------------- */
article_vectors AS (
    SELECT
        article_id,
        ARRAY_AGG(norm_value) WITHIN GROUP (ORDER BY dim) AS article_vector
    FROM article_norm_dims
    GROUP BY article_id
)
/* 9. Final result ---------------------------------------------------------- */
SELECT
    n."id",
    n."date",
    n."title",
    av.article_vector
FROM WORD_VECTORS_US.WORD_VECTORS_US.NATURE n
JOIN article_vectors av
      ON av.article_id = n."id";