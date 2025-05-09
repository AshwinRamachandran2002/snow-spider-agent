/*  Patents in CPC groups G06F or H04L that
    • have ≥1 backward citation whose application date is ≤1 year before their own
    • have ≥1 forward citation whose application date is ≤1 year after their own
    • return the count of forward citations received within the first 3 years
      and output the single patent with the most qualifying backward citations      */

WITH target_cpc AS (          -- patents in the requested CPC groups
    SELECT DISTINCT "patent_id"
    FROM PATENTSVIEW.PATENTSVIEW.CPC_CURRENT
    WHERE "group_id" IN ('G06F', 'H04L')
),

app_dates AS (                -- application dates
    SELECT  "patent_id",
            TRY_TO_DATE("date",'YYYY-MM-DD') AS app_date
    FROM PATENTSVIEW.PATENTSVIEW.APPLICATION
    WHERE "date" IS NOT NULL
),

/* ---------- backward citations ≤1 year BEFORE filing ---------- */
back AS (
    SELECT  p."patent_id",
            COUNT(*) AS back_cnt
    FROM   app_dates                    p
    JOIN   target_cpc                   tc   ON p."patent_id" = tc."patent_id"
    JOIN   PATENTSVIEW.PATENTSVIEW.USPATENTCITATION  uc
           ON p."patent_id" = uc."patent_id"
    JOIN   app_dates                    cited
           ON uc."citation_id" = cited."patent_id"
    WHERE  DATEDIFF('day', cited.app_date, p.app_date) BETWEEN 0 AND 365
    GROUP  BY p."patent_id"
),

/* ---------- forward citations ≤1 year AFTER filing (filter) ---------- */
fwd1 AS (
    SELECT  base."patent_id",
            COUNT(*) AS fwd1_cnt
    FROM   app_dates                    base
    JOIN   target_cpc                   tc   ON base."patent_id" = tc."patent_id"
    JOIN   PATENTSVIEW.PATENTSVIEW.USPATENTCITATION  fwd
           ON base."patent_id" = fwd."citation_id"
    JOIN   app_dates                    citing
           ON fwd."patent_id" = citing."patent_id"
    WHERE  DATEDIFF('day', base.app_date, citing.app_date) BETWEEN 0 AND 365
    GROUP  BY base."patent_id"
),

/* ---------- forward citations ≤3 years AFTER filing (to report) ---------- */
fwd3 AS (
    SELECT  base."patent_id",
            COUNT(*) AS fwd3_cnt
    FROM   app_dates                    base
    JOIN   target_cpc                   tc   ON base."patent_id" = tc."patent_id"
    JOIN   PATENTSVIEW.PATENTSVIEW.USPATENTCITATION  fwd
           ON base."patent_id" = fwd."citation_id"
    JOIN   app_dates                    citing
           ON fwd."patent_id" = citing."patent_id"
    WHERE  DATEDIFF('day', base.app_date, citing.app_date) BETWEEN 0 AND 3*365
    GROUP  BY base."patent_id"
)

/* ---------- final result ---------- */
SELECT
    b."patent_id",
    b.back_cnt,
    f3.fwd3_cnt
FROM   back  b
JOIN   fwd1  f1  ON b."patent_id" = f1."patent_id"   -- ensures ≥1 forward ≤1 yr
JOIN   fwd3  f3  ON b."patent_id" = f3."patent_id"
ORDER BY b.back_cnt DESC NULLS LAST
LIMIT 1;