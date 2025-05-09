/*  Patents that                                                   *
 *  1) have ≥1 backward citations made ≤1 year BEFORE their         *
 *     own application date,                                        *
 *  2) have ≥1 forward citations made ≤1 year AFTER their           *
 *     application date,                                            *
 *  3) count ALL forward citations made ≤3 years after the          *
 *     application date,                                            *
 *  4) belong to CPC groups G06F or A61B,                           *
 *  5) return the single patent with the greatest number of         *
 *     backward-1-year citations (ties broken arbitrarily).         */
WITH app AS (  -------------------------------- application dates
    SELECT  "patent_id",
            MIN(TRY_TO_DATE("date")) AS "app_date"
    FROM    PATENTSVIEW.PATENTSVIEW."APPLICATION"
    WHERE   TRY_TO_DATE("date") IS NOT NULL
    GROUP BY "patent_id"
),
backward AS ( --------------------------------- ≤1 yr BEFORE
    SELECT  uc."patent_id",
            COUNT(*) AS "backward_1yr"
    FROM    PATENTSVIEW.PATENTSVIEW."USPATENTCITATION" uc
    JOIN    app  foc   ON foc."patent_id" = uc."patent_id"
    JOIN    app  prev  ON prev."patent_id" = uc."citation_id"
    WHERE   prev."app_date" >= DATEADD(year,-1,foc."app_date")
      AND   prev."app_date" <  foc."app_date"
    GROUP BY uc."patent_id"
),
forward1 AS ( --------------------------------- ≤1 yr AFTER
    SELECT  uc."citation_id" AS "patent_id",
            COUNT(*)         AS "forward_1yr"
    FROM    PATENTSVIEW.PATENTSVIEW."USPATENTCITATION" uc
    JOIN    app  foc   ON foc."patent_id" = uc."citation_id"
    JOIN    app  nxt   ON nxt."patent_id" = uc."patent_id"
    WHERE   nxt."app_date" >  foc."app_date"
      AND   nxt."app_date" <= DATEADD(year,1,foc."app_date")
    GROUP BY uc."citation_id"
),
forward3 AS ( --------------------------------- ≤3 yrs AFTER
    SELECT  uc."citation_id" AS "patent_id",
            COUNT(*)         AS "forward_3yr"
    FROM    PATENTSVIEW.PATENTSVIEW."USPATENTCITATION" uc
    JOIN    app  foc   ON foc."patent_id" = uc."citation_id"
    JOIN    app  nxt   ON nxt."patent_id" = uc."patent_id"
    WHERE   nxt."app_date" >  foc."app_date"
      AND   nxt."app_date" <= DATEADD(year,3,foc."app_date")
    GROUP BY uc."citation_id"
),
combo AS ( ------------------------------------- patents meeting 1 & 2
    SELECT  b."patent_id",
            b."backward_1yr",
            f1."forward_1yr",
            f3."forward_3yr"
    FROM    backward  b
    JOIN    forward1 f1 ON f1."patent_id" = b."patent_id"
    JOIN    forward3 f3 ON f3."patent_id" = b."patent_id"
)
SELECT  c."patent_id",
        c."backward_1yr"  AS "backward_citations_1yr_before",
        c."forward_1yr"   AS "forward_citations_1yr_after",
        c."forward_3yr"   AS "forward_citations_3yr_after",
        cp."group_id",
        cp."subgroup_id"
FROM    combo c
JOIN    PATENTSVIEW.PATENTSVIEW."CPC_CURRENT" cp
        ON cp."patent_id" = c."patent_id"
WHERE   cp."group_id" IN ('G06F','A61B')          -- specific CPC groups
QUALIFY ROW_NUMBER() OVER (PARTITION BY c."patent_id"
                           ORDER BY cp."group_id") = 1
ORDER BY c."backward_1yr" DESC NULLS LAST
LIMIT 1;