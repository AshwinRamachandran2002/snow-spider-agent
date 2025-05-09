/* ------------------------------------------------------------
   Patents with CPC subsection = 'C05'  OR  CPC group = 'A01G'
   Backward citations : 0‑30 days BEFORE application date
   Forward  citations : 0‑30 days AFTER  application date
   ------------------------------------------------------------ */
WITH app_dates AS (          /* earliest VALID application date per patent */
    SELECT
        "patent_id",
        MIN( TRY_TO_DATE("date") ) AS app_date
    FROM PATENTSVIEW.PATENTSVIEW."APPLICATION"
    WHERE TRY_TO_DATE("date") IS NOT NULL          -- skip bad dates such as YYYY‑MM‑00
    GROUP BY "patent_id"
),
cpc_pool AS (                /* patents that meet the CPC filter */
    SELECT DISTINCT "patent_id"
    FROM PATENTSVIEW.PATENTSVIEW."CPC_CURRENT"
    WHERE "group_id"      = 'A01G'
       OR "subsection_id" = 'C05'
),
target_patents AS (          /* focal patents with metadata & application date */
    SELECT
        p."id"        AS patent_id,
        p."title"     AS title,
        p."abstract"  AS abstract,
        a.app_date
    FROM PATENTSVIEW.PATENTSVIEW."PATENT" p
    JOIN cpc_pool  cp ON cp."patent_id" = p."id"
    JOIN app_dates a  ON a."patent_id"  = p."id"
),
/* backward citations (focal patent -> cited) within 30 days before focal app_date */
backward AS (
    SELECT
        tp.patent_id,
        COUNT(*) AS back_cnt
    FROM target_patents tp
    JOIN PATENTSVIEW.PATENTSVIEW."USPATENTCITATION" uc
         ON uc."patent_id" = tp.patent_id
    JOIN app_dates ac ON ac."patent_id" = uc."citation_id"
    WHERE ac.app_date IS NOT NULL
      AND DATEDIFF('day', ac.app_date, tp.app_date) BETWEEN 0 AND 30
    GROUP BY tp.patent_id
),
/* forward citations (later patent -> focal) within 30 days after focal app_date */
forward AS (
    SELECT
        tp.patent_id,
        COUNT(*) AS fwd_cnt
    FROM target_patents tp
    JOIN PATENTSVIEW.PATENTSVIEW."USPATENTCITATION" uc
         ON uc."citation_id" = tp.patent_id
    JOIN app_dates ac ON ac."patent_id" = uc."patent_id"
    WHERE ac.app_date IS NOT NULL
      AND DATEDIFF('day', tp.app_date, ac.app_date) BETWEEN 0 AND 30
    GROUP BY tp.patent_id
)

SELECT
    tp.patent_id                        AS "PATENT_ID",
    tp.title                            AS "TITLE",
    tp.app_date                         AS "APPLICATION_DATE",
    COALESCE(b.back_cnt, 0)             AS "BACKWARD_CITATIONS_1M",
    COALESCE(f.fwd_cnt, 0)              AS "FORWARD_CITATIONS_1M",
    tp.abstract                         AS "ABSTRACT"
FROM target_patents tp
LEFT JOIN backward b ON b.patent_id = tp.patent_id
LEFT JOIN forward  f ON f.patent_id = tp.patent_id
WHERE COALESCE(b.back_cnt,0) > 0
   OR COALESCE(f.fwd_cnt,0) > 0
ORDER BY tp.app_date, tp.patent_id;