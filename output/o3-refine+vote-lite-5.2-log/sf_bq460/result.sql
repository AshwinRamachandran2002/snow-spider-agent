WITH tokens AS (                 /*---- tokenize body & remove stop‑words ----*/
    SELECT
        n."id"      AS ID,       /*  make the column unquoted afterwards  */
        LOWER(TRIM(f.value::string)) AS WORD
    FROM "WORD_VECTORS_US"."WORD_VECTORS_US"."NATURE" n ,
         LATERAL FLATTEN(
             INPUT => SPLIT(
                 REGEXP_REPLACE(LOWER(n."body"), '[^A-Za-z0-9]+', ' '),
                 ' '
             )
         ) f
    WHERE WORD <> ''
      AND WORD NOT IN (          /* stop‑word list – same as tokenise_no_stop */
        'a','about','above','after','again','against','ain','all','am','an','and','any','are','aren','arent','as','at','be','because',
        'been','before','being','below','between','both','but','by','can','couldn','couldnt','d','did','didn','didnt','do','does',
        'doesn','doesnt','doing','don','dont','down','during','each','few','for','from','further','had','hadn','hadnt','has','hasn',
        'hasnt','have','haven','havent','having','he','her','here','hers','herself','him','himself','his','how','i','if','in','into',
        'is','isn','isnt','it','its','itself','just','ll','m','ma','me','mightn','mightnt','more','most','mustn','mustnt','my',
        'myself','needn','neednt','no','nor','not','now','o','of','off','on','once','only','or','other','our','ours','ourselves',
        'out','over','own','re','s','same','shan','shant','she','shes','should','shouldn','shouldnt','shouldve','so','some','such','t',
        'than','that','thatll','the','their','theirs','them','themselves','then','there','these','they','this','those','through',
        'to','too','under','until','up','ve','very','was','wasn','wasnt','we','were','weren','werent','what','when','where','which',
        'while','who','whom','why','will','with','won','wont','wouldn','wouldnt','y','you','youd','youll','your','youre','yours',
        'yourself','yourselves','youve'
      )
),
word_info AS (                     /*---- attach frequency & GloVe vector ----*/
    SELECT
        t.ID,
        wf."frequency",
        gv."vector",
        t.WORD
    FROM tokens t
    JOIN "WORD_VECTORS_US"."WORD_VECTORS_US"."WORD_FREQUENCIES"  wf ON wf."word" = t.WORD
    JOIN "WORD_VECTORS_US"."WORD_VECTORS_US"."GLOVE_VECTORS"     gv ON gv."word" = t.WORD
),
scaled_vectors AS (                /*---- scale vector by freq^-0.4 ----*/
    SELECT
        wi.ID,
        v.INDEX                 AS POS,
        v.VALUE::FLOAT / POW(wi."frequency", 0.4) AS VAL
    FROM word_info wi,
         LATERAL FLATTEN(INPUT => wi."vector") v
),
agg_vectors AS (                   /*---- sum per article per dimension ----*/
    SELECT ID, POS, SUM(VAL) AS SUM_VAL
    FROM   scaled_vectors
    GROUP  BY ID, POS
),
norms AS (                         /*---- magnitude of each article vector ----*/
    SELECT ID, SQRT(SUM(SUM_VAL*SUM_VAL)) AS MAG
    FROM   agg_vectors
    GROUP  BY ID
),
norm_vectors AS (                  /*---- normalised (unit) vectors ----*/
    SELECT
        a.ID,
        a.POS,
        CASE WHEN n.MAG = 0 THEN 0 ELSE a.SUM_VAL / n.MAG END AS NORM_VAL
    FROM agg_vectors a
    JOIN norms n ON n.ID = a.ID
),
ref_vec AS (                       /*---- vector of reference article ----*/
    SELECT POS, NORM_VAL
    FROM   norm_vectors
    WHERE  ID = '8a78ef2d-d5f7-4d2d-9b47-5adb25cbd373'
),
cosine_scores AS (                 /*---- cosine similarity to reference ----*/
    SELECT
        nv.ID,
        SUM(nv.NORM_VAL * rv.NORM_VAL) AS COSINE
    FROM norm_vectors nv
    JOIN ref_vec     rv ON rv.POS = nv.POS
    GROUP BY nv.ID
),
top10 AS (                         /*---- top‑10 most similar articles ----*/
    SELECT ID, COSINE
    FROM   cosine_scores
    WHERE  ID <> '8a78ef2d-d5f7-4d2d-9b47-5adb25cbd373'
    ORDER  BY COSINE DESC NULLS LAST, ID
    LIMIT  10
)
SELECT
    n."id",
    n."date",
    n."title",
    ROUND(t.COSINE, 4) AS COSINE_SIMILARITY
FROM   top10 t
JOIN   "WORD_VECTORS_US"."WORD_VECTORS_US"."NATURE" n
       ON n."id" = t.ID
ORDER  BY t.COSINE DESC NULLS LAST, n."id";