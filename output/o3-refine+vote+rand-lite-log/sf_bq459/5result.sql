/* ------------------------------------------------------------
   Top‑10 Nature articles most similar to the query
   “Epigenetics and cerebral organoids: promising directions
    in autism spectrum disorders”, using GloVe‑based cosine
    similarity with frequency‑based re‑weighting.
------------------------------------------------------------ */
WITH
/* ---------------- 1. stop‑word list ----------------------- */
stopwords(word) AS (
    SELECT column1 FROM VALUES
        ('a'),('an'),('the'),('and'),('or'),('but'),('if'),('while'),('with'),('to'),('for'),('from'),('of'),
        ('on'),('in'),('by'),('is'),('are'),('was'),('were'),('be'),('been'),('being'),('have'),('has'),('had'),
        ('do'),('does'),('did'),('this'),('that'),('these'),('those'),('it'),('its'),('as'),('at'),('which'),
        ('so'),('such'),('into'),('their'),('there'),('we'),('our'),('you'),('your'),('he'),('she'),('they'),
        ('them'),('his'),('her'),('hers'),('more'),('most'),('can'),('could'),('should'),('would'),('may'),
        ('might'),('will'),('just'),('about'),('over'),('after'),('before'),('under'),('again'),('further'),
        ('then'),('once'),('here'),('when'),('where'),('why'),('how'),('all'),('any'),('both'),('each'),('few'),
        ('other'),('some'),('no'),('nor'),('not'),('only'),('own'),('same'),('than'),('too'),('very'),('s'),
        ('t'),('d'),('ll'),('m'),('o'),('re'),('ve'),('y'),('ain'),('aren'),('couldn'),('didn'),('doesn'),
        ('hadn'),('hasn'),('haven'),('isn'),('ma'),('mightn'),('mustn'),('needn'),('shan'),('shouldn'),
        ('wasn'),('weren'),('won'),('wouldn')
),

/* -------------- 2.  tokenise every article ---------------- */
article_tokens AS (
    SELECT  n."id",
            n."date",
            n."title",
            lower(tok.value::string) AS token
    FROM    WORD_VECTORS_US.WORD_VECTORS_US.NATURE n,
            LATERAL FLATTEN(
                     input => SPLIT( regexp_replace(n."body",'[^A-Za-z]+',' '),' ')
            ) tok
    WHERE   tok.value IS NOT NULL
      AND   tok.value <> ''
),

/* ---------- 3. keep tokens that have vectors & freq -------- */
valid_tokens AS (
    SELECT  at."id", at."date", at."title", at.token
    FROM    article_tokens at
    WHERE   at.token NOT IN (SELECT word FROM stopwords)
      AND   EXISTS (SELECT 1 FROM WORD_VECTORS_US.WORD_VECTORS_US.GLOVE_VECTORS gv WHERE gv."word" = at.token)
      AND   EXISTS (SELECT 1 FROM WORD_VECTORS_US.WORD_VECTORS_US.WORD_FREQUENCIES wf WHERE wf."word" = at.token)
),

/* --------- 4. count occurrences of each token/article ------ */
token_counts AS (
    SELECT  "id","date","title",token, COUNT(*) AS cnt
    FROM    valid_tokens
    GROUP BY "id","date","title",token
),

/* ------------ 5. join vector & frequency, weight ----------- */
token_vectors AS (
    SELECT  tc."id",
            tc."date",
            tc."title",
            gv."vector",
            tc.cnt / POWER(wf."frequency",0.4)  AS scale          -- cnt * weight
    FROM    token_counts tc
        JOIN WORD_VECTORS_US.WORD_VECTORS_US.GLOVE_VECTORS gv
              ON gv."word" = tc.token
        JOIN WORD_VECTORS_US.WORD_VECTORS_US.WORD_FREQUENCIES wf
              ON wf."word" = tc.token
),

/* --------- 6. sum weighted vectors per dimension ----------- */
article_dim_sum AS (
    SELECT  tv."id",
            tv."date",
            tv."title",
            f.index                               AS dim,
            SUM( f.value::float * tv.scale )      AS val_sum
    FROM    token_vectors tv,
            LATERAL FLATTEN( input => tv."vector") f                -- 300‑dim explosion
    GROUP BY tv."id",tv."date",tv."title",f.index
),

/* --------------- 7. normalise article vectors -------------- */
article_norm AS (
    SELECT  "id",
            SQRT( SUM( val_sum*val_sum ) ) AS norm
    FROM    article_dim_sum
    GROUP BY "id"
),
article_vec AS (
    SELECT  ads."id",
            ads."date",
            ads."title",
            ads.dim,
            ads.val_sum / an.norm           AS val                 -- unit vector value
    FROM    article_dim_sum ads
      JOIN  article_norm an ON an."id" = ads."id"
),

/* ======================= QUERY ============================ */
/* ------ 8. prepare query tokens, vectors, weighted sum ----- */
query_tokens AS (
    SELECT lower(tok.value::string) AS token
    FROM   LATERAL FLATTEN(
             input => SPLIT(
                       regexp_replace(
                         'Epigenetics and cerebral organoids: promising directions in autism spectrum disorders',
                         '[^A-Za-z]+',' '
                       ),
                       ' '
             )
           ) tok
    WHERE  tok.value IS NOT NULL
      AND  tok.value <> ''
      AND  lower(tok.value::string) NOT IN (SELECT word FROM stopwords)
),
query_vecs AS (
    SELECT  gv."vector",
            1 / POWER(wf."frequency",0.4)  AS wt
    FROM    query_tokens qt
      JOIN  WORD_VECTORS_US.WORD_VECTORS_US.GLOVE_VECTORS gv ON gv."word" = qt.token
      JOIN  WORD_VECTORS_US.WORD_VECTORS_US.WORD_FREQUENCIES wf ON wf."word" = qt.token
),
query_dim_sum AS (
    SELECT  f.index                     AS dim,
            SUM( f.value::float * qv.wt ) AS val_sum
    FROM    query_vecs qv,
            LATERAL FLATTEN( input => qv."vector") f
    GROUP BY f.index
),
query_norm AS (
    SELECT SQRT( SUM( val_sum*val_sum ) ) AS norm FROM query_dim_sum
),
query_vec AS (
    SELECT  qds.dim,
            qds.val_sum / qn.norm        AS val
    FROM    query_dim_sum qds
      CROSS JOIN query_norm qn
),

/* ------------ 9. cosine similarity (dot product) ----------- */
similarity AS (
    SELECT  av."id",
            av."date",
            av."title",
            SUM( av.val * qv.val ) AS cosine_similarity
    FROM    article_vec av
      JOIN  query_vec qv ON qv.dim = av.dim
    GROUP BY av."id", av."date", av."title"
)

/* --------------- 10.  return top‑10 ------------------------ */
SELECT  "id",
        "date",
        "title",
        cosine_similarity
FROM    similarity
ORDER BY cosine_similarity DESC NULLS LAST, "id"
LIMIT 10;