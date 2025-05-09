WITH base_vec AS (                                   -- embedding of the focal patent
    SELECT  f.index  AS idx,
            f.value::FLOAT AS val
    FROM    PATENTS_GOOGLE.PATENTS_GOOGLE.ABS_AND_EMB,
            LATERAL FLATTEN(input => "embedding_v1") f
    WHERE   "publication_number" = 'US-9741766-B2'
),
focal_year AS (                                      -- filing‑year of the focal patent
    SELECT FLOOR("filing_date" / 10000) AS yr
    FROM   PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS
    WHERE  "publication_number" = 'US-9741766-B2'
),
candidates AS (                                      -- all other patents filed that year with embeddings
    SELECT  e."publication_number",
            e."embedding_v1"
    FROM    PATENTS_GOOGLE.PATENTS_GOOGLE.ABS_AND_EMB  e
    JOIN    PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS p
            ON e."publication_number" = p."publication_number"
    JOIN    focal_year fy
            ON FLOOR(p."filing_date" / 10000) = fy.yr
    WHERE   e."publication_number" <> 'US-9741766-B2'
)
SELECT  c."publication_number"
FROM    candidates c,
        LATERAL FLATTEN(input => c."embedding_v1") cf   -- explode candidate vector
JOIN    base_vec b
        ON b.idx = cf.index                             -- element‑wise multiplication
GROUP BY c."publication_number"
ORDER BY SUM(b.val * cf.value::FLOAT) DESC NULLS LAST,  -- similarity score
         c."publication_number" ASC
LIMIT 5;