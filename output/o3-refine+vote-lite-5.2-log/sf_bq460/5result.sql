/* ---------------------------------------------------------------
   Compute the 10 articles most similar to the target article
   ( id = '8a78ef2d-d5f7-4d2d-9b47-5adb25cbd373' )
   The workload is reduced by considering ONLY the words that
   occur in the target article, thus staying inside the time‑out.
---------------------------------------------------------------- */
WITH
/* --------------------------------------------------------------------
A. TOKENISE + STOP‑WORD FILTER  (helper so we write it only once)
-------------------------------------------------------------------- */
tokenised AS (
    SELECT
        n."id",
        LOWER(tok.value::string) AS word
    FROM WORD_VECTORS_US.WORD_VECTORS_US.NATURE n,
         LATERAL FLATTEN(
             INPUT => SPLIT(
                         REGEXP_REPLACE(LOWER(n."body"), '[^a-z0-9]+', ' '),
                         ' '
                     )
         ) tok
    WHERE tok.value IS NOT NULL
      AND tok.value <> ''
      -- stop‑words
      AND tok.value::string NOT IN (
          'a','about','above','after','again','against','ain','all','am','an',
          'and','any','are','aren','arent','as','at','be','because','been',
          'before','being','below','between','both','but','by','can','couldn',
          'couldnt','d','did','didn','didnt','do','does','doesn','doesnt',
          'doing','don','dont','down','during','each','few','for','from',
          'further','had','hadn','hadnt','has','hasn','hasnt','have','haven',
          'havent','having','he','her','here','hers','herself','him','himself',
          'his','how','i','if','in','into','is','isn','isnt','it','its',
          'itself','just','ll','m','ma','me','mightn','mightnt','more','most',
          'mustn','mustnt','my','myself','needn','neednt','no','nor','not',
          'now','o','of','off','on','once','only','or','other','our','ours',
          'ourselves','out','over','own','re','s','same','shan','shant','she',
          'shes','should','shouldn','shouldnt','shouldve','so','some','such',
          't','than','that','thatll','the','their','theirs','them','themselves',
          'then','there','these','they','this','those','through','to','too',
          'under','until','up','ve','very','was','wasn','wasnt','we','were',
          'weren','werent','what','when','where','which','while','who','whom',
          'why','will','with','won','wont','wouldn','wouldnt','y','you','youd',
          'youll','your','youre','yours','yourself','yourselves','youve'
      )
),
/* --------------------------------------------------------------------
B. DISTINCT WORD LIST FROM THE TARGET ARTICLE
-------------------------------------------------------------------- */
target_words AS (
    SELECT DISTINCT word
    FROM tokenised
    WHERE "id" = '8a78ef2d-d5f7-4d2d-9b47-5adb25cbd373'
),
/* --------------------------------------------------------------------
C. TOKEN rows for ALL ARTICLES but ONLY words that occur in target
-------------------------------------------------------------------- */
tokens AS (
    SELECT t."id", tw.word
    FROM tokenised t
    JOIN target_words tw
      ON t.word = tw.word
),
/* --------------------------------------------------------------------
D. JOIN VECTORS & FREQUENCIES, CALCULATE WEIGHT
-------------------------------------------------------------------- */
word_vectors AS (
    SELECT
        t."id",
        gv."vector"                    AS vec,
        POWER(wf."frequency", 0.4)     AS freq_pow04
    FROM tokens t
    JOIN WORD_VECTORS_US.WORD_VECTORS_US.GLOVE_VECTORS gv
      ON gv."word" = t.word
    JOIN WORD_VECTORS_US.WORD_VECTORS_US.WORD_FREQUENCIES wf
      ON wf."word" = t.word
),
/* --------------------------------------------------------------------
E. WEIGHT & FLATTEN VECTORS
-------------------------------------------------------------------- */
weighted_dims AS (
    SELECT
        w."id",
        v.index                        AS dim,
        (v.value::FLOAT) / w.freq_pow04 AS val
    FROM word_vectors w,
         LATERAL FLATTEN(INPUT => w.vec) v
),
/* --------------------------------------------------------------------
F. SUM PER ARTICLE & DIMENSION  (aggregate vector)
-------------------------------------------------------------------- */
agg_dims AS (
    SELECT
        "id",
        dim,
        SUM(val)                      AS val
    FROM weighted_dims
    GROUP BY "id", dim
),
/* --------------------------------------------------------------------
G. NORMALISE EACH ARTICLE VECTOR
-------------------------------------------------------------------- */
norms AS (
    SELECT
        "id",
        SQRT(SUM(val*val))            AS norm
    FROM agg_dims
    GROUP BY "id"
),
normalised AS (
    SELECT
        a."id",
        a.dim,
        a.val / n.norm                AS val
    FROM agg_dims a
    JOIN norms n USING ("id")
    WHERE n.norm <> 0
),
/* --------------------------------------------------------------------
H. TARGET VECTOR
-------------------------------------------------------------------- */
target_vec AS (
    SELECT dim, val
    FROM normalised
    WHERE "id" = '8a78ef2d-d5f7-4d2d-9b47-5adb25cbd373'
),
/* --------------------------------------------------------------------
I. COSINE SIMILARITY (only articles sharing ≥1 target word)
-------------------------------------------------------------------- */
similarity AS (
    SELECT
        n."id",
        SUM(n.val * t.val)            AS cosine_similarity
    FROM normalised n
    JOIN target_vec t
      ON n.dim = t.dim
    GROUP BY n."id"
)
SELECT
    s."id",
    n."date",
    n."title",
    s.cosine_similarity
FROM similarity s
JOIN WORD_VECTORS_US.WORD_VECTORS_US.NATURE n
  ON n."id" = s."id"
WHERE s."id" <> '8a78ef2d-d5f7-4d2d-9b47-5adb25cbd373'
ORDER BY s.cosine_similarity DESC NULLS LAST, s."id"
LIMIT 10;