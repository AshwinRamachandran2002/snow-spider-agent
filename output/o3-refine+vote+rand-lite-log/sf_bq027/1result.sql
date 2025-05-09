WITH sea_citations AS (
    /* Count SEA‑category backward citations for every publication */
    SELECT
        p."publication_number",
        COUNT(*) AS sea_backward_citation_count
    FROM PATENTS.PATENTS.PUBLICATIONS p,
         LATERAL FLATTEN(input => p."citation") c
    WHERE p."grant_date" BETWEEN 20100101 AND 20181231
          AND c.value:"category"::STRING = 'SEA'
    GROUP BY p."publication_number"
),
target_publications AS (
    /* All patents granted between 2010‑01‑01 and 2018‑12‑31 */
    SELECT
        "publication_number"
    FROM PATENTS.PATENTS.PUBLICATIONS
    WHERE "grant_date" BETWEEN 20100101 AND 20181231
)
SELECT
    t."publication_number",
    COALESCE(s.sea_backward_citation_count, 0) AS sea_backward_citation_count
FROM target_publications t
LEFT JOIN sea_citations s
       ON t."publication_number" = s."publication_number"
ORDER BY sea_backward_citation_count DESC NULLS LAST,
         t."publication_number";