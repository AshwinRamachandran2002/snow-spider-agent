WITH candidate AS (   -- US utility patents (B2) granted 2010‑2014
    SELECT
        p."publication_number",
        p."filing_date",
        TO_DATE(p."filing_date"::STRING,'YYYYMMDD')                    AS filing_dt,
        CAST(FLOOR(p."filing_date" / 10000) AS INT)                    AS filing_year
    FROM PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS p
    WHERE p."country_code"      = 'US'
      AND p."kind_code"         = 'B2'
      AND p."publication_date"  BETWEEN 20100101 AND 20141231
      AND p."application_kind"  = 'A'                       -- utility
      AND p."filing_date"       BETWEEN 10000101 AND 99991231
),
citations AS (         -- (citing , cited) pairs with citing filing date
    SELECT
        cp."publication_number"                                         AS citing_pub,
        TO_DATE(cp."filing_date"::STRING,'YYYYMMDD')                    AS citing_filing_dt,
        ct.value:"publication_number"::STRING                           AS cited_pub
    FROM PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS cp,
         LATERAL FLATTEN(input => cp."citation") ct
    WHERE ct.value:"publication_number" IS NOT NULL
      AND cp."filing_date" BETWEEN 10000101 AND 99991231
),
fwd_counts AS (        -- forward citations within 30 days of filing
    SELECT
        c."publication_number"                                          AS patent_number,
        COUNT(*)                                                        AS fwd_30d,
        c.filing_year
    FROM candidate c
    JOIN citations ci
      ON ci.cited_pub = c."publication_number"
     AND ci.citing_filing_dt BETWEEN c.filing_dt
                                 AND DATEADD('day', 30, c.filing_dt)
    GROUP BY c."publication_number", c.filing_year
),
best_with_emb AS (     -- best‑cited patent that also has an embedding
    SELECT
        fc.patent_number,
        fc.fwd_30d,
        fc.filing_year,
        e."embedding_v1"                                               AS best_vec,
        ROW_NUMBER() OVER (ORDER BY fc.fwd_30d DESC, fc.patent_number)  AS rn
    FROM fwd_counts fc
    JOIN PATENTS_GOOGLE.PATENTS_GOOGLE.ABS_AND_EMB e
      ON e."publication_number" = fc.patent_number
),
best AS (
    SELECT patent_number, fwd_30d, filing_year, best_vec
    FROM best_with_emb
    WHERE rn = 1
),
others AS (            -- embeddings of ALL patents filed in the same year
    SELECT
        op."publication_number",
        CAST(FLOOR(op."filing_date" / 10000) AS INT) AS filing_year,
        oe."embedding_v1"                               AS other_vec
    FROM PATENTS_GOOGLE.PATENTS_GOOGLE.ABS_AND_EMB  oe
    JOIN PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS op
      ON oe."publication_number" = op."publication_number"
    WHERE oe."embedding_v1" IS NOT NULL
      AND op."filing_date" BETWEEN 10000101 AND 99991231
),
similarities AS (      -- dot‑product similarity, computed manually
    SELECT
        b.patent_number,
        b.fwd_30d,
        o."publication_number"                         AS similar_patent,
        SUM(bv.value::FLOAT * ov.value::FLOAT)         AS sim_score
    FROM best b
    JOIN others o
      ON o.filing_year = b.filing_year
     AND o."publication_number" <> b.patent_number
    , LATERAL FLATTEN(input => b.best_vec) bv
    , LATERAL FLATTEN(input => o.other_vec) ov
    WHERE ov.index = bv.index
    GROUP BY b.patent_number, b.fwd_30d, o."publication_number"
),
ranked AS (
    SELECT
        s.*,
        ROW_NUMBER() OVER (ORDER BY s.sim_score DESC, s.similar_patent) AS rn
    FROM similarities s
)
SELECT
    patent_number,
    fwd_30d AS forward_citations_within_30_days,
    similar_patent AS most_similar_patent_from_same_filing_year
FROM ranked
WHERE rn = 1;