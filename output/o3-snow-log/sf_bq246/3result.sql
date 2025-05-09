/* ---------------------------------------------------------------
   Retrieve the patent (within CPC groups starting “G06”)
   that has (i) ≥1 backward citation made within 1-year before its
   filing date and (ii) ≥1 forward citation received within
   1-year after its filing date, then pick the one with the most
   total backward citations.  All date parsing uses TRY_TO_DATE to
   skip records that contain malformed dates such as ‘1968-05-00’.
---------------------------------------------------------------- */
WITH app_dates AS (   -- 1. valid U.S. filing dates
    SELECT  "patent_id"                                         AS id,
            TRY_TO_DATE("date",'YYYY-MM-DD')                   AS app_date
    FROM    PATENTSVIEW.PATENTSVIEW."APPLICATION"
    WHERE   "country" = 'US'
      AND   TRY_TO_DATE("date",'YYYY-MM-DD') IS NOT NULL
),

cpc_focus AS (        -- 2. patents in the target CPC scope
    SELECT DISTINCT "patent_id"
    FROM   PATENTSVIEW.PATENTSVIEW."CPC_CURRENT"
    WHERE  "group_id" ILIKE 'G06%'                -- adjust as needed
),

backward AS (         -- 3. backward citation statistics
    SELECT  uc."patent_id"                                        AS patent_id,
            COUNT(DISTINCT uc."citation_id")                      AS bwd_total,
            COUNT(DISTINCT CASE
                             WHEN bc_app.app_date BETWEEN
                                  DATEADD(year,-1 , cur_app.app_date)
                                  AND DATEADD(day , -1 , cur_app.app_date)
                             THEN uc."citation_id"
                           END)                                   AS bwd_1yr_cnt
    FROM   PATENTSVIEW.PATENTSVIEW."USPATENTCITATION"   uc
    JOIN   app_dates  cur_app ON cur_app.id = uc."patent_id"
    JOIN   app_dates  bc_app  ON bc_app.id  = uc."citation_id"
    GROUP  BY uc."patent_id"
),

forward AS (          -- 4. forward citation statistics (≤3 yrs, flag ≤1 yr)
    SELECT  uc."citation_id"                                       AS patent_id,
            COUNT(DISTINCT uc."patent_id")                         AS fwd_3yr_cnt,
            COUNT(DISTINCT CASE
                             WHEN fwd_app.app_date BETWEEN
                                  DATEADD(day , 1 , cur_app.app_date)
                                  AND DATEADD(year,1 , cur_app.app_date)
                             THEN uc."patent_id"
                           END)                                     AS fwd_1yr_cnt
    FROM   PATENTSVIEW.PATENTSVIEW."USPATENTCITATION"   uc
    JOIN   app_dates  cur_app ON cur_app.id = uc."citation_id"
    JOIN   app_dates  fwd_app ON fwd_app.id = uc."patent_id"
    WHERE  fwd_app.app_date > cur_app.app_date
      AND  fwd_app.app_date <= DATEADD(year,3, cur_app.app_date)
    GROUP  BY uc."citation_id"
),

eligible_patents AS ( -- 5. patents satisfying both window conditions
    SELECT  cf."patent_id",
            b.bwd_total,
            f.fwd_3yr_cnt
    FROM    cpc_focus  cf
    LEFT JOIN backward b ON b.patent_id = cf."patent_id"
    LEFT JOIN forward  f ON f.patent_id = cf."patent_id"
    WHERE   b.bwd_1yr_cnt > 0
      AND   f.fwd_1yr_cnt > 0
)

-- 6. final result: patent with the most backward citations
SELECT   "patent_id",
         bwd_total            AS "backward_citation_count",
         fwd_3yr_cnt          AS "forward_citation_count_3yrs"
FROM     eligible_patents
ORDER BY bwd_total DESC NULLS LAST
LIMIT    1;