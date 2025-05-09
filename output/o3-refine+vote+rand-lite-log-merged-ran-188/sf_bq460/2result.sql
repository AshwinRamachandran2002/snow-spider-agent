/* ---------------------------------------------------------------------------
   Build article-level vectors efficiently (word-count aggregation first)
---------------------------------------------------------------------------*/
WITH tokenized AS (                         -- 1. split body text into tokens
    SELECT  n."id",
            n."date",
            n."title",
            tok.value::string  AS word
    FROM    "WORD_VECTORS_US"."WORD_VECTORS_US"."NATURE" n,
            LATERAL SPLIT_TO_TABLE(
                     LOWER(REGEXP_REPLACE(n."body", '[^0-9A-Za-z]+', ' ')),
                     ' '
            ) tok
    WHERE   tok.value IS NOT NULL
      AND   tok.value <> ''
      AND   LENGTH(tok.value) > 2            -- ignore 1-2 letter strings
), 
word_counts AS (                             -- 2. count each word once per article
    SELECT  "id", "date", "title", word, COUNT(*) AS cnt
    FROM    tokenized
    GROUP BY "id", "date", "title", word
), 
word_info AS (                               -- 3. keep words present in both helper tables
    SELECT  wc."id",
            wc."date",
            wc."title",
            wc.word,
            wc.cnt,
            gv."vector"        AS vec,
            wf."frequency"     AS freq
    FROM    word_counts  wc
    JOIN    "WORD_VECTORS_US"."WORD_VECTORS_US"."GLOVE_VECTORS"     gv ON gv."word" = wc.word
    JOIN    "WORD_VECTORS_US"."WORD_VECTORS_US"."WORD_FREQUENCIES"  wf ON wf."word" = wc.word
), 
vector_components AS (                       -- 4. flatten vectors & apply weighting and word count
    SELECT  wi."id",
            wi."date",
            wi."title",
            fv.index             AS pos,
            (fv.value::FLOAT * wi.cnt) / POWER(wi.freq, 0.4)  AS val
    FROM    word_info wi,
            LATERAL FLATTEN(INPUT => wi.vec) fv
), 
article_vector AS (                          -- 5. sum components per article
    SELECT  "id", "date", "title", pos, SUM(val) AS comp
    FROM    vector_components
    GROUP BY "id","date","title", pos
), 
norms AS (                                   -- 6. compute Euclidean norm
    SELECT  "id", SQRT(SUM(comp*comp)) AS norm
    FROM    article_vector
    GROUP BY "id"
), 
unit_vec AS (                                -- 7. normalize vectors
    SELECT  av."id", av."date", av."title", av.pos, av.comp / n.norm AS uval
    FROM    article_vector av
    JOIN    norms n ON av."id" = n."id"
    WHERE   n.norm > 0
), 
target AS (                                  -- 8. vector of reference article
    SELECT  pos, uval AS tval
    FROM    unit_vec
    WHERE   "id" = '8a78ef2d-d5f7-4d2d-9b47-5adb25cbd373'
), 
similarities AS (                            -- 9. cosine similarities (dot product)
    SELECT  u."id", u."date", u."title",
            SUM(u.uval * t.tval) AS cos_sim
    FROM    unit_vec u
    JOIN    target  t ON u.pos = t.pos
    GROUP BY u."id", u."date", u."title"
) 
SELECT  "id",
        "date",
        "title",
        ROUND(cos_sim, 4) AS cosine_similarity
FROM    similarities
WHERE   "id" <> '8a78ef2d-d5f7-4d2d-9b47-5adb25cbd373'
ORDER BY cosine_similarity DESC NULLS LAST
LIMIT 10;