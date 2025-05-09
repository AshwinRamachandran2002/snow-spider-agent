WITH base_patents AS (   -- utility patents granted in 2010
    SELECT  p."publication_number",
            p."filing_date"
    FROM    PATENTS.PATENTS.PUBLICATIONS p
    WHERE   p."grant_date" BETWEEN 20100101 AND 20101231   -- granted in 2010
      AND   p."application_kind" = 'A'                     -- utility patents
),
flattened_citations AS (  -- explode citation arrays
    SELECT  b."publication_number",
            b."filing_date",
            f.value:"application_number"::STRING   AS "citing_app_no",
            f.value:"publication_date"::NUMBER     AS "citing_pub_date"
    FROM    base_patents b
    JOIN    PATENTS.PATENTS.PUBLICATIONS p
            ON p."publication_number" = b."publication_number"
            , LATERAL FLATTEN(input => p."citation") f
),
forward_citations AS (    -- keep distinct citing application numbers within 10-year window
    SELECT  "publication_number",
            "citing_app_no"
    FROM    flattened_citations
    WHERE   "citing_app_no" IS NOT NULL
      AND   "citing_app_no" <> ''
      AND   "citing_pub_date" BETWEEN "filing_date"
                                   AND ("filing_date" + 100000)   -- ≈10-year window
    GROUP BY "publication_number", "citing_app_no"
),
citation_counts AS (      -- count forward citations per patent
    SELECT  "publication_number",
            COUNT(*) AS "num_forward_cites"
    FROM    forward_citations
    GROUP BY "publication_number"
)
SELECT  COUNT(*) AS "num_patents_with_exactly_one_forward_citation"
FROM    citation_counts
WHERE   "num_forward_cites" = 1;