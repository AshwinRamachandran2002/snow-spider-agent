WITH target AS (
    /* obtain target patent’s filing year and its embedding */
    SELECT  p."publication_number",
            p."filing_date",
            FLOOR(p."filing_date" / 10000)            AS filing_year,
            e."embedding_v1"                          AS embedding
    FROM    PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS       p
    JOIN    PATENTS_GOOGLE.PATENTS_GOOGLE.ABS_AND_EMB        e
           ON p."publication_number" = e."publication_number"
    WHERE   p."publication_number" = 'US-9741766-B2'
),
target_vec AS (
    /* turn target embedding into (position, value) rows */
    SELECT  t."publication_number",
            f.index                                      AS pos,
            f.value::FLOAT                               AS val
    FROM    target t,
            LATERAL FLATTEN(input => t.embedding) f
),
candidates AS (
    /* every other patent filed in the same year that has an embedding */
    SELECT  p."publication_number",
            e."embedding_v1"        AS embedding
    FROM    PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS  p
    JOIN    PATENTS_GOOGLE.PATENTS_GOOGLE.ABS_AND_EMB   e
           ON p."publication_number" = e."publication_number"
    JOIN    target t
           ON FLOOR(p."filing_date" / 10000) = t.filing_year
    WHERE   p."publication_number" <> 'US-9741766-B2'
),
cand_vec AS (
    /* explode candidate embeddings */
    SELECT  c."publication_number",
            f.index                      AS pos,
            f.value::FLOAT               AS val
    FROM    candidates c,
            LATERAL FLATTEN(input => c.embedding) f
),
dot_prod AS (
    /* dot product between each candidate and the target */
    SELECT  cv."publication_number",
            SUM(cv.val * tv.val)         AS similarity
    FROM    cand_vec cv
    JOIN    target_vec tv
           ON cv.pos = tv.pos
    GROUP BY cv."publication_number"
)
SELECT      "publication_number"
FROM        dot_prod
ORDER BY    similarity DESC NULLS LAST
LIMIT 5;