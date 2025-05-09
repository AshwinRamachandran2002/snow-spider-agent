/* -----------------------------------------------------------------
   Vector-based similarity search between the query and Nature papers
   – performance-oriented version that
       • limits the comparison set to ≤ 300 likely-relevant papers
       • collapses duplicate tokens inside every article
-------------------------------------------------------------------*/
WITH
/* -------- 0) Pick ≤ 300 candidate articles containing any query term -------- */
candidate_articles AS (
    SELECT  *
    FROM   (
        SELECT n."id", n."date", n."title", n."body",
               ROW_NUMBER() OVER (ORDER BY n."date" DESC) AS rn
        FROM   WORD_VECTORS_US.WORD_VECTORS_US.NATURE n
        WHERE  n."body" ILIKE '%epigenetic%'      -- epigenetics
           OR  n."body" ILIKE '%cerebral%'
           OR  n."body" ILIKE '%organoid%'
           OR  n."body" ILIKE '%autism%'
           OR  n."body" ILIKE '%spectrum%'
           OR  n."body" ILIKE '%disorder%'        -- disorder / disorders
    )
    WHERE rn <= 300
),

/* ---------------- 1) tiny stop-word list ---------------- */
stopwords(word) AS (
  SELECT column1 FROM VALUES
    ('a'),('an'),('and'),('are'),('as'),('at'),('be'),('but'),('by'),
    ('for'),('if'),('in'),('into'),('is'),('it'),('no'),('not'),
    ('of'),('on'),('or'),('such'),('that'),('the'),('their'),('then'),
    ('there'),('these'),('they'),('this'),('to'),('was'),('will'),
    ('with'),('we'),('our'),('you'),('your'),('were'),('has'),('have'),
    ('had'),('which')
),

/* ---------------- 2)   QUERY  →  unit vector ---------------- */
query_tokens AS (
  SELECT LOWER(REGEXP_REPLACE(value,'[^a-z]+','')) AS token
  FROM TABLE( SPLIT_TO_TABLE(
        'Epigenetics and cerebral organoids: promising directions in autism spectrum disorders',
        ' '))
  WHERE token <> ''
),
query_filtered AS (
  SELECT qt.token
  FROM   query_tokens qt
  LEFT   JOIN stopwords s ON qt.token = s.word
  WHERE  s.word IS NULL
),
query_vectors AS (
  SELECT gv."vector"                    AS vec,
         1 / POWER(wf."frequency",0.4)  AS wt
  FROM   query_filtered q
  JOIN   WORD_VECTORS_US.WORD_VECTORS_US.GLOVE_VECTORS    gv ON gv."word" = q.token
  JOIN   WORD_VECTORS_US.WORD_VECTORS_US.WORD_FREQUENCIES wf ON wf."word" = q.token
),
query_weighted AS (
  SELECT f.index                       AS dim,
         (f.value::FLOAT * qv.wt)      AS val
  FROM   query_vectors qv,
         LATERAL FLATTEN(INPUT => qv.vec) f
),
query_sum AS (
  SELECT dim, SUM(val) AS comp
  FROM   query_weighted
  GROUP  BY dim
),
query_norm AS (
  SELECT SQRT(SUM(comp*comp)) AS nrm
  FROM   query_sum
),
query_unit AS (
  SELECT dim, comp / qn.nrm AS uval
  FROM   query_sum, query_norm qn
),

/* ---------------- 3)   ARTICLES  →  unit vectors ---------------- */
/* 3-a)   tokenise & drop stop-words                                      */
article_tokens AS (
  SELECT
      ca."id", ca."date", ca."title",
      LOWER(REGEXP_REPLACE(tok.value,'[^a-z]+','')) AS token
  FROM   candidate_articles ca,
         LATERAL SPLIT_TO_TABLE(ca."body",' ') tok
  WHERE  tok.value <> ''
),
article_filtered AS (
  SELECT at.*
  FROM   article_tokens at
  LEFT   JOIN stopwords s ON at.token = s.word
  WHERE  s.word IS NULL
),

/* 3-b)   collapse duplicates -> per-article token counts                 */
article_token_counts AS (
  SELECT
      at."id",
      MIN(at."date")  AS "date",
      MIN(at."title") AS "title",
      at.token,
      COUNT(*)        AS tok_cnt
  FROM   article_filtered at
  GROUP  BY at."id", at.token
),

/* 3-c)   attach vectors & corpus weight, multiply by within-article freq */
article_vectors AS (
  SELECT
      atc."id",
      atc."date",
      atc."title",
      gv."vector"                       AS vec,
      atc.tok_cnt * (1 / POWER(wf."frequency",0.4))  AS wt
  FROM   article_token_counts atc
  JOIN   WORD_VECTORS_US.WORD_VECTORS_US.GLOVE_VECTORS    gv ON gv."word" = atc.token
  JOIN   WORD_VECTORS_US.WORD_VECTORS_US.WORD_FREQUENCIES wf ON wf."word" = atc.token
),

/* 3-d)   explode vector, weight, and sum                                 */
article_weighted AS (
  SELECT
      av."id", av."date", av."title",
      f.index                            AS dim,
      (f.value::FLOAT * av.wt)           AS val
  FROM   article_vectors av,
         LATERAL FLATTEN(INPUT => av.vec) f
),
article_sum AS (
  SELECT
      "id","date","title",
      dim,
      SUM(val)                          AS comp
  FROM   article_weighted
  GROUP  BY "id","date","title",dim
),
article_norm AS (
  SELECT "id", SQRT(SUM(comp*comp)) AS nrm
  FROM   article_sum
  GROUP  BY "id"
),
article_unit AS (
  SELECT
      a."id", a."date", a."title",
      a.dim,
      a.comp / an.nrm                AS uval
  FROM   article_sum a
  JOIN   article_norm an ON an."id" = a."id"
),

/* ---------------- 4)   cosine similarity ---------------- */
cosine AS (
  SELECT
      au."id",
      au."date",
      au."title",
      SUM( au.uval * qu.uval )        AS similarity
  FROM   article_unit au
  JOIN   query_unit  qu USING (dim)
  GROUP  BY au."id", au."date", au."title"
)

/* ---------------- 5)   top-10 results ---------------- */
SELECT
    "id",
    "date",
    "title",
    similarity
FROM   cosine
ORDER  BY similarity DESC NULLS LAST
LIMIT 10;