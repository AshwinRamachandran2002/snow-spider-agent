WITH early AS (   -- utility patents granted in 2010
    SELECT
        "publication_number",
        "filing_date"
    FROM PATENTS.PATENTS.PUBLICATIONS
    WHERE "grant_date" BETWEEN 20100101 AND 20101231
      AND "application_kind" = 'A'
),
citations AS (    -- flatten every citation in the dataset
    SELECT
        p."application_number"                       AS citing_app,
        p."filing_date"                              AS citing_filing,
        f.value:"publication_number"::STRING         AS cited_pub
    FROM PATENTS.PATENTS.PUBLICATIONS p,
         LATERAL FLATTEN(input => p."citation") f
),
cite_pairs AS (    -- keep only citations that fall within the 10‑year window
    SELECT
        e."publication_number"  AS early_pub,
        c.citing_app
    FROM early e
    JOIN citations c
      ON c.cited_pub = e."publication_number"
    WHERE c.citing_filing BETWEEN e."filing_date" 
                              AND (e."filing_date" + 100000)
),
forward_ct AS (    -- count distinct citing application numbers
    SELECT
        early_pub,
        COUNT(DISTINCT citing_app) AS forward_cite_cnt
    FROM cite_pairs
    GROUP BY early_pub
)
SELECT
    2010 AS grant_year,
    COUNT(*) AS patents_with_exactly_one_forward_citation
FROM forward_ct
WHERE forward_cite_cnt = 1;