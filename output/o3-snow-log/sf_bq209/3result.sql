/* ---------------------------------------------------------------
   Patents granted in 2010 (utility type “A”) that received EXACTLY
   ONE distinct forward-citation (by citing application number)
   within ten years of their own filing date.
---------------------------------------------------------------- */
WITH publications_clean AS (      -- normalise dates, discard bad ones
    SELECT
        "publication_number",
        "application_number",
        "application_kind",
        TRY_TO_DATE("filing_date"::STRING , 'YYYYMMDD')  AS filing_dt,
        TRY_TO_DATE("grant_date" ::STRING , 'YYYYMMDD')  AS grant_dt,
        "citation"
    FROM PATENTS.PATENTS.PUBLICATIONS
),

target_patents AS (              -- utility patents granted in 2010
    SELECT
        "publication_number",
        "application_number",
        filing_dt
    FROM publications_clean
    WHERE "application_kind" = 'A'
      AND grant_dt BETWEEN '2010-01-01' AND '2010-12-31'
      AND filing_dt IS NOT NULL
),

citations_to_target AS (         -- forward citations within 10-year window
    SELECT
        t."publication_number"                       AS target_pub,
        c."application_number"                       AS citing_app
    FROM target_patents            t
    JOIN publications_clean        c
      ON TRUE                                   -- will filter in WHERE
    ,   LATERAL FLATTEN (INPUT => c."citation") cit
    WHERE cit.value:"publication_number"::STRING = t."publication_number"
      AND c.filing_dt IS NOT NULL
      AND c.filing_dt >  t.filing_dt
      AND c.filing_dt <= DATEADD(year, 10, t.filing_dt)
),

targets_with_one_citation AS (
    SELECT
        target_pub
    FROM citations_to_target
    GROUP BY target_pub
    HAVING COUNT(DISTINCT citing_app) = 1
)

SELECT COUNT(*) AS utility_patents_with_exactly_one_forward_citation_10yr
FROM   targets_with_one_citation;