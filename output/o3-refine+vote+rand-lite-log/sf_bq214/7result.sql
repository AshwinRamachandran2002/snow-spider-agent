WITH candidates AS (    -- 1. US utility patents, kind B2, granted 2010‑2014
    SELECT
        p."publication_number",
        p."filing_date"
    FROM PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS p
    WHERE p."country_code"      = 'US'
      AND p."kind_code"         = 'B2'          -- granted utility patent
      AND p."application_kind"  = 'A'           -- utility‑type
      AND p."grant_date" BETWEEN 20100101 AND 20141231
      AND p."filing_date"       IS NOT NULL
      AND p."filing_date"       > 0
),
forward_cites AS (      -- 2. count forward citations made ≤30 days after filing
    SELECT
        cand."publication_number"                             AS target_pub,
        COUNT(DISTINCT citing."publication_number")           AS fwd_cite_count
    FROM candidates                     cand
    JOIN PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS citing
         ON citing."filing_date"
            BETWEEN cand."filing_date" AND cand."filing_date" + 30
    JOIN LATERAL FLATTEN(input => citing."citation") f
    WHERE f.value:"publication_number"::STRING = cand."publication_number"
    GROUP BY cand."publication_number"
),
top_candidate AS (      -- 3. pick patent with most such citations
    SELECT *
    FROM forward_cites
    ORDER BY fwd_cite_count DESC NULLS LAST, target_pub
    LIMIT 1
),
top_info AS (           -- 4. basic data of that top patent
    SELECT
        p."publication_number",
        p."filing_date",
        CAST(LEFT(p."filing_date"::STRING,4) AS INT) AS filing_year
    FROM PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS p
    JOIN top_candidate tc
      ON p."publication_number" = tc.target_pub
),
similar_list AS (       -- 5. list of Google‑pre‑computed “similar” patents
    SELECT
        s.value:"publication_number"::STRING AS similar_pub
    FROM PATENTS_GOOGLE.PATENTS_GOOGLE.ABS_AND_EMB a
    JOIN top_info ti
      ON a."publication_number" = ti."publication_number"
    , LATERAL FLATTEN(input => a."similar") s
),
same_year_similar AS (  -- 6. keep only those with the same filing year
    SELECT sl.similar_pub
    FROM similar_list sl
    JOIN PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS p
      ON p."publication_number" = sl.similar_pub
    WHERE CAST(LEFT(p."filing_date"::STRING,4) AS INT) =
          (SELECT filing_year FROM top_info)
    ORDER BY sl.similar_pub          -- arbitrary tie‑breaker
    LIMIT 1
)
SELECT
    tc.target_pub                    AS "PATENT_WITH_MOST_FORWARD_CITATIONS",
    tc.fwd_cite_count                AS "FORWARD_CITATIONS_WITHIN_30D",
    sys.similar_pub                  AS "MOST_SIMILAR_PATENT_SAME_FILING_YEAR"
FROM top_candidate tc
LEFT JOIN same_year_similar sys ON 1=1;