WITH
/*------------------------------------------------------------------
  1)  Frequency and GloVe-vector lookup tables
------------------------------------------------------------------*/
freq AS (            -- word → frequency
    SELECT  LOWER("word")  AS word ,
            "frequency"    AS freq
    FROM    "WORD_VECTORS_US"."WORD_VECTORS_US"."WORD_FREQUENCIES"
),
vec  AS (            -- word → GloVe vector
    SELECT  LOWER("word")  AS word ,
            "vector"       AS vec
    FROM    "WORD_VECTORS_US"."WORD_VECTORS_US"."GLOVE_VECTORS"
),

/*------------------------------------------------------------------
  2)  Weighted / normalised vector of the query phrase
------------------------------------------------------------------*/
query_tokens AS (
    SELECT  LOWER(tok.value::string) AS token
    FROM    TABLE(
              FLATTEN(
                  INPUT => SPLIT(
                              REGEXP_REPLACE(
                                  LOWER('Epigenetics and cerebral organoids: promising directions in autism spectrum disorders'),
                                  '[^a-z0-9]+',
                                  ' '
                              ),
                              ' '
                          )
              )
            ) tok
    WHERE token <> ''
),
query_dim_vals AS (
    SELECT  v.seq                                AS dim ,
            SUM( (v.value::float) /
                 POW( COALESCE(f.freq,1) , 0.4) ) AS wval
    FROM   query_tokens qt
    JOIN   vec           gv  ON gv.word = qt.token
    LEFT  JOIN freq      f   ON f.word  = qt.token
    , LATERAL FLATTEN( INPUT => gv.vec ) v
    GROUP BY v.seq
),
query_norm AS (
    SELECT SQRT( SUM( POWER(wval,2) ) ) AS q_norm
    FROM   query_dim_vals
),

/*------------------------------------------------------------------
  3)  Candidate articles (pre-filter to cut work)
------------------------------------------------------------------*/
candidate AS (
    SELECT  "id", "date", "title", "body"
    FROM    "WORD_VECTORS_US"."WORD_VECTORS_US"."NATURE"
    WHERE   "body" ILIKE '%epigenetic%'
        OR  "body" ILIKE '%organoid%'
        OR  "body" ILIKE '%autism%'
),

/*------------------------------------------------------------------
  4)  Tokenise each candidate article body
------------------------------------------------------------------*/
article_tokens AS (
    SELECT  c."id"                              AS id ,
            c."date"                            AS art_date ,
            c."title"                           AS title ,
            LOWER(tok.value::string)            AS token
    FROM    candidate         c ,
            LATERAL FLATTEN(
                INPUT => SPLIT(
                            REGEXP_REPLACE( LOWER(c."body"), '[^a-z0-9]+', ' ' ),
                            ' '
                        )
            ) tok
    WHERE tok.value::string <> ''
),

/*------------------------------------------------------------------
  5)  Token counts per article  (reduces duplicate work)
------------------------------------------------------------------*/
article_token_counts AS (
    SELECT  id,
            art_date,
            title,
            token,
            COUNT(*) AS tok_count
    FROM    article_tokens
    GROUP BY id, art_date, title, token
),

/*------------------------------------------------------------------
  6)  Weighted summed vector for each article  (id × dim)
------------------------------------------------------------------*/
article_dims AS (
    SELECT  atc.id,
            atc.art_date,
            atc.title,
            vv.seq                                            AS dim ,
            SUM( atc.tok_count
                 * (vv.value::float)
                 / POW( COALESCE(f.freq,1) , 0.4) )           AS wval
    FROM   article_token_counts atc
    JOIN   vec                 gv  ON gv.word = atc.token
    LEFT  JOIN freq            f   ON f.word  = atc.token
    , LATERAL FLATTEN( INPUT => gv.vec ) vv
    GROUP BY atc.id, atc.art_date, atc.title, vv.seq
),

/*------------------------------------------------------------------
  7)  Dot-product with query vector & article vector norms
------------------------------------------------------------------*/
article_scores AS (
    SELECT  ad.id,
            ad.art_date,
            ad.title,
            SUM( ad.wval * COALESCE(q.wval,0) )    AS dot ,
            SUM( POWER(ad.wval,2) )                AS art_sq_sum
    FROM   article_dims   ad
    LEFT  JOIN query_dim_vals q ON q.dim = ad.dim
    GROUP BY ad.id, ad.art_date, ad.title
),

/*------------------------------------------------------------------
  8)  Cosine similarity
------------------------------------------------------------------*/
similarities AS (
    SELECT  id,
            art_date    AS date,
            title,
            dot / ( SQRT(art_sq_sum) * (SELECT q_norm FROM query_norm) ) AS similarity
    FROM    article_scores
    WHERE   art_sq_sum > 0
        AND dot IS NOT NULL
)

/*------------------------------------------------------------------
  9)  Top-10 most similar articles
------------------------------------------------------------------*/
SELECT  id,
        date,
        title,
        similarity
FROM    similarities
ORDER BY similarity DESC NULLS LAST
LIMIT 10;