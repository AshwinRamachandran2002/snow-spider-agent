WITH tokens AS (
    /* Tokenise article body, keep alphabetic / numeric tokens, drop stop‑words */
    SELECT
        n."id",
        tok.value::STRING AS "word"
    FROM WORD_VECTORS_US.WORD_VECTORS_US.NATURE n,
         LATERAL SPLIT_TO_TABLE(
             REGEXP_REPLACE(LOWER(n."body"), '[^0-9a-z]+', ' '),
             ' '
         ) tok
    WHERE tok.value IS NOT NULL
      AND tok.value <> ''
      AND tok.value NOT IN
          ('a','about','above','after','again','against','ain','all','am','an','and','any','are','aren','arent',
           'as','at','be','because','been','before','being','below','between','both','but','by','can','couldn',
           'couldnt','d','did','didn','didnt','do','does','doesn','doesnt','doing','don','dont','down','during',
           'each','few','for','from','further','had','hadn','hadnt','has','hasn','hasnt','have','haven','havent',
           'having','he','her','here','hers','herself','him','himself','his','how','i','if','in','into','is',
           'isn','isnt','it','its','itself','just','ll','m','ma','me','mightn','mightnt','more','most','mustn',
           'mustnt','my','myself','needn','neednt','no','nor','not','now','o','of','off','on','once','only','or',
           'other','our','ours','ourselves','out','over','own','re','s','same','shan','shant','she','shes',
           'should','shouldn','shouldnt','shouldve','so','some','such','t','than','that','thatll','the','their',
           'theirs','them','themselves','then','there','these','they','this','those','through','to','too','under',
           'until','up','ve','very','was','wasn','wasnt','we','were','weren','werent','what','when','where',
           'which','while','who','whom','why','will','with','won','wont','wouldn','wouldnt','y','you','youd',
           'youll','your','youre','yours','yourself','yourselves','youve')
),
token_vecs AS (
    /* Keep tokens that have both a vector and a corpus frequency */
    SELECT
        t."id",
        gv."vector"     AS vec,
        wf."frequency"  AS freq
    FROM tokens t
    JOIN WORD_VECTORS_US.WORD_VECTORS_US.GLOVE_VECTORS    gv ON gv."word" = t."word"
    JOIN WORD_VECTORS_US.WORD_VECTORS_US.WORD_FREQUENCIES wf ON wf."word" = t."word"
),
weighted_dims AS (
    /* Weight each vector by frequency^‑0.4 and sum per dimension per article */
    SELECT
        tv."id",
        f.index                                    AS dim,
        SUM( f.value::FLOAT / POW(tv.freq, 0.4) ) AS dim_val
    FROM token_vecs tv,
         LATERAL FLATTEN(INPUT => tv.vec) f
    GROUP BY tv."id", f.index
),
magnitudes AS (
    /* Compute magnitude of each aggregate vector */
    SELECT
        "id",
        SQRT( SUM(dim_val * dim_val) ) AS mag
    FROM weighted_dims
    GROUP BY "id"
),
norm AS (
    /* Normalise aggregate vectors to unit length */
    SELECT
        d."id",
        d.dim,
        d.dim_val / m.mag AS val
    FROM weighted_dims d
    JOIN magnitudes m ON m."id" = d."id"
    WHERE m.mag > 0
),
target_vec AS (
    /* Normalised vector of the reference article */
    SELECT
        dim,
        val
    FROM norm
    WHERE "id" = '8a78ef2d-d5f7-4d2d-9b47-5adb25cbd373'
),
cosine AS (
    /* Cosine similarity (dot product of normalised vectors) */
    SELECT
        n."id",
        SUM( n.val * t.val ) AS cosine_similarity
    FROM norm n
    JOIN target_vec t ON n.dim = t.dim
    GROUP BY n."id"
),
result AS (
    SELECT
        c."id",
        art."date",
        art."title",
        c.cosine_similarity
    FROM cosine c
    JOIN WORD_VECTORS_US.WORD_VECTORS_US.NATURE art ON art."id" = c."id"
    WHERE c."id" <> '8a78ef2d-d5f7-4d2d-9b47-5adb25cbd373'
)
SELECT
    "id",
    "date",
    "title",
    ROUND(cosine_similarity, 4) AS cosine_similarity
FROM result
ORDER BY cosine_similarity DESC NULLS LAST, "id"
LIMIT 10;