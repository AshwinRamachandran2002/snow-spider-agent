/*-----------------------------------------------------------------------
   Patents filed between 2014‑01‑01 and 2014‑02‑01 (inclusive) together
   with backward‑ and 5‑year forward‑citation counts.
   TRY_TO_DATE is used so that any malformed date strings become NULL and
   are safely ignored, preventing “Date … is not recognised” errors.
  ----------------------------------------------------------------------*/
WITH base AS (      /* filing window & core patent data */
    SELECT
        p."id"                         AS patent_id,
        p."title"                      AS title,
        p."abstract"                   AS abstract,
        TRY_TO_DATE(p."date")          AS pub_date,
        MIN(TRY_TO_DATE(a."date"))     AS app_date
    FROM PATENTSVIEW.PATENTSVIEW.PATENT      p
    JOIN PATENTSVIEW.PATENTSVIEW.APPLICATION a
          ON a."patent_id" = p."id"
    WHERE p."country" = 'US'
      AND TRY_TO_DATE(a."date") >= '2014-01-01'
      AND TRY_TO_DATE(a."date") <  '2014-02-02'  /* up to & incl. 01‑Feb‑2014 */
    GROUP BY p."id", p."title", p."abstract", p."date"
),
base_clean AS (      /* keep only rows with valid dates */
    SELECT *
    FROM base
    WHERE pub_date IS NOT NULL
      AND app_date IS NOT NULL
),

/* ---------- backward citations: cited patents dated before filing ---------- */
backward AS (
    SELECT
        uc."patent_id"                          AS patent_id,
        COUNT(DISTINCT uc."citation_id")        AS backward_cnt
    FROM PATENTSVIEW.PATENTSVIEW.USPATENTCITATION uc
    JOIN base_clean b
          ON b.patent_id = uc."patent_id"
    WHERE TRY_TO_DATE(uc."date") IS NOT NULL
      AND TRY_TO_DATE(uc."date") < b.app_date
    GROUP BY uc."patent_id"
),

/* ---------- forward citations: within 5 years of publication ---------- */
fwd AS (
    SELECT
        uc."citation_id"                        AS patent_id,       /* the focal patent */
        COUNT(DISTINCT uc."patent_id")          AS forward_cnt_5y
    FROM PATENTSVIEW.PATENTSVIEW.USPATENTCITATION uc
    JOIN base_clean b
          ON b.patent_id = uc."citation_id"
    JOIN PATENTSVIEW.PATENTSVIEW.PATENT  p_citing
          ON p_citing."id" = uc."patent_id"
    WHERE TRY_TO_DATE(p_citing."date") IS NOT NULL
      AND TRY_TO_DATE(p_citing."date") >= b.pub_date
      AND TRY_TO_DATE(p_citing."date") <  DATEADD(year, 5, b.pub_date)
    GROUP BY uc."citation_id"
)

/* ---------- final report ---------- */
SELECT
    b.patent_id                          AS "Patent_ID",
    b.title                              AS "Title",
    b.abstract                           AS "Abstract",
    b.pub_date                           AS "Publication_Date",
    COALESCE(bw.backward_cnt , 0)        AS "Backward_Citation_Count",
    COALESCE(fw.forward_cnt_5y, 0)       AS "Forward_Citation_Count_5Y"
FROM base_clean b
LEFT JOIN backward bw  ON bw.patent_id = b.patent_id
LEFT JOIN fwd     fw  ON fw.patent_id = b.patent_id
ORDER BY b.pub_date NULLS LAST, b.patent_id;