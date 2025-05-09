WITH
/* 1.  Patents that belong to the chosen CPC subsection (“C08”) */
cpc_sel AS (
    SELECT DISTINCT "patent_id"
    FROM PATENTSVIEW.PATENTSVIEW.CPC_CURRENT
    WHERE "subsection_id" = 'C08'
),

/* 2.  Earliest application date for every patent */
app AS (
    SELECT "patent_id",
           MIN(TRY_TO_DATE("date")) AS "app_date"
    FROM   PATENTSVIEW.PATENTSVIEW.APPLICATION
    GROUP BY "patent_id"
),

/* 3.  Back‑citations within 1‑year before the application date */
back AS (
    SELECT bc."patent_id",
           COUNT(*) AS "back_1yr"
    FROM   PATENTSVIEW.PATENTSVIEW.USPATENTCITATION bc
    JOIN   app  curr  ON bc."patent_id"   = curr."patent_id"
    JOIN   app  cited ON bc."citation_id" = cited."patent_id"
    WHERE  curr."app_date"  IS NOT NULL
      AND  cited."app_date" IS NOT NULL
      AND  DATEDIFF('day', cited."app_date", curr."app_date") BETWEEN 0 AND 365
    GROUP BY bc."patent_id"
),

/* 4.  Forward‑citations within 1‑year and 3‑years after application */
fwd AS (
    SELECT fc."citation_id" AS "patent_id",
           /* within first year */
           SUM(
               CASE
                   WHEN citing."app_date" IS NOT NULL
                    AND curr."app_date"  IS NOT NULL
                    AND DATEDIFF('day', curr."app_date", citing."app_date") BETWEEN 0 AND 365
                   THEN 1 ELSE 0
               END
           ) AS "fwd_1yr",
           /* within first 3 years */
           SUM(
               CASE
                   WHEN citing."app_date" IS NOT NULL
                    AND curr."app_date"  IS NOT NULL
                    AND DATEDIFF('day', curr."app_date", citing."app_date") BETWEEN 0 AND 1095
                   THEN 1 ELSE 0
               END
           ) AS "fwd_3yr"
    FROM   PATENTSVIEW.PATENTSVIEW.USPATENTCITATION fc
    JOIN   app curr   ON fc."citation_id" = curr."patent_id"
    JOIN   app citing ON fc."patent_id"   = citing."patent_id"
    GROUP BY fc."citation_id"
),

/* 5.  Patents meeting both backward & forward conditions */
qualified AS (
    SELECT b."patent_id",
           b."back_1yr",
           f."fwd_1yr",
           f."fwd_3yr"
    FROM back b
    JOIN fwd  f ON b."patent_id" = f."patent_id"
    WHERE b."back_1yr" > 0      -- ≥1 back citation in 1 year
      AND f."fwd_1yr"  > 0      -- ≥1 forward citation in 1 year
),

/* 6.  Add CPC info and application date (restricted to subsection C08) */
details AS (
    SELECT q."patent_id",
           q."back_1yr",
           q."fwd_1yr",
           q."fwd_3yr",
           a."app_date",
           LISTAGG(DISTINCT c."group_id", ';')
             WITHIN GROUP (ORDER BY c."group_id") AS "cpc_category"
    FROM   qualified q
    JOIN   app a  ON q."patent_id" = a."patent_id"
    JOIN   PATENTSVIEW.PATENTSVIEW.CPC_CURRENT c
           ON q."patent_id" = c."patent_id"
    WHERE  c."subsection_id" = 'C08'
    GROUP BY q."patent_id", q."back_1yr", q."fwd_1yr", q."fwd_3yr", a."app_date"
)

/* 7.  Final result – top patent by backward citations */
SELECT p."number"                               AS patent_number,
       TO_CHAR(d."app_date", 'YYYY-MM-DD')      AS application_date,
       d."cpc_category"                         AS cpc_category,
       d."back_1yr"                             AS backward_citations_within_1yr,
       d."fwd_1yr"                              AS forward_citations_within_1yr,
       d."fwd_3yr"                              AS forward_citations_within_3yrs
FROM   details d
JOIN   PATENTSVIEW.PATENTSVIEW.PATENT p
       ON d."patent_id" = p."id"
WHERE  p."country" = 'US'            -- keep only U.S. patents
ORDER  BY d."back_1yr" DESC NULLS LAST, p."number"
LIMIT 1;