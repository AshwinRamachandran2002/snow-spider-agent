/*  --------  Top-10 Nature articles closest to the query  -------- */
WITH
/* ---------------------------------------------------------- */
/* stop-words                                                 */
stopwords(word) AS (
  SELECT column1 FROM VALUES
    ('a'),('an'),('the'),('and'),('or'),('but'),('if'),('in'),('on'),
    ('to'),('of'),('for'),('with'),('at'),('by'),('from'),('up'),
    ('down'),('into'),('over'),('about'),('after'),('before'),
    ('between'),('through'),('during'),('without'),('within'),
    ('along'),('across'),('behind'),('beyond'),('under'),('again'),
    ('further'),('then'),('once'),('here'),('there'),('when'),
    ('where'),('why'),('how'),('all'),('any'),('both'),('each'),
    ('few'),('more'),('most'),('other'),('some'),('such'),('no'),
    ('nor'),('not'),('only'),('own'),('same'),('so'),('than'),
    ('too'),('very'),('can'),('will'),('just'),('is'),('are'),
    ('was'),('were'),('be'),('been'),('being'),('it'),('its'),
    ('that'),('this'),('these'),('those')
),

/* ---------------------------------------------------------- */
/* articles pre-filtered to ones that contain at least one    */
/* query keyword – keeps the job far smaller and faster       */
candidate_articles AS (
  SELECT "id","date","title","body"
  FROM   WORD_VECTORS_US.WORD_VECTORS_US.NATURE
  WHERE  LOWER("body") LIKE '%autism%'
     OR  LOWER("body") LIKE '%epigenetic%'
     OR  LOWER("body") LIKE '%cerebral%'
     OR  LOWER("body") LIKE '%organoid%'
),

/* ---------------------------------------------------------- */
/* user-query tokens                                           */
query_tokens(token) AS (
  SELECT column1 FROM VALUES
    ('epigenetics'),('cerebral'),('organoids'),('promising'),
    ('directions'),('autism'),('spectrum'),('disorders')
),

/* ---------------------------------------------------------- */
/* weighted summed vector for the query                        */
query_dim_sums AS (
  SELECT
      f.index                                            AS dim,
      SUM( f.value::DOUBLE /
           POWER(wf."frequency",0.4) )                   AS dim_sum
  FROM   query_tokens qt
  JOIN   WORD_VECTORS_US.WORD_VECTORS_US.GLOVE_VECTORS gv
         ON gv."word" = qt.token
  JOIN   WORD_VECTORS_US.WORD_VECTORS_US.WORD_FREQUENCIES wf
         ON wf."word" = qt.token,
         LATERAL FLATTEN(input => gv."vector") f
  GROUP  BY dim
),
query_norm AS (
  SELECT SQRT(SUM(dim_sum*dim_sum)) AS norm FROM query_dim_sums
),
query_vector AS (
  SELECT dim, dim_sum/query_norm.norm AS value
  FROM   query_dim_sums, query_norm
),

/* ---------------------------------------------------------- */
/* tokenise each candidate article                             */
article_tokens AS (
  SELECT
      ca."id",
      ca."date",
      ca."title",
      gv."vector"                       AS vec,
      1/POWER(wf."frequency",0.4)       AS weight
  FROM   candidate_articles ca
  CROSS  JOIN LATERAL SPLIT_TO_TABLE(
             REGEXP_REPLACE(LOWER(ca."body"),'[^a-z]+',' '), ' '
         ) tok
  LEFT   JOIN stopwords sw               ON sw.word = tok.value
  JOIN   WORD_VECTORS_US.WORD_VECTORS_US.GLOVE_VECTORS gv
           ON gv."word" = tok.value
  JOIN   WORD_VECTORS_US.WORD_VECTORS_US.WORD_FREQUENCIES wf
           ON wf."word" = tok.value
  WHERE  sw.word IS NULL
     AND tok.value <> ''
),

/* ---------------------------------------------------------- */
/* accumulate weighted dimensions per article                  */
article_dim_sums AS (
  SELECT
      at."id",
      at."date",
      at."title",
      f.index                                AS dim,
      SUM( f.value::DOUBLE * at.weight )     AS dim_sum
  FROM   article_tokens at,
         LATERAL FLATTEN(input => at.vec) f
  GROUP  BY at."id", at."date", at."title", dim
),
article_norms AS (
  SELECT "id",
         SQRT(SUM(dim_sum*dim_sum)) AS norm
  FROM   article_dim_sums
  GROUP  BY "id"
  HAVING norm > 0
),
article_vectors AS (
  SELECT
      ads."id",
      ads."date",
      ads."title",
      ads.dim,
      ads.dim_sum / an.norm               AS value
  FROM   article_dim_sums ads
  JOIN   article_norms  an ON an."id" = ads."id"
),

/* ---------------------------------------------------------- */
/* cosine similarity                                           */
article_similarities AS (
  SELECT
      av."id",
      av."date",
      av."title",
      SUM(av.value * qv.value)            AS cosine_similarity
  FROM   article_vectors av
  JOIN   query_vector qv
         ON qv.dim = av.dim
  GROUP  BY av."id", av."date", av."title"
)

/* ---------------------------------------------------------- */
SELECT
    "id",
    "date",
    "title",
    ROUND(cosine_similarity,4) AS cosine_similarity
FROM   article_similarities
ORDER  BY cosine_similarity DESC NULLS LAST
LIMIT 10;