WITH tokens AS (                                                      -- tokenize every article body
    SELECT
        n."id"                                                            AS article_id,
        LOWER(tok.value::STRING)                                          AS word
    FROM WORD_VECTORS_US.WORD_VECTORS_US.NATURE n,
         LATERAL FLATTEN(
             INPUT => SPLIT(
                         REGEXP_REPLACE(COALESCE(n."body", ''), '[^\w]+', ' '),
                         ' ')
         ) tok
),                                                                      
filtered AS (                                                           -- remove blanks & stop‑words
    SELECT article_id, word
    FROM   tokens
    WHERE  word <> ''
       AND word NOT IN ( 'a','about','above','after','again','against','ain','all','am','an','and','any',
                         'are','aren','arent','as','at','be','because','been','before','being','below',
                         'between','both','but','by','can','couldn','couldnt','d','did','didn','didnt',
                         'do','does','doesn','doesnt','doing','don','dont','down','during','each','few',
                         'for','from','further','had','hadn','hadnt','has','hasn','hasnt','have','haven',
                         'havent','having','he','her','here','hers','herself','him','himself','his','how',
                         'i','if','in','into','is','isn','isnt','it','its','itself','just','ll','m','ma',
                         'me','mightn','mightnt','more','most','mustn','mustnt','my','myself','needn',
                         'neednt','no','nor','not','now','o','of','off','on','once','only','or','other',
                         'our','ours','ourselves','out','over','own','re','s','same','shan','shant','she',
                         'shes','should','shouldn','shouldnt','shouldve','so','some','such','t','than',
                         'that','thatll','the','their','theirs','them','themselves','then','there',
                         'these','they','this','those','through','to','too','under','until','up','ve',
                         'very','was','wasn','wasnt','we','were','weren','werent','what','when','where',
                         'which','while','who','whom','why','will','with','won','wont','wouldn','wouldnt',
                         'y','you','youd','youll','your','youre','yours','yourself','yourselves','youve')
),                                                                       
word_info AS (                                                           -- attach vectors & frequencies
    SELECT
        f.article_id                                             AS id,
        gv."vector"                                              AS raw_vec,
        COALESCE(wf."frequency", 1)                              AS freq
    FROM filtered f
    JOIN WORD_VECTORS_US.WORD_VECTORS_US.GLOVE_VECTORS    gv ON gv."word" = f.word
    LEFT JOIN WORD_VECTORS_US.WORD_VECTORS_US.WORD_FREQUENCIES wf ON wf."word" = f.word
),                                                                       
dim_values AS (                                                          -- weight each dimension
    SELECT
        wi.id,
        dim_item.index                                    AS dim,
        dim_item.value::FLOAT / POW(wi.freq, 0.4)         AS weighted_val
    FROM word_info wi,
         LATERAL FLATTEN( INPUT => wi.raw_vec ) dim_item          -- raw_vec is VARIANT array
),                                                                       
article_vec AS (                                                         -- summed vectors
    SELECT id, dim, SUM(weighted_val) AS val
    FROM   dim_values
    GROUP BY id, dim
),                                                                       
norms AS (                                                               -- L2 norms
    SELECT id, SQRT(SUM(val*val)) AS norm
    FROM   article_vec
    GROUP BY id
),                                                                       
article_norm AS (                                                        -- normalized vectors
    SELECT
        av.id,
        av.dim,
        CASE WHEN n.norm = 0 THEN 0 ELSE av.val / n.norm END AS nval
    FROM article_vec av
    JOIN norms       n ON n.id = av.id
),                                                                       
target AS (                                                              -- vector of target article
    SELECT dim, nval AS tgt_val
    FROM   article_norm
    WHERE  id = '8a78ef2d-d5f7-4d2d-9b47-5adb25cbd373'
),                                                                       
cosine AS (                                                              -- cosine similarity
    SELECT
        a.id,
        SUM( a.nval * COALESCE(t.tgt_val, 0) ) AS cos_sim
    FROM article_norm           a
    LEFT JOIN target            t ON t.dim = a.dim
    GROUP BY a.id
    HAVING a.id <> '8a78ef2d-d5f7-4d2d-9b47-5adb25cbd373'
),                                                                       
final AS (                                                               -- attach article metadata
    SELECT
        n."id",
        n."date",
        n."title",
        c.cos_sim
    FROM cosine                                     c
    JOIN WORD_VECTORS_US.WORD_VECTORS_US.NATURE n ON n."id" = c.id
)
SELECT
    "id",
    "date",
    "title",
    cos_sim
FROM final
ORDER BY cos_sim DESC NULLS LAST, "id"
LIMIT 10;