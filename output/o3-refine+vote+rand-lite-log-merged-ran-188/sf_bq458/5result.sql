WITH token_vectors AS (   -- 1. tokens having both frequency & glove entries, minus stop-words
    SELECT
        n."id"                               AS id,        -- ensure unquoted alias
        gv."vector"                          AS vec,
        POWER(wf."frequency", -0.4)::FLOAT   AS weight
    FROM WORD_VECTORS_US.WORD_VECTORS_US."NATURE" n,
         LATERAL FLATTEN(
             INPUT => SPLIT(
                         REGEXP_REPLACE(LOWER(n."body"), '[^a-z]+', ' '),
                         ' '
                     )
         ) tok
    JOIN WORD_VECTORS_US.WORD_VECTORS_US."WORD_FREQUENCIES" wf
      ON tok.value::STRING = wf."word"
    JOIN WORD_VECTORS_US.WORD_VECTORS_US."GLOVE_VECTORS" gv
      ON tok.value::STRING = gv."word"
    WHERE tok.value::STRING <> ''
      AND tok.value::STRING NOT IN (        -- simple stop-word list
          'a','an','the','and','or','but','if','in','on','at','of','for','to','with',
          'is','are','was','were','be','been','has','have','had','that','this','these',
          'those','it','its','as','by','from','not','which','we','they','their','them',
          'he','she','his','her','you','your','i','me','my','our','ours','us','do',
          'does','did','will','shall','can','could','should','would','may','might',
          'about','into','over','after','before','between','among','so','such','no',
          'nor','than','too','very'
      )
),
weighted_components AS (                    -- 2. weight each vector component
    SELECT
        id,
        vec_el.index                       AS dim,
        vec_el.value::FLOAT * weight       AS comp
    FROM token_vectors,
         LATERAL FLATTEN(INPUT => vec) vec_el
),
sum_components AS (                         -- 3. sum components per article
    SELECT
        id,
        dim,
        SUM(comp) AS sum_comp
    FROM weighted_components
    GROUP BY id, dim
),
aggregated AS (                             -- 4. collect sums & compute magnitude
    SELECT
        id,
        ARRAY_AGG(sum_comp) WITHIN GROUP (ORDER BY dim)  AS raw_vector,
        SQRT(SUM(POWER(sum_comp, 2)))                    AS magnitude
    FROM sum_components
    GROUP BY id
),
normalized AS (                             -- 5. normalise to unit length
    SELECT
        sc.id,
        ARRAY_AGG(sc.sum_comp / agg.magnitude)
            WITHIN GROUP (ORDER BY sc.dim)              AS norm_vector
    FROM sum_components sc
    JOIN aggregated agg ON sc.id = agg.id
    WHERE agg.magnitude <> 0
    GROUP BY sc.id
)
SELECT
    n."id",
    n."date",
    n."title",
    norm.norm_vector AS "article_vector"
FROM WORD_VECTORS_US.WORD_VECTORS_US."NATURE" n
JOIN normalized norm ON n."id" = norm.id;