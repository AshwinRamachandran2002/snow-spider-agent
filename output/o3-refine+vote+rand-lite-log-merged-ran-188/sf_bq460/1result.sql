/* --------------------------------------------------------------------------
   Build article-level sentence vectors and retrieve the 10 papers whose
   contents are most similar to the anchor article
   (id = '8a78ef2d-d5f7-4d2d-9b47-5adb25cbd373')
   -------------------------------------------------------------------------- */
WITH
/* ---- 1) vocabulary dictionary : word → (vector , frequency) -------------- */
dict AS (
    SELECT
        gv."word",
        gv."vector",          -- 300-D GloVe vector (VARIANT array)
        wf."frequency"
    FROM WORD_VECTORS_US.WORD_VECTORS_US.GLOVE_VECTORS      gv
    JOIN WORD_VECTORS_US.WORD_VECTORS_US.WORD_FREQUENCIES   wf
      ON wf."word" = gv."word"
),

/* ---- 2) tokenise every Nature article, keep tokens that exist in dict ---- */
tokens AS (
    SELECT
        n."id",
        n."title",
        n."date",
        d."vector"           AS vec,
        d."frequency"        AS freq
    FROM WORD_VECTORS_US.WORD_VECTORS_US.NATURE n,
         LATERAL SPLIT_TO_TABLE(
             REGEXP_REPLACE(LOWER(n."body"), '[^a-z0-9]+', ' '), ' '
         ) tok
    JOIN dict d
      ON d."word" = tok.VALUE
    /* stop-word removal */
    WHERE tok.VALUE <> ''
      AND tok.VALUE NOT IN (
          'a','about','above','after','again','against','ain','all','am','an','and',
          'any','are','aren','arent','as','at','be','because','been','before','being',
          'below','between','both','but','by','can','couldn','couldnt','d','did',
          'didn','didnt','do','does','doesn','doesnt','doing','don','dont','down',
          'during','each','few','for','from','further','had','hadn','hadnt','has',
          'hasn','hasnt','have','haven','havent','having','he','her','here','hers',
          'herself','him','himself','his','how','i','if','in','into','is','isn',
          'isnt','it','its','itself','just','ll','m','ma','me','mightn','mightnt',
          'more','most','mustn','mustnt','my','myself','needn','neednt','no','nor',
          'not','now','o','of','off','on','once','only','or','other','our','ours',
          'ourselves','out','over','own','re','s','same','shan','shant','she','shes',
          'should','shouldn','shouldnt','shouldve','so','some','such','t','than',
          'that','thatll','the','their','theirs','them','themselves','then','there',
          'these','they','this','those','through','to','too','under','until','up',
          've','very','was','wasn','wasnt','we','were','weren','werent','what','when',
          'where','which','while','who','whom','why','will','with','won','wont',
          'wouldn','wouldnt','y','you','youd','youll','your','youre','yours',
          'yourself','yourselves','youve'
      )
),

/* ---- 3) explode each (article , vector) into weighted components --------- */
weighted AS (
    SELECT
        t."id",
        f.INDEX                         AS dim,                 -- 0 … 299
        (f.VALUE::FLOAT) / POWER(t.freq , 0.4)  AS val          -- weight
    FROM tokens t,
         LATERAL FLATTEN(INPUT => t.vec) f
),

/* ---- 4) sum components → aggregate article vector ----------------------- */
agg AS (
    SELECT
        "id",
        dim,
        SUM(val)                        AS agg_val
    FROM weighted
    GROUP BY "id", dim
),

/* ---- 5) compute ℓ2 norm of every aggregate vector ----------------------- */
norms AS (
    SELECT
        "id",
        SQRT(SUM(agg_val * agg_val))    AS norm
    FROM agg
    GROUP BY "id"
),

/* ---- 6) obtain anchor (target) vector & its norm ------------------------ */
target_vec  AS ( SELECT dim, agg_val FROM agg   WHERE "id" = '8a78ef2d-d5f7-4d2d-9b47-5adb25cbd373' ),
target_norm AS ( SELECT norm          AS tgt_norm FROM norms WHERE "id" = '8a78ef2d-d5f7-4d2d-9b47-5adb25cbd373' ),

/* ---- 7) dot-product of every article with the target -------------------- */
dots AS (
    SELECT
        a."id",
        SUM(a.agg_val * t.agg_val)      AS dot_val
    FROM   agg         a
    JOIN   target_vec  t USING (dim)
    GROUP BY a."id"
),

/* ---- 8) cosine similarity ---------------------------------------------- */
cosines AS (
    SELECT
        dots."id",
        nat."date",
        nat."title",
        dots.dot_val / (n.norm * tn.tgt_norm)   AS cosine_similarity
    FROM dots
    JOIN norms                                  n   USING ("id")
    JOIN WORD_VECTORS_US.WORD_VECTORS_US.NATURE nat USING ("id")
    CROSS JOIN target_norm                      tn
)

SELECT
    "id",
    "date",
    "title",
    cosine_similarity
FROM   cosines
WHERE  "id" <> '8a78ef2d-d5f7-4d2d-9b47-5adb25cbd373'
ORDER  BY cosine_similarity DESC NULLS LAST
LIMIT  10;