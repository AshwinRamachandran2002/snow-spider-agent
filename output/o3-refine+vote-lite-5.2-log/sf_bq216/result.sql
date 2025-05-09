WITH target AS (   -- get embedding vector and filing year of reference patent
    SELECT  A."embedding_v1"  AS vec,
            P."filing_date"   AS filing_date
    FROM    PATENTS_GOOGLE.PATENTS_GOOGLE.ABS_AND_EMB  A
    JOIN    PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS P
           ON A."publication_number" = P."publication_number"
    WHERE   A."publication_number" = 'US-9741766-B2'
),
target_vec AS (    -- explode reference‑vector to (position , value)
    SELECT  f.index  AS pos,
            f.value::FLOAT AS val
    FROM    target,
            LATERAL FLATTEN(input => target.vec) f
),
others AS (        -- candidate patents filed in the same year, with embeddings
    SELECT  P."publication_number",
            A."embedding_v1" AS vec
    FROM    PATENTS_GOOGLE.PATENTS_GOOGLE.ABS_AND_EMB  A
    JOIN    PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS P
           ON A."publication_number" = P."publication_number"
    JOIN    target T
           ON FLOOR(P."filing_date" / 10000) = FLOOR(T.filing_date / 10000)   -- same filing year
    WHERE   A."publication_number" <> 'US-9741766-B2'
      AND   P."filing_date" IS NOT NULL
)
SELECT  res."publication_number"
FROM  (
        SELECT  o."publication_number",
                SUM(tv.val * ov.value::FLOAT) AS similarity
        FROM    others                                  o,
                LATERAL FLATTEN(input => o.vec)         ov,
                target_vec                              tv
        WHERE   tv.pos = ov.index
        GROUP BY o."publication_number"
      ) res
ORDER BY res.similarity DESC NULLS LAST,
         res."publication_number"
LIMIT 5;