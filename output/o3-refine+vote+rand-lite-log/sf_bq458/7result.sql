/* -----------------------------------------------------------
   Build a normalised GloVe‑based vector for every Nature article
   -----------------------------------------------------------
   Performance‑oriented version:
     · count each word only once per article (token_counts)
     · flatten every GloVe vector only once per (article , word)
---------------------------------------------------------------- */
WITH                                                          -- 1) simple stop‑word list
stop_words(word) AS (
    SELECT column1 FROM VALUES
        ('a'),('an'),('and'),('are'),('as'),('at'),('be'),('but'),
        ('by'),('for'),('from'),('has'),('have'),('he'),('in'),
        ('is'),('it'),('its'),('of'),('on'),('that'),('the'),('their'),
        ('they'),('this'),('to'),('was'),('were'),('will'),('with')
),                                                            -- 2) explode body, then count distinct words per article
token_counts AS (
    SELECT
        n."id",
        n."date",
        n."title",
        LOWER(f.value::string)                     AS word,
        COUNT(*)                                   AS tok_cnt        -- term‑frequency in article
    FROM WORD_VECTORS_US.WORD_VECTORS_US."NATURE" n,
         LATERAL FLATTEN(
             INPUT => SPLIT(
                 REGEXP_REPLACE(LOWER(n."body"), '[^a-z]+', ' '),    -- keep only letters, use space as delimiter
                 ' '
             )
         ) f
    WHERE f.value IS NOT NULL
      AND f.value <> ''
      AND LOWER(f.value::string) NOT IN (SELECT word FROM stop_words)
    GROUP BY n."id", n."date", n."title", LOWER(f.value::string)
),                                                            -- 3) attach corpus frequency & glove vector, then explode vector
word_vectors AS (
    SELECT
        tc."id",
        tc."date",
        tc."title",
        gv_idx.index                                          AS dim,
        ( tc.tok_cnt * gv_idx.value::float ) /
        POWER(wf."frequency", 0.4)                            AS weighted_val
    FROM token_counts tc
    JOIN WORD_VECTORS_US.WORD_VECTORS_US."WORD_FREQUENCIES" wf
         ON wf."word" = tc.word
    JOIN WORD_VECTORS_US.WORD_VECTORS_US."GLOVE_VECTORS"     gv
         ON gv."word" = tc.word
         , LATERAL FLATTEN(INPUT => gv."vector") gv_idx                      -- component‑wise values
),                                                            -- 4) sum weighted vectors per article‑dimension
article_sum AS (
    SELECT
        "id", "date", "title",
        dim,
        SUM(weighted_val)                                    AS dim_val
    FROM word_vectors
    GROUP BY "id", "date", "title", dim
),                                                            -- 5) compute vector magnitude
article_mag AS (
    SELECT
        "id", "date", "title",
        SQRT(SUM(dim_val * dim_val))                         AS mag
    FROM article_sum
    GROUP BY "id", "date", "title"
),                                                            -- 6) normalise & gather into ordered array
article_vector AS (
    SELECT
        a."id",
        a."date",
        a."title",
        ARRAY_AGG( a.dim_val / m.mag ) 
        WITHIN GROUP ( ORDER BY a.dim )                      AS norm_vector
    FROM article_sum a
    JOIN article_mag m
      ON a."id"    = m."id"
     AND a."date"  = m."date"
     AND a."title" = m."title"
    GROUP BY a."id", a."date", a."title", m.mag
)
SELECT
    "id",
    "date",
    "title",
    norm_vector AS normalised_article_vector
FROM article_vector;