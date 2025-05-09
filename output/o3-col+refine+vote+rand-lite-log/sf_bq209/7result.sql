WITH target AS (                               -- 2010-granted utility patents
    SELECT
        "publication_number",
        "filing_date"
    FROM PATENTS.PATENTS.PUBLICATIONS
    WHERE "grant_date" BETWEEN 20100101 AND 20101231
      AND "application_kind" = 'A'
),
citings AS (                                   -- flattened forward-citation rows
    SELECT
        fl.value:"publication_number"::STRING  AS cited_pub,
        src."application_number"               AS citing_app,
        src."filing_date"                      AS citing_filing
    FROM PATENTS.PATENTS.PUBLICATIONS src,
         LATERAL FLATTEN(input => src."citation") fl
    INNER JOIN target tgt
            ON fl.value:"publication_number"::STRING = tgt."publication_number"
),
fwd_cnt AS (                                   -- count distinct citing apps within 10-yr window
    SELECT
        tgt."publication_number"               AS cited_pub,
        COUNT(DISTINCT cit.citing_app)         AS forward_cite_cnt
    FROM target tgt
    LEFT JOIN citings cit
           ON cit.cited_pub = tgt."publication_number"
          AND cit.citing_filing BETWEEN tgt."filing_date"
                                   AND tgt."filing_date" + 1000000   -- +10 years
    GROUP BY tgt."publication_number"
)
SELECT
    COUNT(*) AS "num_utility_patents_granted2010_with_one_forward_cite"
FROM fwd_cnt
WHERE forward_cite_cnt = 1;