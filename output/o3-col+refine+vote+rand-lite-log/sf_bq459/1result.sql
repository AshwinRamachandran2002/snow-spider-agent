/* ----------------------------------------------------------------------
   Top-10 most relevant Nature articles for the query
   “Epigenetics and cerebral organoids: promising directions in autism
    spectrum disorders”.
   – First 1 000 tokens per article are analysed to stay inside the
     execution-time budget.
------------------------------------------------------------------------*/
WITH stopwords AS ( --------------------------------------------------------
    SELECT column1 AS word
    FROM VALUES
        ('a'),('an'),('and'),('are'),('as'),('at'),('be'),('but'),('by'),
        ('for'),('if'),('in'),('into'),('is'),('it'),('no'),('not'),('of'),
        ('on'),('or'),('such'),('that'),('the'),('their'),('then'),('there'),
        ('these'),('they'),('this'),('to'),('was'),('will'),('with'),('we'),
        ('our'),('you'),('your'),('from'),('up'),('down'),('out'),('over'),
        ('under')
),
/* ----------------------------------------------------------------------
   1.  Build weighted, unit-length vector for the query phrase
------------------------------------------------------------------------*/
query_tokens AS (
    SELECT LOWER(REGEXP_REPLACE(value,'[^a-zA-Z]+','')) AS token
    FROM TABLE(SPLIT_TO_TABLE(
         'Epigenetics and cerebral organoids: promising directions in autism spectrum disorders',' '))
    WHERE REGEXP_REPLACE(value,'[^a-zA-Z]+','') <> ''
),
query_filtered AS (
    SELECT qt.token
    FROM query_tokens qt
    LEFT JOIN stopwords s ON qt.token = s.word
    WHERE s.word IS NULL
),
query_vectors AS (
    SELECT
        gv."vector",
        POWER(wf."frequency", -0.4)::FLOAT AS weight
    FROM query_filtered q
    JOIN WORD_VECTORS_US.WORD_VECTORS_US.GLOVE_VECTORS      gv ON q.token = gv."word"
    JOIN WORD_VECTORS_US.WORD_VECTORS_US.WORD_FREQUENCIES   wf ON q.token = wf."word"
),
q_flat AS (
    SELECT
        f.index                      AS dim,
        (f.value::FLOAT) * qv.weight AS contrib
    FROM query_vectors qv,
         LATERAL FLATTEN(input => qv."vector") f
),
q_sum AS (
    SELECT dim, SUM(contrib) AS val
    FROM q_flat
    GROUP BY dim
),
q_norm AS (
    SELECT SQRT(SUM(POWER(val,2))) AS norm FROM q_sum
),
q_unit AS (
    SELECT dim, val / q_norm.norm AS val
    FROM q_sum, q_norm
),
/* ----------------------------------------------------------------------
   2.  Tokenise each article (first 1 000 tokens), compute unit vectors
------------------------------------------------------------------------*/
article_tokens AS (
    SELECT
        n."id",
        n."date",
        n."title",
        LOWER(REGEXP_REPLACE(f.value::STRING,'[^a-zA-Z]+','')) AS token
    FROM WORD_VECTORS_US.WORD_VECTORS_US.NATURE n,
         LATERAL FLATTEN(input => SPLIT(n."body",' ')) f
    WHERE f.index < 1000
      AND REGEXP_REPLACE(f.value::STRING,'[^a-zA-Z]+','') <> ''
),
article_filtered AS (
    SELECT at.*
    FROM article_tokens at
    LEFT JOIN stopwords s ON at.token = s.word
    WHERE s.word IS NULL
),
article_vectors AS (
    SELECT
        at."id",
        at."date",
        at."title",
        gv."vector",
        POWER(wf."frequency", -0.4)::FLOAT AS weight
    FROM article_filtered at
    JOIN WORD_VECTORS_US.WORD_VECTORS_US.GLOVE_VECTORS     gv ON at.token = gv."word"
    JOIN WORD_VECTORS_US.WORD_VECTORS_US.WORD_FREQUENCIES  wf ON at.token = wf."word"
),
a_flat AS (
    SELECT
        av."id",
        av."date",
        av."title",
        f.index                      AS dim,
        (f.value::FLOAT) * av.weight AS contrib
    FROM article_vectors av,
         LATERAL FLATTEN(input => av."vector") f
),
a_sum AS (
    SELECT
        "id","date","title",dim,
        SUM(contrib) AS val
    FROM a_flat
    GROUP BY "id","date","title",dim
),
a_norm AS (
    SELECT "id", SQRT(SUM(POWER(val,2))) AS norm
    FROM a_sum
    GROUP BY "id"
),
a_unit AS (
    SELECT
        s."id", s."date", s."title", s.dim,
        s.val / n.norm AS val
    FROM a_sum s
    JOIN a_norm n ON s."id" = n."id"
    WHERE n.norm > 0
),
/* ----------------------------------------------------------------------
   3.  Cosine similarity (dot product of unit vectors)
------------------------------------------------------------------------*/
similarity AS (
    SELECT
        a."id",
        a."date",
        a."title",
        SUM(a.val * q.val) AS cosine_sim
    FROM a_unit a
    JOIN q_unit q ON a.dim = q.dim
    GROUP BY a."id", a."date", a."title"
)
/* ----------------------------------------------------------------------
   4.  Top-10 results
------------------------------------------------------------------------*/
SELECT
    "id",
    "date",
    "title",
    cosine_sim
FROM similarity
ORDER BY cosine_sim DESC NULLS LAST
LIMIT 10;