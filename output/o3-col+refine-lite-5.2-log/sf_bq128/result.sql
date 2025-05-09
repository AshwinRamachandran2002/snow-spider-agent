WITH base AS (                                                          -- patents filed in window
    SELECT
        a."patent_id",
        a."date"                        AS "app_date",                  -- filing date
        p."title",
        p."abstract",
        p."date"                        AS "pub_date"                   -- publication date
    FROM PATENTSVIEW.PATENTSVIEW."APPLICATION"  a
    JOIN PATENTSVIEW.PATENTSVIEW."PATENT"       p
          ON p."id" = a."patent_id"
    WHERE a."country" = 'US'
      AND a."date" BETWEEN '2014-01-01' AND '2014-02-01'
),
-----------------------------------------------------------------------
backward AS (                                                           -- backward‑citation counts
    SELECT
        b."patent_id",
        COUNT(DISTINCT u."citation_id") AS "backward_cnt"
    FROM   base                                   b
    LEFT JOIN PATENTSVIEW.PATENTSVIEW."USPATENTCITATION" u
           ON u."patent_id" = b."patent_id"       -- cited by the focal patent
          AND u."date"      < b."app_date"        -- cited patent published before filing
    GROUP BY b."patent_id"
),
-----------------------------------------------------------------------
forward AS (                                                            -- forward‑citation counts (≤5 yrs)
    SELECT
        b."patent_id",
        COUNT(DISTINCT citing."id")   AS "forward_cnt_5yr"
    FROM   base                                   b
    LEFT JOIN PATENTSVIEW.PATENTSVIEW."USPATENTCITATION"  fc
           ON fc."citation_id" = b."patent_id"    -- patents that cite the focal patent
    LEFT JOIN PATENTSVIEW.PATENTSVIEW."PATENT"     citing
           ON citing."id" = fc."patent_id"
          AND citing."date" <= DATEADD(year, 5, b."pub_date")   -- within 5 years
    GROUP BY b."patent_id"
)
-----------------------------------------------------------------------
SELECT
    b."patent_id",
    b."title",
    b."abstract",
    b."pub_date"                  AS "publication_date",
    COALESCE(bw."backward_cnt",0) AS "backward_citation_count",
    COALESCE(fw."forward_cnt_5yr",0) AS "forward_citation_5yr"
FROM   base     b
LEFT  JOIN backward bw ON bw."patent_id" = b."patent_id"
LEFT  JOIN forward  fw ON fw."patent_id" = b."patent_id";