WITH
-- ------------------------------------------------------------
-- 1. Stop-word list
-- ------------------------------------------------------------
stopwords(word) AS (
    SELECT column1 FROM VALUES
    ('a'),('an'),('the'),('and'),('or'),('but'),('if'),('while'),('with'),('without'),
    ('of'),('on'),('in'),('to'),('for'),('from'),('by'),('at'),('is'),('are'),('was'),
    ('were'),('be'),('been'),('being'),('this'),('that'),('these'),('those'),('as'),
    ('it'),('its'),('into'),('about'),('after'),('before'),('over'),('under'),
    ('again'),('further'),('then'),('once')
),

-- ------------------------------------------------------------
-- 2. Tokenise article body, remove punctuation & stop-words
-- ------------------------------------------------------------
article_words AS (
    SELECT
        n."id",
        n."date",
        n."title",
        LOWER(f.value::string) AS word
    FROM WORD_VECTORS_US.WORD_VECTORS_US.NATURE n,
         LATERAL FLATTEN(
             INPUT => SPLIT(
                         REGEXP_REPLACE(LOWER(n."body"), '[^a-z]', ' '),
                         ' ')
         ) f
    WHERE f.value IS NOT NULL
      AND f.value <> ''
      AND NOT EXISTS (SELECT 1 FROM stopwords s WHERE s.word = LOWER(f.value::string))
),

-- ------------------------------------------------------------
-- 3. Join word frequency and GloVe vector
-- ------------------------------------------------------------
word_data AS (
    SELECT
        aw."id",
        aw.word,
        wf."frequency",
        gv."vector"
    FROM article_words aw
    JOIN WORD_VECTORS_US.WORD_VECTORS_US.WORD_FREQUENCIES wf
         ON wf."word" = aw.word
    JOIN WORD_VECTORS_US.WORD_VECTORS_US.GLOVE_VECTORS gv
         ON gv."word" = aw.word
),

-- ------------------------------------------------------------
-- 4. Weight every vector element by frequency^-0.4
-- ------------------------------------------------------------
word_vector_flat AS (
    SELECT
        wd."id",
        vf.index AS idx,
        (vf.value::float / POWER(wd."frequency", 0.4)) AS weighted_value
    FROM word_data wd,
         LATERAL FLATTEN(INPUT => wd."vector") vf
),

-- ------------------------------------------------------------
-- 5. Sum weighted elements → raw article vector
-- ------------------------------------------------------------
article_vector AS (
    SELECT
        "id",
        idx,
        SUM(weighted_value) AS sum_val
    FROM word_vector_flat
    GROUP BY "id", idx
),

-- ------------------------------------------------------------
-- 6. Compute vector norms
-- ------------------------------------------------------------
norms AS (
    SELECT
        "id",
        SQRT(SUM(POWER(sum_val, 2))) AS norm_val
    FROM article_vector
    GROUP BY "id"
),

-- ------------------------------------------------------------
-- 7. Create normalised (unit-length) vectors
-- ------------------------------------------------------------
normalized_flat AS (
    SELECT
        av."id",
        av.idx,
        av.sum_val / nm.norm_val AS element
    FROM article_vector av
    JOIN norms nm
      ON nm."id" = av."id"
    WHERE nm.norm_val <> 0
),

-- ------------------------------------------------------------
-- 8. Reference article vector
-- ------------------------------------------------------------
reference_vector AS (
    SELECT
        idx,
        element AS ref_element
    FROM normalized_flat
    WHERE "id" = '8a78ef2d-d5f7-4d2d-9b47-5adb25cbd373'
),

-- ------------------------------------------------------------
-- 9. Cosine similarity (dot product, vectors are unit length)
-- ------------------------------------------------------------
cosine AS (
    SELECT
        nf."id",
        SUM(nf.element * rv.ref_element) AS cosine_similarity
    FROM normalized_flat nf
    JOIN reference_vector rv USING (idx)
    WHERE nf."id" <> '8a78ef2d-d5f7-4d2d-9b47-5adb25cbd373'
    GROUP BY nf."id"
)

-- ------------------------------------------------------------
-- 10. Return top-10 most similar articles
-- ------------------------------------------------------------
SELECT
    c."id",
    n."date",
    n."title",
    c.cosine_similarity
FROM cosine c
JOIN WORD_VECTORS_US.WORD_VECTORS_US.NATURE n
  ON n."id" = c."id"
ORDER BY c.cosine_similarity DESC NULLS LAST
LIMIT 10;