/* ----------------------------------------------------------------------
   Top-10 Nature papers closest (cosine) to the query
   “Epigenetics and cerebral organoids: promising directions in
   autism spectrum disorders”, but **first** restrict to articles whose
   body already contains at least one of the main query terms to keep
   the workload small enough for the warehouse-timeout limit.
   --------------------------------------------------------------------*/
WITH
/* 0. Candidate articles – bodies that mention a query keyword
      (greatly reduces the amount of text to vectorise)                */
candidates AS (
    SELECT  "id", "date", "title", "body"
    FROM    WORD_VECTORS_US.WORD_VECTORS_US.NATURE
    WHERE   "body" ILIKE ANY ('%epigenet%','%organoid%','%autism%','%cerebral%')
),

/* -------------------------------------------------------------------
   1. Build the weighted query vector
   ------------------------------------------------------------------*/
query_tokens(token) AS (
    SELECT column1
    FROM VALUES
        ('epigenetics'), ('cerebral'), ('organoids'), ('promising'),
        ('directions'), ('autism'), ('spectrum'), ('disorders')
),
query_vec AS (
    SELECT
        fv.index::INT                              AS idx,
        SUM( fv.value::FLOAT
             * POWER(wf."frequency", -0.4) )       AS val
    FROM query_tokens qt
    JOIN WORD_VECTORS_US.WORD_VECTORS_US.WORD_FREQUENCIES wf
         ON wf."word" = qt.token
    JOIN WORD_VECTORS_US.WORD_VECTORS_US.GLOVE_VECTORS gv
         ON gv."word" = qt.token,
         LATERAL FLATTEN(input => gv."vector")      fv
    GROUP BY fv.index
),
query_norm AS (
    SELECT SQRT(SUM(val*val)) AS norm FROM query_vec
),

/* -------------------------------------------------------------------
   2. Weighted vector entries (per dimension) for every candidate
   ------------------------------------------------------------------*/
article_vec_entries AS (
    SELECT
        c."id",
        fv.index::INT                                            AS idx,
        SUM( fv.value::FLOAT *
             POWER(wf."frequency", -0.4) )                       AS val
    FROM   candidates                                   c,
           LATERAL SPLIT_TO_TABLE(
                   LOWER(REGEXP_REPLACE(c."body",'[^A-Za-z0-9 ]',' ')),
                   ' ')                                         tok
    JOIN   WORD_VECTORS_US.WORD_VECTORS_US.WORD_FREQUENCIES wf
           ON wf."word" = tok.value
    JOIN   WORD_VECTORS_US.WORD_VECTORS_US.GLOVE_VECTORS    gv
           ON gv."word" = tok.value,
           LATERAL FLATTEN(input => gv."vector")            fv
    WHERE  wf."frequency" < 5000          -- drop very common words
    GROUP BY c."id", fv.index
),
article_norms AS (
    SELECT "id",
           SQRT(SUM(val*val)) AS norm
    FROM   article_vec_entries
    GROUP BY "id"
),
article_dot AS (          /* dot-product with the query vector */
    SELECT  a."id",
            SUM(a.val * q.val) AS dot
    FROM    article_vec_entries a
    JOIN    query_vec          q ON q.idx = a.idx
    GROUP BY a."id"
),

/* -------------------------------------------------------------------
   3.  Final cosine similarity and ranking
   ------------------------------------------------------------------*/
similarities AS (
    SELECT
        n."id",
        n."date",
        n."title",
        ad.dot / NULLIF(an.norm * qn.norm,0) AS similarity
    FROM        article_dot   ad
    JOIN        article_norms an ON an."id" = ad."id"
    CROSS JOIN  query_norm    qn
    JOIN        candidates    n  ON n."id" = ad."id"
)
SELECT
    "id",
    "date",
    "title",
    similarity
FROM similarities
ORDER BY similarity DESC NULLS LAST
LIMIT 10;