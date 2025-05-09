/*  Return the U.S. patent (CPC group G06F) that
    • cites ≥1 patent filed within the year before its filing date, and
    • is cited by ≥1 patent filed within the year after its filing date.
    Show backward‑1 yr, forward‑1 yr, and forward‑3 yr citation counts,
    order by the backward‑1 yr count (highest first) and limit to 1 row.            */

WITH app AS (          -- earliest valid application date for every patent
    SELECT
        "patent_id",
        MIN(app_date) AS app_date
    FROM (
        SELECT
            "patent_id",
            TRY_TO_DATE("date") AS app_date          -- ignore malformed dates
        FROM PATENTSVIEW.PATENTSVIEW.APPLICATION
    )
    WHERE app_date IS NOT NULL
    GROUP BY "patent_id"
),

/* ----------  FOCAL PATENTS: US + chosen CPC group  ------------------------------- */
focal AS (
    SELECT
        p."id"                 AS patent_id,
        a.app_date
    FROM PATENTSVIEW.PATENTSVIEW.PATENT          p
    JOIN app                                     a  ON a."patent_id" = p."id"
    JOIN PATENTSVIEW.PATENTSVIEW.CPC_CURRENT     c  ON c."patent_id" = p."id"
    WHERE p."country" = 'US'
      AND c."group_id" = 'G06F'                      -- <-- CPC filter
),

/* ----------  BACKWARD citations (made by focal patents)  ------------------------- */
backward_1y AS (
    SELECT
        uc."patent_id"          AS patent_id,
        COUNT(*)                AS backward_citations_1y
    FROM PATENTSVIEW.PATENTSVIEW.USPATENTCITATION uc
    JOIN focal f          ON f.patent_id        = uc."patent_id"
    JOIN app   cited      ON cited."patent_id"  = uc."citation_id"
    WHERE cited.app_date >= DATEADD(year,-1,f.app_date)
      AND cited.app_date <  f.app_date
    GROUP BY uc."patent_id"
),

/* ----------  FORWARD citations (received by focal patents)  ---------------------- */
forward_window AS (
    SELECT
        uc."citation_id"        AS patent_id,
        SUM(CASE
                WHEN citing.app_date <= DATEADD(year,1,f.app_date) THEN 1
                ELSE 0
            END)                AS forward_citations_1y,
        SUM(CASE
                WHEN citing.app_date <= DATEADD(year,3,f.app_date) THEN 1
                ELSE 0
            END)                AS forward_citations_3y
    FROM PATENTSVIEW.PATENTSVIEW.USPATENTCITATION uc
    JOIN focal f           ON f.patent_id        = uc."citation_id"
    JOIN app   citing      ON citing."patent_id" = uc."patent_id"
    WHERE citing.app_date > f.app_date
    GROUP BY uc."citation_id"
)

/* ---------------------------  FINAL OUTPUT  -------------------------------------- */
SELECT
    f.patent_id,
    f.app_date                         AS application_date,
    b.backward_citations_1y,
    fw.forward_citations_1y,
    fw.forward_citations_3y
FROM focal            f
JOIN backward_1y      b  ON b.patent_id = f.patent_id
JOIN forward_window   fw ON fw.patent_id = f.patent_id
WHERE fw.forward_citations_1y > 0              -- ensure ≥1 forward‑1 yr
ORDER BY
    b.backward_citations_1y DESC NULLS LAST,
    f.patent_id
LIMIT 1;