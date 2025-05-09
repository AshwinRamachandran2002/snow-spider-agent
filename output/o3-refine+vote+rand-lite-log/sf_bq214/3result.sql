WITH candidate AS (   -- US utility patents (B2) granted 2010‑2014
    SELECT
        "publication_number",
        TRY_TO_DATE("filing_date"::STRING , 'YYYYMMDD')                 AS filing_dt,
        EXTRACT(YEAR FROM TRY_TO_DATE("filing_date"::STRING,'YYYYMMDD')) AS filing_year
    FROM PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS
    WHERE "country_code"   = 'US'
      AND "kind_code"      = 'B2'
      AND "application_kind" = 'A'          -- utility patent
      AND "grant_date" BETWEEN 20100101 AND 20141231
      AND TRY_TO_DATE("filing_date"::STRING,'YYYYMMDD') IS NOT NULL
),
forward_counts AS (   -- count forward citations made within 30 days of filing
    SELECT
        p."publication_number"                         AS origin_pub,
        p.filing_year,
        COUNT(DISTINCT q."publication_number")         AS forward_30d
    FROM candidate p
    JOIN PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS q      -- potential citing patents
          ON TRY_TO_DATE(q."filing_date"::STRING,'YYYYMMDD') IS NOT NULL
    CROSS JOIN LATERAL FLATTEN(input => q."citation") qc
    WHERE qc.value:"publication_number"::STRING = p."publication_number"
      AND DATEDIFF(
              'day',
              p.filing_dt,
              TRY_TO_DATE(q."filing_date"::STRING,'YYYYMMDD')
          ) BETWEEN 0 AND 30
    GROUP BY p."publication_number", p.filing_year
),
top_patent AS (       -- patent with most very‑early forward citations
    SELECT origin_pub, filing_year
    FROM forward_counts
    ORDER BY forward_30d DESC NULLS LAST, origin_pub
    LIMIT 1
),
sim_list AS (         -- patents Google lists as most text‑similar
    SELECT
        s.value:"publication_number"::STRING           AS sim_pub,
        s.index,
        tp.filing_year
    FROM top_patent tp
    JOIN PATENTS_GOOGLE.PATENTS_GOOGLE.ABS_AND_EMB ae
          ON ae."publication_number" = tp.origin_pub
    CROSS JOIN LATERAL FLATTEN(input => ae."similar") s
),
sim_year_filtered AS ( -- keep those filed in the same year, closest in list order
    SELECT sl.sim_pub
    FROM sim_list sl
    JOIN PATENTS_GOOGLE.PATENTS_GOOGLE.PUBLICATIONS p
          ON p."publication_number" = sl.sim_pub
    WHERE TRY_TO_DATE(p."filing_date"::STRING,'YYYYMMDD') IS NOT NULL
      AND EXTRACT(YEAR FROM TRY_TO_DATE(p."filing_date"::STRING,'YYYYMMDD')) = sl.filing_year
    ORDER BY sl.index
    LIMIT 1
)
SELECT
    tp.origin_pub                                           AS "PATENT_WITH_MOST_FORWARD_CITATIONS",
    syf.sim_pub                                             AS "MOST_SIMILAR_PATENT_SAME_YEAR"
FROM top_patent tp
LEFT JOIN sim_year_filtered syf ON 1=1;