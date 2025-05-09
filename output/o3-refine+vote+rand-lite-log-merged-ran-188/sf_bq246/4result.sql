/*  ------------------------------------------------------------
    Top U.S. patent (single result) that
      • belongs to CPC group(s) beginning with “G06F”
      • has ≥1 backward citation made exactly 1 year BEFORE its
        application year
      • has ≥1 forward citation received exactly 1 year AFTER its
        application year
    The output shows that patent together with
      – number of qualifying backward citations
      – number of forward citations received within 3 years AFTER
        the application year
      – basic bibliographic data
------------------------------------------------------------- */
WITH application_years AS (      -- 1)  application year for every patent
    SELECT
        "patent_id",
        TO_NUMBER(SUBSTR("date",1,4))        AS "app_year",
        "date"                               AS "application_date"
    FROM PATENTSVIEW.PATENTSVIEW."APPLICATION"
),

back_cte AS (                    -- 2)  backward-citation count (-1 year)
    SELECT
        c."patent_id",
        COUNT(*)                   AS "bwd_cnt"
    FROM PATENTSVIEW.PATENTSVIEW."USPATENTCITATION" c
    JOIN application_years a
          ON c."patent_id" = a."patent_id"
    WHERE a."app_year" - TO_NUMBER(SUBSTR(c."date",1,4)) = 1
    GROUP BY c."patent_id"
),

fwd1_cte AS (                    -- 3)  forward citations exactly +1 year
    SELECT
        c."citation_id"           AS "patent_id",
        COUNT(*)                  AS "fwd_cnt_1yr"
    FROM PATENTSVIEW.PATENTSVIEW."USPATENTCITATION" c
    JOIN application_years a
          ON c."citation_id" = a."patent_id"
    WHERE TO_NUMBER(SUBSTR(c."date",1,4)) - a."app_year" = 1
    GROUP BY c."citation_id"
),

fwd3_cte AS (                    -- 4)  forward citations within +0…+3 yrs
    SELECT
        c."citation_id"           AS "patent_id",
        COUNT(*)                  AS "fwd_cnt_3yr"
    FROM PATENTSVIEW.PATENTSVIEW."USPATENTCITATION" c
    JOIN application_years a
          ON c."citation_id" = a."patent_id"
    WHERE TO_NUMBER(SUBSTR(c."date",1,4)) - a."app_year" BETWEEN 0 AND 3
    GROUP BY c."citation_id"
),

eligible AS (                    -- 5)  patents meeting BOTH timing rules
    SELECT
        b."patent_id",
        b."bwd_cnt",
        f3."fwd_cnt_3yr"
    FROM back_cte  b
    JOIN fwd1_cte f1  ON b."patent_id" = f1."patent_id"
    JOIN fwd3_cte f3  ON b."patent_id" = f3."patent_id"
)

SELECT
    e."patent_id",
    e."bwd_cnt",
    e."fwd_cnt_3yr"      AS "fwd_cnt_within_3yr",
    p."title",
    p."date"             AS "grant_date",
    a."application_date"
FROM eligible                               e
JOIN PATENTSVIEW.PATENTSVIEW."CPC_CURRENT"  cc
      ON e."patent_id" = cc."patent_id"
JOIN PATENTSVIEW.PATENTSVIEW."PATENT"       p
      ON e."patent_id" = p."id"
JOIN application_years                      a
      ON e."patent_id" = a."patent_id"
WHERE cc."group_id" ILIKE 'G06F%'           -- specific CPC category
ORDER BY e."bwd_cnt" DESC NULLS LAST,
         e."patent_id" ASC
LIMIT 1;