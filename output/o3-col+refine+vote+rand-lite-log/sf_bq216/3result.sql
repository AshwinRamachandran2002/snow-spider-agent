WITH target AS (   -- embedding of the focal patent
    SELECT "embedding_v1" AS emb
    FROM   PATENTS_GOOGLE.PATENTS_GOOGLE.ABS_AND_EMB
    WHERE  "publication_number" = 'US-9741766-B2'
),

cands AS (         -- embeddings of all other 2016-filed patents
    SELECT  a."publication_number",
            a."embedding_v1"
    FROM    PATENTS_GOOGLE.PATENTS_GOOGLE.ABS_AND_EMB   a
    JOIN    PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS  b
           ON a."publication_number" = b."publication_number"
    WHERE   FLOOR(b."filing_date" / 10000) = 2016      -- filing year = 2016
      AND   a."publication_number" <> 'US-9741766-B2'
      AND   a."embedding_v1" IS NOT NULL
),

sim AS (           -- dot-product similarity with the focal patent
    SELECT  c."publication_number",
            SUM(t_el.value::FLOAT * c_el.value::FLOAT) AS similarity
    FROM    target,
            cands c,
            LATERAL FLATTEN(input => target.emb)        t_el,
            LATERAL FLATTEN(input => c."embedding_v1")  c_el
    WHERE   t_el.index = c_el.index
    GROUP  BY c."publication_number"
)

SELECT  "publication_number"
FROM    sim
ORDER  BY similarity DESC NULLS LAST
LIMIT 5;