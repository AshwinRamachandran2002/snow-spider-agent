/* -----------------------------------------------------------
   Efficiently create a length-normalised GloVe article vector
   for every Nature paper.

   Optimisations versus the previous attempt
   •  Count repeated tokens first, so each distinct (article,token)
     is looked-up/flattened only once.
   •  Apply that count in the weighting term to keep results exact
     while greatly reducing the explode size.
-----------------------------------------------------------*/
WITH
/* 1) Small English stop-word list */
stop_words(word) AS (
  SELECT column1 FROM VALUES
    ('the'),('of'),('and'),('in'),('to'),('a'),('is'),('it'),('for'),('on'),
    ('that'),('with'),('as'),('was'),('were'),('be'),('by'),('are'),('an'),
    ('at'),('from'),('this'),('or'),('which'),('have'),('has'),('had'),
    ('but'),('not'),('we'),('they'),('their'),('its'),('he'),('she'),
    ('his'),('her'),('them'),('also'),('may'),('can'),('will'),('would'),
    ('should'),('could'),('about')
),

/* 2) Tokenise each article body (lower-case, letters only) */
article_tokens AS (
  SELECT
      art."id"                                            AS article_id,
      REGEXP_REPLACE(LOWER(tok.value::STRING), '[^a-z]+','') AS token
  FROM WORD_VECTORS_US.WORD_VECTORS_US.NATURE            AS art
  CROSS JOIN LATERAL FLATTEN(INPUT => SPLIT(art."body", ' ')) tok
),

/* 3) Remove empty tokens & stop-words */
filtered_tokens AS (
  SELECT article_id, token
  FROM   article_tokens t
  WHERE  token <> ''
    AND NOT EXISTS (SELECT 1 FROM stop_words s WHERE s.word = t.token)
),

/* 4) Count how many times each token occurs per article        */
token_counts AS (
  SELECT
      article_id,
      token,
      COUNT(*) AS tok_count
  FROM filtered_tokens
  GROUP BY article_id, token
),

/* 5) Join once per distinct token to frequency & GloVe vector
      and apply the weighting (tok_count / frequency^0.4).      */
token_vectors AS (
  SELECT
      tc.article_id,
      gv.index                                                         AS dim,
      (gv.value::FLOAT * tc.tok_count) / POWER(w."frequency", 0.4)     AS weighted_val
  FROM token_counts                                           AS tc
  JOIN WORD_VECTORS_US.WORD_VECTORS_US.WORD_FREQUENCIES w
       ON tc.token = w."word"
  JOIN WORD_VECTORS_US.WORD_VECTORS_US.GLOVE_VECTORS      g
       ON tc.token = g."word",
       LATERAL FLATTEN(INPUT => g."vector")               AS gv
),

/* 6) Sum weighted values per article & dimension               */
article_dim_sum AS (
  SELECT
      article_id,
      dim,
      SUM(weighted_val) AS dim_val
  FROM token_vectors
  GROUP BY article_id, dim
),

/* 7) Compute Euclidean norm of each raw article vector         */
article_norms AS (
  SELECT
      article_id,
      SQRT(SUM(dim_val * dim_val)) AS norm
  FROM article_dim_sum
  GROUP BY article_id
),

/* 8) Normalise each dimension                                  */
article_dim_norm AS (
  SELECT
      ads.article_id,
      ads.dim,
      CASE WHEN an.norm = 0 THEN 0
           ELSE ads.dim_val / an.norm
      END AS norm_val
  FROM article_dim_sum ads
  JOIN article_norms  an
    ON ads.article_id = an.article_id
)

/* 9) Re-assemble ordered unit-length vector for every article  */
SELECT
    nat."id",
    nat."date",
    nat."title",
    ARRAY_AGG(adn.norm_val) WITHIN GROUP (ORDER BY adn.dim) AS article_vector
FROM WORD_VECTORS_US.WORD_VECTORS_US.NATURE nat
LEFT JOIN article_dim_norm adn
       ON nat."id" = adn.article_id
GROUP BY nat."id", nat."date", nat."title"
;