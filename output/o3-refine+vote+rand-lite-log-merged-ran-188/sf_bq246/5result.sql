/*  Patents in CPC subsection ‘G06’ that
    – have at least one backward citation made ≤ 1 year BEFORE their application date
    – have at least one forward citation received ≤ 1 year AFTER their application date
    – report the total number of forward citations received in the first 3 years
    Return the single patent with the greatest count of 1-year-backward citations           */

WITH app AS (                                             -- clean application dates
    SELECT  "patent_id",
            TRY_TO_DATE("date")      AS "app_date"
    FROM    PATENTSVIEW.PATENTSVIEW."APPLICATION"
    WHERE   TRY_TO_DATE("date") IS NOT NULL
),

/* -------- backward citations ≤ 1 year BEFORE filing ------------------------ */
backward AS (
    SELECT  c."patent_id",
            COUNT(*)                 AS "backward_1yr"
    FROM    PATENTSVIEW.PATENTSVIEW."USPATENTCITATION"  c
    JOIN    app  citing   ON c."patent_id"  = citing."patent_id"
    JOIN    app  cited    ON c."citation_id" = cited."patent_id"
    WHERE   DATEDIFF('day', cited."app_date", citing."app_date") BETWEEN 0 AND 365
    GROUP BY c."patent_id"
),

/* -------- forward citations within 3 years of filing ----------------------- */
forward_3 AS (
    SELECT  c."citation_id"          AS "patent_id",
            COUNT(*)                 AS "forward_3yr"
    FROM    PATENTSVIEW.PATENTSVIEW."USPATENTCITATION"  c
    JOIN    app  original ON c."citation_id" = original."patent_id"
    JOIN    app  citing   ON c."patent_id"   = citing."patent_id"
    WHERE   DATEDIFF('day', original."app_date", citing."app_date") BETWEEN 0 AND 365*3
    GROUP BY c."citation_id"
),

/* -------- forward citations within 1 year of filing (filter condition) ----- */
forward_1 AS (
    SELECT  c."citation_id"          AS "patent_id",
            COUNT(*)                 AS "forward_1yr"
    FROM    PATENTSVIEW.PATENTSVIEW."USPATENTCITATION"  c
    JOIN    app  original ON c."citation_id" = original."patent_id"
    JOIN    app  citing   ON c."patent_id"   = citing."patent_id"
    WHERE   DATEDIFF('day', original."app_date", citing."app_date") BETWEEN 0 AND 365
    GROUP BY c."citation_id"
),

/* -------- put the three pieces together ----------------------------------- */
combo AS (
    SELECT  b."patent_id",
            b."backward_1yr",
            f3."forward_3yr"
    FROM    backward   b
    JOIN    forward_3  f3  ON b."patent_id" = f3."patent_id"
    JOIN    forward_1  f1  ON b."patent_id" = f1."patent_id"   -- ensures ≥1 fwd ≤1 yr
)

/* -------- focus on desired CPC category & pick the top result -------------- */
SELECT  c."patent_id",
        c."backward_1yr",
        c."forward_3yr"
FROM    combo                          c
JOIN    PATENTSVIEW.PATENTSVIEW."CPC_CURRENT"  cc
          ON c."patent_id" = cc."patent_id"
WHERE   cc."subsection_id" = 'G06'              -- <-- specify CPC category here
ORDER BY c."backward_1yr" DESC NULLS LAST
LIMIT 1;