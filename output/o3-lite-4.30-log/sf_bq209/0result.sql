WITH cited AS (
    SELECT
        "publication_number",
        "application_number",
        "filing_date"
    FROM PATENTS.PATENTS.PUBLICATIONS
    WHERE "grant_date" BETWEEN 20100101 AND 20101231      -- utility patents granted in 2010
      AND "application_kind" = 'A'
      AND "filing_date" IS NOT NULL
),
forward_cites AS (
    SELECT
        cited."publication_number",
        COUNT(DISTINCT citing."application_number") AS "fwd_cite_cnt"
    FROM PATENTS.PATENTS.PUBLICATIONS citing
    CROSS JOIN LATERAL FLATTEN(input => citing."citation") f
    JOIN cited
      ON  (f.value:"publication_number"::STRING = cited."publication_number"
           OR f.value:"application_number"::STRING = cited."application_number")
    WHERE citing."application_number" IS NOT NULL
      AND citing."filing_date" IS NOT NULL
      AND citing."filing_date" <= cited."filing_date" + 100000   -- within 10‑year window
      AND citing."application_number" <> cited."application_number"   -- exclude self‑citations
    GROUP BY cited."publication_number"
)
SELECT
    2010 AS "grant_year",
    COUNT(*) AS "patents_with_exactly_one_forward_citation"
FROM forward_cites
WHERE "fwd_cite_cnt" = 1;