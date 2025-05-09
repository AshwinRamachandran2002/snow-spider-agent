/* ------------------------------------------------------------------
   Build a unit-normalised vector for every Nature article.
   – Count each token once per article (term-frequency) before
     exploding the 300-dimensional GloVe vector — greatly reducing
     the amount of work versus the original per-token approach.
-------------------------------------------------------------------*/
WITH tokens AS (  ---------------------------------------------------
    SELECT
        n."id",
        n."date",
        n."title",
        TRIM(f.value)::STRING AS "word"
    FROM WORD_VECTORS_US.WORD_VECTORS_US."NATURE" n,
         LATERAL FLATTEN(
             INPUT => SPLIT(
                 REGEXP_REPLACE( LOWER(n."body"), '[^a-z0-9 ]', ' ' ),
                 ' '
             )
         ) f
    WHERE TRIM(f.value) <> ''
      AND TRIM(f.value) NOT IN (     -- minimalist stop list
           'the','and','of','to','a','in','is','on','for','with',
           'as','by','an','at','be','this','that','it','from'
      )
),                    ------------------------------------------------
token_counts AS (      -- 1. term-frequency for every (article, word)
    SELECT
        "id",
        "date",
        "title",
        "word",
        COUNT(*) AS tf
    FROM tokens
    GROUP BY "id","date","title","word"
),                    ------------------------------------------------
weighted_components AS (  -- 2. weight each vector component once
    SELECT
        tc."id",
        tc."date",
        tc."title",
        v.index                                                       AS idx,
        v.value::FLOAT * ( tc.tf / POWER( wf."frequency", 0.4 ) )     AS comp
    FROM token_counts tc
    JOIN WORD_VECTORS_US.WORD_VECTORS_US."WORD_FREQUENCIES" wf
         ON tc."word" = wf."word"
    JOIN WORD_VECTORS_US.WORD_VECTORS_US."GLOVE_VECTORS" gv
         ON tc."word" = gv."word",
    LATERAL FLATTEN( INPUT => gv."vector" ) v
),                    ------------------------------------------------
article_vec AS (        -- 3. sum components per article
    SELECT
        "id",
        "date",
        "title",
        idx,
        SUM(comp) AS comp_sum
    FROM weighted_components
    GROUP BY "id","date","title",idx
),                    ------------------------------------------------
magnitudes AS (         -- 4. vector magnitudes
    SELECT
        "id",
        SQRT( SUM( comp_sum * comp_sum ) ) AS mag
    FROM article_vec
    GROUP BY "id"
)                     ------------------------------------------------
-- 5. normalise & return final vectors
SELECT
    a."id",
    a."date",
    a."title",
    ARRAY_AGG( a.comp_sum / m.mag ) WITHIN GROUP (ORDER BY a.idx)
        AS "normalised_article_vector"
FROM article_vec  a
JOIN magnitudes   m  ON a."id" = m."id"
GROUP BY a."id", a."date", a."title";