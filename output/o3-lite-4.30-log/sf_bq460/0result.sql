/* -----------------------------------------------------------------------------
   Top‑10 Nature articles most similar to
   ID = 8a78ef2d-d5f7-4d2d-9b47-5adb25cbd373
----------------------------------------------------------------------------- */
WITH
/* -------------------------------------------------------------------------- */
/* 1. Tokenise article bodies, remove stop‑words and keep words present in    */
/*    both the GloVe and frequency tables                                     */
base_tokens AS (
    SELECT  n."id",
            n."title",
            n."date",
            LOWER(tok.value::STRING) AS token
    FROM   "WORD_VECTORS_US"."WORD_VECTORS_US"."NATURE"  n,
           LATERAL FLATTEN(
                   input => SPLIT(
                              REGEXP_REPLACE(COALESCE(n."body", ''), '[^A-Za-z0-9]+', ' '),
                              ' ')
           ) tok
    WHERE  tok.value IS NOT NULL
      AND  tok.value <> ''
      AND  LOWER(tok.value::STRING) NOT IN
         ('a','about','above','after','again','against','ain','all','am','an','and','any','are','arent',
          'as','at','be','because','been','before','being','below','between','both','but','by','can',
          'could','couldnt','d','did','didn','do','does','doesn','doing','don','down','during','each',
          'few','for','from','further','had','hadn','has','hasn','have','haven','having','he','her',
          'here','hers','herself','him','himself','his','how','i','if','in','into','is','isn','it',
          'its','itself','just','ll','m','ma','me','mightn','more','most','mustn','my','myself','needn',
          'no','nor','not','now','o','of','off','on','once','only','or','other','our','ours','ourselves',
          'out','over','own','re','s','same','shan','she','should','so','some','such','t','than','that',
          'the','their','theirs','them','themselves','then','there','these','they','this','those',
          'through','to','too','under','until','up','ve','very','was','wasn','we','were','weren','what',
          'when','where','which','while','who','whom','why','will','with','won','wouldn','y','you',
          'your','yours','yourself','yourselves')
      AND  EXISTS (SELECT 1
                   FROM "WORD_VECTORS_US"."WORD_VECTORS_US"."GLOVE_VECTORS" gv
                   WHERE gv."word" = LOWER(tok.value::STRING))
      AND  EXISTS (SELECT 1
                   FROM "WORD_VECTORS_US"."WORD_VECTORS_US"."WORD_FREQUENCIES" wf
                   WHERE wf."word" = LOWER(tok.value::STRING))
),
/* -------------------------------------------------------------------------- */
/* 2. Weighted vector components (vector / frequency^0.4)                     */
token_dims AS (
    SELECT  bt."id",
            bt."title",
            bt."date",
            fv.index                                      AS dim,
            fv.value::FLOAT /
            POWER(wf."frequency", 0.4)                   AS wval
    FROM    base_tokens                         bt
    JOIN    "WORD_VECTORS_US"."WORD_VECTORS_US"."GLOVE_VECTORS"      gv
           ON bt.token = gv."word"
    JOIN    "WORD_VECTORS_US"."WORD_VECTORS_US"."WORD_FREQUENCIES"   wf
           ON bt.token = wf."word",
           LATERAL FLATTEN(input => gv."vector") fv
),
/* -------------------------------------------------------------------------- */
/* 3. Sum weighted components per article & dimension                         */
article_vec AS (
    SELECT  "id", "title", "date", dim, SUM(wval) AS val
    FROM    token_dims
    GROUP BY "id", "title", "date", dim
),
/* -------------------------------------------------------------------------- */
/* 4. Compute Euclidean norm for each article vector                          */
magnitudes AS (
    SELECT  "id", SQRT(SUM(val * val)) AS mag
    FROM    article_vec
    GROUP BY "id"
    HAVING  mag > 0
),
/* -------------------------------------------------------------------------- */
/* 5. Normalise article vectors                                               */
norm_vecs AS (
    SELECT  av."id",
            av."title",
            av."date",
            av.dim,
            av.val / m.mag AS nval
    FROM    article_vec av
    JOIN    magnitudes m USING ("id")
),
/* -------------------------------------------------------------------------- */
/* 6. Target article’s normalised vector                                      */
target_vec AS (
    SELECT dim, nval
    FROM   norm_vecs
    WHERE  "id" = '8a78ef2d-d5f7-4d2d-9b47-5adb25cbd373'
),
/* -------------------------------------------------------------------------- */
/* 7. Cosine similarity (dot product of unit vectors)                         */
similarities AS (
    SELECT  nv."id",
            nv."date",
            nv."title",
            SUM(nv.nval * tv.nval) AS cosine_similarity
    FROM    norm_vecs nv
    JOIN    target_vec tv USING (dim)
    WHERE   nv."id" <> '8a78ef2d-d5f7-4d2d-9b47-5adb25cbd373'
    GROUP BY nv."id", nv."date", nv."title"
)
/* -------------------------------------------------------------------------- */
/* 8. Return the 10 most similar articles                                     */
SELECT
       "id",
       "date",
       "title",
       ROUND(cosine_similarity, 4) AS cosine_similarity
FROM   similarities
ORDER  BY cosine_similarity DESC NULLS LAST,
          "id"
LIMIT 10;