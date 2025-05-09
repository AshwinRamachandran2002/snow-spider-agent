/*  Patents (CPC subsections G06 or H04)
    – ≥1 backward citation whose application date is ≤1 yr before the focal patent’s application date
    – ≥1 forward citation whose application date is ≤1 yr after the focal patent’s application date
    – Count forward citations whose application date is ≤3 yrs after the focal patent’s application date
    Return the single patent with the most backward‐citation matches.
*/
WITH
/* 1-yr backward citations (earlier patents that the focal patent cites) */
back_1yr AS (
    SELECT
        uc."patent_id"                         AS cited_by_patent,  -- focal patent
        COUNT(*)                               AS back_cnt_1yr
    FROM PATENTSVIEW.PATENTSVIEW."USPATENTCITATION" uc
    JOIN PATENTSVIEW.PATENTSVIEW."APPLICATION" app_later
         ON uc."patent_id" = app_later."patent_id"
    JOIN PATENTSVIEW.PATENTSVIEW."APPLICATION" app_earlier
         ON uc."citation_id" = app_earlier."patent_id"
    WHERE
          TRY_TO_DATE(app_later."date")   IS NOT NULL
      AND TRY_TO_DATE(app_earlier."date") IS NOT NULL
      AND DATEDIFF(
              'day',
              TRY_TO_DATE(app_earlier."date"),   -- earlier application
              TRY_TO_DATE(app_later."date")      -- focal application
          ) BETWEEN 0 AND 365                    -- ≤ 1 year before
    GROUP BY uc."patent_id"
),
/* 1-yr forward citations (later patents that cite the focal patent) */
fwd_1yr AS (
    SELECT
        uc."citation_id"                       AS cited_patent,     -- focal patent
        COUNT(*)                               AS fwd_cnt_1yr
    FROM PATENTSVIEW.PATENTSVIEW."USPATENTCITATION" uc
    JOIN PATENTSVIEW.PATENTSVIEW."APPLICATION" app_focal
         ON uc."citation_id" = app_focal."patent_id"
    JOIN PATENTSVIEW.PATENTSVIEW."APPLICATION" app_later
         ON uc."patent_id" = app_later."patent_id"
    WHERE
          TRY_TO_DATE(app_focal."date") IS NOT NULL
      AND TRY_TO_DATE(app_later."date") IS NOT NULL
      AND DATEDIFF(
              'day',
              TRY_TO_DATE(app_focal."date"),     -- focal application
              TRY_TO_DATE(app_later."date")      -- citing application
          ) BETWEEN 0 AND 365                    -- ≤ 1 year after
    GROUP BY uc."citation_id"
),
/* 3-yr forward citations (used for final output) */
fwd_3yr AS (
    SELECT
        uc."citation_id"                       AS cited_patent,     -- focal patent
        COUNT(*)                               AS fwd_cnt_3yr
    FROM PATENTSVIEW.PATENTSVIEW."USPATENTCITATION" uc
    JOIN PATENTSVIEW.PATENTSVIEW."APPLICATION" app_focal
         ON uc."citation_id" = app_focal."patent_id"
    JOIN PATENTSVIEW.PATENTSVIEW."APPLICATION" app_later
         ON uc."patent_id" = app_later."patent_id"
    WHERE
          TRY_TO_DATE(app_focal."date") IS NOT NULL
      AND TRY_TO_DATE(app_later."date") IS NOT NULL
      AND DATEDIFF(
              'day',
              TRY_TO_DATE(app_focal."date"),
              TRY_TO_DATE(app_later."date")
          ) BETWEEN 0 AND 1095                   -- ≤ 3 years after
    GROUP BY uc."citation_id"
)

SELECT
    b.cited_by_patent  AS "patent_id",
    b.back_cnt_1yr     AS "num_backward_citations_1yr_before",
    f1.fwd_cnt_1yr     AS "num_forward_citations_1yr_after",
    f3.fwd_cnt_3yr     AS "num_forward_citations_3yrs_after"
FROM back_1yr b
JOIN fwd_1yr f1
     ON b.cited_by_patent = f1.cited_patent
JOIN fwd_3yr f3
     ON b.cited_by_patent = f3.cited_patent
JOIN PATENTSVIEW.PATENTSVIEW."CPC_CURRENT" cc
     ON b.cited_by_patent = cc."patent_id"
WHERE cc."subsection_id" IN ('G06', 'H04')        -- restrict to chosen CPC categories
ORDER BY b.back_cnt_1yr DESC NULLS LAST
LIMIT 1;