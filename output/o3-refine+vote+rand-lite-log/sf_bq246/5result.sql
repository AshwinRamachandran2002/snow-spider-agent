/*  Return the G06F patent that
      – has ≥1 backward citation whose application date is ≤1 year before its own
      – has ≥1 forward citation whose application date is ≤1 year after its own
      – report forward‑citation count accrued within 3 years
      – rank by number of such backward citations (highest first)              */

WITH app AS (               /* clean application dates; fix “‑00” day values */
    SELECT
        "patent_id"                                                     AS PATENT_ID,
        TRY_TO_DATE(
            REGEXP_REPLACE("date", '(^\\d{4}-\\d{2})-00$', '\\1-01')
        )                                                               AS APP_DATE
    FROM PATENTSVIEW.PATENTSVIEW.APPLICATION
    WHERE TRY_TO_DATE(
              REGEXP_REPLACE("date", '(^\\d{4}-\\d{2})-00$', '\\1-01')
          ) IS NOT NULL
),

cpc_pat AS (                 /* patents that have CPC group G06F               */
    SELECT DISTINCT
        "patent_id" AS PATENT_ID
    FROM PATENTSVIEW.PATENTSVIEW.CPC_CURRENT
    WHERE "group_id" = 'G06F'
),

/* -------- backward citations: cited ≤1 yr BEFORE focal patent ------------- */
backward_cnt AS (
    SELECT
        uc."patent_id"                          AS PATENT_ID,   -- focal patent
        COUNT(*)                                AS BACKWARD_1YR_CNT
    FROM PATENTSVIEW.PATENTSVIEW.USPATENTCITATION uc
    JOIN app curr   ON curr.PATENT_ID  = uc."patent_id"         -- focal
    JOIN app cited  ON cited.PATENT_ID = uc."citation_id"       -- cited
    WHERE DATEDIFF('day', cited.APP_DATE, curr.APP_DATE) BETWEEN 0 AND 365
    GROUP BY uc."patent_id"
),

/* -------- forward citations: citing ≤1 yr & ≤3 yrs AFTER focal patent ------ */
forward_cnt AS (
    SELECT
        uc."citation_id"                                           AS PATENT_ID,
        SUM( CASE WHEN DATEDIFF('day', curr.APP_DATE, citing.APP_DATE)
                       BETWEEN 0 AND 365  THEN 1 ELSE 0 END )      AS FORWARD_1YR_CNT,
        SUM( CASE WHEN DATEDIFF('day', curr.APP_DATE, citing.APP_DATE)
                       BETWEEN 0 AND 1095 THEN 1 ELSE 0 END )      AS FORWARD_3YR_CNT
    FROM PATENTSVIEW.PATENTSVIEW.USPATENTCITATION uc
    JOIN app curr   ON curr.PATENT_ID   = uc."citation_id"         -- focal
    JOIN app citing ON citing.PATENT_ID = uc."patent_id"           -- citing
    GROUP BY uc."citation_id"
),

/* ------------------- patents meeting both criteria ----------------------- */
candidate_patents AS (
    SELECT
        curr.PATENT_ID,
        curr.APP_DATE,
        b.BACKWARD_1YR_CNT,
        f.FORWARD_3YR_CNT
    FROM app            curr
    JOIN cpc_pat        c ON c.PATENT_ID = curr.PATENT_ID
    JOIN backward_cnt   b ON b.PATENT_ID = curr.PATENT_ID
    JOIN forward_cnt    f ON f.PATENT_ID = curr.PATENT_ID
    WHERE b.BACKWARD_1YR_CNT > 0    -- ≥1 backward citation
      AND f.FORWARD_1YR_CNT  > 0    -- ≥1 forward citation
)

/* ------------------------------ final result ----------------------------- */
SELECT
    PATENT_ID,
    APP_DATE                        AS APPLICATION_DATE,
    BACKWARD_1YR_CNT                AS BACKWARD_CITATIONS_1YR,
    FORWARD_3YR_CNT                 AS FORWARD_CITATIONS_3YR
FROM candidate_patents
ORDER BY BACKWARD_1YR_CNT DESC NULLS LAST, PATENT_ID
LIMIT 1;