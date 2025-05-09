WITH
/*---------------------------------------------------------------
  1. Stop‑word list
----------------------------------------------------------------*/
stop_words AS (
    SELECT column1 AS word
    FROM VALUES
        ('a'),('an'),('the'),('and'),('or'),('but'),('if'),('to'),('of'),
        ('in'),('on'),('for'),('with'),('is'),('are'),('was'),('were'),
        ('be'),('been'),('being'),('at'),('by'),('that'),('this'),('it'),
        ('as'),('from'),('not'),('have'),('has'),('had'),('which'),('we'),
        ('they'),('i'),('you'),('he'),('she'),('them'),('us'),('our'),
        ('their'),('his'),('her'),('will'),('would'),('shall'),('should'),
        ('can'),('could'),('may'),('might'),('do'),('does'),('did'),
        ('done'),('so'),('such')
),
/*---------------------------------------------------------------
  2. Tokenise article bodies, clean, remove stop‑words
----------------------------------------------------------------*/
tokens AS (
    SELECT
        n."id",
        n."date",
        n."title",
        LOWER(REGEXP_REPLACE(t.value::STRING, '[^A-Za-z0-9]', '')) AS word
    FROM WORD_VECTORS_US.WORD_VECTORS_US.NATURE n,
         LATERAL SPLIT_TO_TABLE(n."body", ' ') t
),
filtered_tokens AS (
    SELECT *
    FROM tokens tk
    WHERE tk.word <> ''
      AND NOT EXISTS (
            SELECT 1 FROM stop_words sw WHERE sw.word = tk.word
      )
),
/*---------------------------------------------------------------
  3. Attach GloVe vectors and word frequencies
----------------------------------------------------------------*/
token_vectors AS (
    SELECT
        ft."id",
        ft."date",
        ft."title",
        gv."vector"                       AS vec,
        COALESCE(wf."frequency", 1)::FLOAT AS freq
    FROM filtered_tokens ft
    JOIN WORD_VECTORS_US.WORD_VECTORS_US.GLOVE_VECTORS gv
          ON gv."word" = ft.word
    LEFT JOIN WORD_VECTORS_US.WORD_VECTORS_US.WORD_FREQUENCIES wf
          ON wf."word" = ft.word
),
/*---------------------------------------------------------------
  4. Weight components by freq^(‑0.4) and sum per article
----------------------------------------------------------------*/
components AS (
    SELECT
        tv."id",
        tv."date",
        tv."title",
        f.index                                        AS idx,
        (f.value::FLOAT) / POW(tv.freq, 0.4)          AS comp
    FROM token_vectors tv,
         LATERAL FLATTEN(input => tv.vec) f
),
summed AS (
    SELECT
        "id", "date", "title",
        idx,
        SUM(comp) AS comp_sum
    FROM components
    GROUP BY "id", "date", "title", idx
),
article_vecs AS (
    SELECT
        "id", "date", "title",
        ARRAY_AGG(comp_sum) WITHIN GROUP (ORDER BY idx) AS article_vec
    FROM summed
    GROUP BY "id", "date", "title"
),
/*---------------------------------------------------------------
  5. Compute magnitude and normalise
----------------------------------------------------------------*/
norms AS (
    SELECT
        av.*,
        SQRT(SUM(POWER(f.value::FLOAT, 2))) AS mag
    FROM article_vecs av,
         LATERAL FLATTEN(input => av.article_vec) f
    GROUP BY av."id", av."date", av."title", av.article_vec
),
norm_components AS (
    SELECT
        n."id",
        n."date",
        n."title",
        f.index                                         AS idx,
        (f.value::FLOAT) / NULLIF(n.mag, 0)             AS comp_norm
    FROM norms n,
         LATERAL FLATTEN(input => n.article_vec) f
),
normalised AS (
    SELECT
        "id", "date", "title",
        ARRAY_AGG(comp_norm) WITHIN GROUP (ORDER BY idx) AS normalised_vec
    FROM norm_components
    GROUP BY "id", "date", "title"
)
/*---------------------------------------------------------------
  6. Final result
----------------------------------------------------------------*/
SELECT
    "id",
    "date",
    "title",
    normalised_vec AS "article_vector"
FROM normalised;