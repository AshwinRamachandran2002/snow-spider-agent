WITH
/*-----------------------------------------------------------*/
/* 1) Tokenise every article body and remove English stopwords */
tokens AS (
    SELECT
        n."id",
        LOWER(f.value::STRING) AS word
    FROM WORD_VECTORS_US.WORD_VECTORS_US.NATURE n,
         LATERAL FLATTEN(
             INPUT => REGEXP_EXTRACT_ALL(
                         LOWER(n."body"),
                         '[A-Za-z0-9]+')
         ) f
    WHERE LOWER(f.value::STRING) NOT IN
          ('a','about','above','after','again','against','all','am','an','and',
           'any','are','as','at','be','because','been','before','being','below',
           'between','both','but','by','can','could','did','do','does','doing',
           'down','during','each','few','for','from','further','had','has','have',
           'having','he','her','here','hers','herself','him','himself','his','how',
           'i','if','in','into','is','it','its','itself','just','me','more','most',
           'my','myself','no','nor','not','now','of','off','on','once','only','or',
           'other','our','ours','ourselves','out','over','own','same','she',
           'should','so','some','such','than','that','the','their','theirs',
           'them','themselves','then','there','these','they','this','those',
           'through','to','too','under','until','up','very','was','we','were',
           'what','when','where','which','while','who','whom','why','will','with',
           'you','your','yours','yourself','yourselves')
),
/*-----------------------------------------------------------*/
/* 2) Attach each token’s GloVe vector and corpus frequency   */
word_data AS (
    SELECT
        t."id",
        gv."vector",
        wf."frequency"
    FROM tokens t
    JOIN WORD_VECTORS_US.WORD_VECTORS_US.GLOVE_VECTORS  gv ON gv."word" = t.word
    JOIN WORD_VECTORS_US.WORD_VECTORS_US.WORD_FREQUENCIES wf ON wf."word" = t.word
),
/*-----------------------------------------------------------*/
/* 3) Weight every token vector by  frequency^(-0.4)          */
token_vectors AS (
    SELECT
        wd."id",
        elem.index  AS idx,
        (elem.value::FLOAT) / POWER(wd."frequency", 0.4) AS val
    FROM word_data  wd,
         LATERAL FLATTEN(INPUT => wd."vector") elem
),
/*-----------------------------------------------------------*/
/* 4) Sum weighted vectors -> one aggregate vector / article  */
vector_sum AS (
    SELECT
        "id",
        idx,
        SUM(val) AS val
    FROM token_vectors
    GROUP BY "id", idx
),
/*-----------------------------------------------------------*/
/* 5) Compute L2-norm of each aggregate vector                */
norms AS (
    SELECT
        "id",
        SQRT( SUM( val * val ) ) AS norm
    FROM vector_sum
    GROUP BY "id"
),
/*-----------------------------------------------------------*/
/* 6) Convert aggregate vectors to unit length                */
norm_vectors AS (
    SELECT
        vs."id",
        vs.idx,
        vs.val / n.norm AS val
    FROM vector_sum vs
    JOIN norms n ON n."id" = vs."id"
    WHERE n.norm > 0
),
/*-----------------------------------------------------------*/
/* 7) Store the normalised reference article vector           */
ref_vector AS (
    SELECT
        idx,
        val AS ref_val
    FROM norm_vectors
    WHERE "id" = '8a78ef2d-d5f7-4d2d-9b47-5adb25cbd373'
),
/*-----------------------------------------------------------*/
/* 8) Cosine similarity = dot product of unit vectors         */
similarity AS (
    SELECT
        nv."id",
        SUM( nv.val * rv.ref_val ) AS cosine_similarity
    FROM norm_vectors nv
    JOIN ref_vector  rv ON rv.idx = nv.idx
    GROUP BY nv."id"
)
/*-----------------------------------------------------------*/
/* 9) Bring back article meta-data and list top-10 matches     */
SELECT
    n."id",
    n."date",
    n."title",
    s.cosine_similarity
FROM similarity s
JOIN WORD_VECTORS_US.WORD_VECTORS_US.NATURE n ON n."id" = s."id"
WHERE s."id" <> '8a78ef2d-d5f7-4d2d-9b47-5adb25cbd373'
ORDER BY s.cosine_similarity DESC NULLS LAST
LIMIT 10;