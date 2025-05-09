WITH us_b2_2010_2014 AS (      -- 1) U.S. utility patents (kind B2) granted 2010‑2014
    SELECT
        p."publication_number",
        p."filing_date"
    FROM PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS p
    WHERE p."country_code"     = 'US'
      AND p."kind_code"        = 'B2'          -- granted utility patents
      AND p."application_kind" = 'A'
      AND p."grant_date" BETWEEN 20100101 AND 20141231
      AND p."filing_date" IS NOT NULL
),
early_cite_counts AS (         -- 2) forward citations ≤ 31 days after filing
    SELECT
        f."publication_number"                                AS focal_pub,
        COUNT(*)                                              AS forward_cites_within_31d
    FROM us_b2_2010_2014 f
    JOIN PATENTS_GOOGLE.PATENTS_GOOGLE.ABS_AND_EMB emb_f
      ON emb_f."publication_number" = f."publication_number"
    CROSS JOIN LATERAL FLATTEN(INPUT => emb_f."cited_by") citing
    JOIN PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS pc
      ON pc."publication_number" = citing.value:"publication_number"::STRING
    WHERE TRY_TO_DATE(pc."filing_date"::STRING,'YYYYMMDD') BETWEEN
          TRY_TO_DATE(f."filing_date"::STRING,'YYYYMMDD')
          AND DATEADD(day,31,TRY_TO_DATE(f."filing_date"::STRING,'YYYYMMDD'))
    GROUP BY focal_pub
),
top_focal AS (                 -- 3) patent with the most early forward citations
    SELECT
        ec.focal_pub,
        ec.forward_cites_within_31d,
        p2."filing_date"
    FROM early_cite_counts                          ec
    JOIN PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS p2
      ON p2."publication_number" = ec.focal_pub
    QUALIFY ROW_NUMBER()
            OVER (ORDER BY ec.forward_cites_within_31d DESC, ec.focal_pub) = 1
),
focal_vec AS (                 -- 4) embedding vector of that focal patent
    SELECT a."embedding_v1" AS vec
    FROM PATENTS_GOOGLE.PATENTS_GOOGLE.ABS_AND_EMB a
    JOIN top_focal tf ON tf.focal_pub = a."publication_number"
),
peer_candidates AS (           -- 5) all patents filed in the same calendar year
    SELECT
        p."publication_number",
        a."embedding_v1"
    FROM PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS p
    JOIN PATENTS_GOOGLE.PATENTS_GOOGLE.ABS_AND_EMB a
      ON a."publication_number" = p."publication_number"
    JOIN top_focal tf
      ON TO_CHAR(TRY_TO_DATE(p."filing_date"::STRING,'YYYYMMDD'),'YYYY') =
         TO_CHAR(TRY_TO_DATE(tf."filing_date"::STRING,'YYYYMMDD'),'YYYY')
    WHERE p."publication_number" <> tf.focal_pub
      AND TRY_TO_DATE(p."filing_date"::STRING,'YYYYMMDD') IS NOT NULL
),
similarity AS (                -- 6) dot‑product similarity with the focal patent
    SELECT
        pc."publication_number"                                   AS peer_pub,
        SUM(fv_el.value::FLOAT * pc_el.value::FLOAT)              AS dot_product
    FROM peer_candidates pc
    JOIN focal_vec fv ON TRUE                                     -- single‑row join
    CROSS JOIN LATERAL FLATTEN(INPUT => fv.vec)           fv_el
    CROSS JOIN LATERAL FLATTEN(INPUT => pc."embedding_v1") pc_el
    WHERE pc_el.index = fv_el.index                               -- align dimensions
    GROUP BY pc."publication_number"
),
top_peer AS (                  -- 7) most similar peer patent of that filing year
    SELECT
        peer_pub,
        dot_product
    FROM similarity
    QUALIFY ROW_NUMBER() OVER (ORDER BY dot_product DESC, peer_pub) = 1
)
-- 8) final result
SELECT
    tf.focal_pub                AS "focal_publication_number",
    tf.forward_cites_within_31d AS "forward_cites_within_31d",
    tp.peer_pub                 AS "most_similar_publication_number",
    tp.dot_product              AS "similarity_score"
FROM top_focal tf
JOIN top_peer  tp ON TRUE;