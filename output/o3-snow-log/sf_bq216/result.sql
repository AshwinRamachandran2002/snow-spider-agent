WITH target AS (
    SELECT 
        a."embedding_v1"                          AS tgt_vec,
        FLOOR(p."filing_date" / 10000)            AS tgt_year
    FROM PATENTS_GOOGLE.PATENTS_GOOGLE.ABS_AND_EMB  a
    JOIN PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS p
          ON a."publication_number" = p."publication_number"
    WHERE a."publication_number" = 'US-9741766-B2'
),
same_year AS (
    SELECT 
        a."publication_number",
        a."embedding_v1"                         AS cand_vec
    FROM PATENTS_GOOGLE.PATENTS_GOOGLE.ABS_AND_EMB  a
    JOIN PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS p
          ON a."publication_number" = p."publication_number"
    CROSS JOIN target t
    WHERE FLOOR(p."filing_date" / 10000) = t.tgt_year      -- same filing year
      AND a."publication_number" <> 'US-9741766-B2'        -- exclude focal patent
),
scored AS (
    SELECT
        s."publication_number",
        SUM( (t_elem.value::FLOAT) * (c_elem.value::FLOAT) ) AS sim_score
    FROM same_year s
    CROSS JOIN target t
    , LATERAL FLATTEN(INPUT => t.tgt_vec)  t_elem
    , LATERAL FLATTEN(INPUT => s.cand_vec) c_elem
    WHERE t_elem.index = c_elem.index
    GROUP BY s."publication_number"
)
SELECT "publication_number"
FROM scored
ORDER BY sim_score DESC NULLS LAST
LIMIT 5;