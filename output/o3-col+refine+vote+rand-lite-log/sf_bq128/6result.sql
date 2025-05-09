/*  Patents filed (U.S. applications) 2014-01-01 — 2014-02-01
    – title/abstract/publication date
    – backward-citation count (cited patents granted BEFORE filing date)
    – forward-citation count (citations received WITHIN 5 yrs of publication)
    All date conversions use TRY_TO_DATE to skip malformed rows such as
    “YYYY-MM-00”.                                               */
WITH base AS (                       -- focal patents + filing date
    SELECT
        a."patent_id",
        TRY_TO_DATE(a."date") AS "app_date"
    FROM PATENTSVIEW.PATENTSVIEW."APPLICATION" a
    WHERE a."country" = 'US'
      AND TRY_TO_DATE(a."date") BETWEEN '2014-01-01' AND '2014-02-01'
      AND TRY_TO_DATE(a."date") IS NOT NULL
),
biblio AS (                          -- bibliographic data
    SELECT
        p."id"                    AS "patent_id",
        p."title",
        p."abstract",
        TRY_TO_DATE(p."date")     AS "pub_date"
    FROM PATENTSVIEW.PATENTSVIEW."PATENT" p
    JOIN base b  ON p."id" = b."patent_id"
    WHERE TRY_TO_DATE(p."date") IS NOT NULL
),
backward AS (                        -- cited patents (before filing)
    SELECT
        u."patent_id",
        COUNT(DISTINCT u."citation_id") AS "backward_cnt"
    FROM PATENTSVIEW.PATENTSVIEW."USPATENTCITATION" u
    JOIN base b  ON u."patent_id" = b."patent_id"
    WHERE TRY_TO_DATE(u."date") < b."app_date"          -- pre-filing
      AND TRY_TO_DATE(u."date") IS NOT NULL
    GROUP BY u."patent_id"
),
forward AS (                         -- citations received within 5 years
    SELECT
        u."citation_id"                 AS "patent_id",
        COUNT(DISTINCT u."patent_id")   AS "forward_cnt"
    FROM PATENTSVIEW.PATENTSVIEW."USPATENTCITATION" u
    JOIN biblio pb  ON pb."patent_id" = u."citation_id"
    JOIN PATENTSVIEW.PATENTSVIEW."PATENT" pc
         ON pc."id" = u."patent_id"
    WHERE pb."pub_date" IS NOT NULL
      AND TRY_TO_DATE(pc."date") IS NOT NULL
      AND TRY_TO_DATE(pc."date")
            <= DATEADD(year, 5, pb."pub_date")          -- ≤5-yr window
    GROUP BY u."citation_id"
)
SELECT
    b."patent_id",
    b."title",
    b."abstract",
    b."pub_date",
    COALESCE(back."backward_cnt", 0)  AS "backward_citation_count",
    COALESCE(fwd."forward_cnt", 0)    AS "forward_citation_5yr_count"
FROM biblio b
LEFT JOIN backward back ON b."patent_id" = back."patent_id"
LEFT JOIN forward  fwd  ON b."patent_id" = fwd."patent_id"
ORDER BY b."pub_date", b."patent_id";