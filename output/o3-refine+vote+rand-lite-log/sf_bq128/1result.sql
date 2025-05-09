WITH
/*--------------------------------------------------------------------
1. Patents having U.S. application (filing) dates 2014‑01‑01 – 2014‑02‑01
   and whose CPC technology falls in the requested domains
--------------------------------------------------------------------*/
APP_WINDOW AS (          -- application (filing) date window
    SELECT  "patent_id",
            TRY_TO_DATE("date")  AS APP_DATE
    FROM    PATENTSVIEW.PATENTSVIEW."APPLICATION"
    WHERE   TRY_TO_DATE("date") BETWEEN '2014-01-01' AND '2014-02-01'
          AND TRY_TO_DATE("date") IS NOT NULL
),
CPC_SCOPE AS (           -- chemistry / biology / medical scope
    SELECT DISTINCT "patent_id"
    FROM   PATENTSVIEW.PATENTSVIEW."CPC_CURRENT"
    WHERE  ("subsection_id" BETWEEN 'C05' AND 'C13')
        OR ("group_id" IN ('A01G','A01H','A61K','A61P','A61Q',
                           'B01F','B01J','B81B','B82B','B82Y',
                           'G01N','G16H'))
),
BASE_PATENTS AS (        -- patents of interest with bibliographic info
    SELECT  p."id"             AS PATENT_ID,
            p."title"          AS TITLE,
            p."abstract"       AS ABSTRACT,
            TRY_TO_DATE(p."date") AS PUB_DATE
    FROM    PATENTSVIEW.PATENTSVIEW."PATENT"  p
            JOIN APP_WINDOW  aw ON aw."patent_id" = p."id"
            JOIN CPC_SCOPE   cs ON cs."patent_id" = p."id"
    WHERE   p."country" = 'US'
      AND   TRY_TO_DATE(p."date") IS NOT NULL
),
/*--------------------------------------------------------------------
2. Backward citations = patents cited by the focal patent
   (cited patent publication date earlier than focal filing date)
--------------------------------------------------------------------*/
BACKWARD_CT AS (
    SELECT  uc."patent_id"   AS PATENT_ID,      -- focal patent
            COUNT(*)         AS BACK_CNT
    FROM    PATENTSVIEW.PATENTSVIEW."USPATENTCITATION" uc
            JOIN APP_WINDOW aw
                 ON aw."patent_id" = uc."patent_id"
    WHERE   TRY_TO_DATE(uc."date") IS NOT NULL
      AND   TRY_TO_DATE(uc."date") < aw.APP_DATE
    GROUP BY uc."patent_id"
),
/*--------------------------------------------------------------------
3. Forward citations within 5 years = later patents that cite the focal
   patent no later than 5 years after the focal publication date
--------------------------------------------------------------------*/
FORWARD_CT AS (
    SELECT  uc."citation_id" AS PATENT_ID,      -- focal patent
            COUNT(*)         AS FWD_CNT
    FROM    PATENTSVIEW.PATENTSVIEW."USPATENTCITATION" uc
            JOIN PATENTSVIEW.PATENTSVIEW."PATENT" p_citing
                 ON p_citing."id" = uc."patent_id"           -- citing patent
            JOIN BASE_PATENTS bp
                 ON bp.PATENT_ID = uc."citation_id"          -- focal patent
    WHERE   TRY_TO_DATE(p_citing."date") IS NOT NULL
      AND   TRY_TO_DATE(p_citing."date") 
            <= DATEADD(year, 5, bp.PUB_DATE)                 -- ≤ 5‑year window
    GROUP BY uc."citation_id"
)
/*--------------------------------------------------------------------
4. Final report
--------------------------------------------------------------------*/
SELECT  bp.PATENT_ID,
        bp.TITLE,
        bp.ABSTRACT,
        bp.PUB_DATE                               AS PUBLICATION_DATE,
        COALESCE(bc.BACK_CNT, 0)                  AS BACKWARD_CITATION_COUNT,
        COALESCE(fc.FWD_CNT, 0)                   AS FORWARD_CITATION_COUNT_5YR
FROM    BASE_PATENTS  bp
        LEFT JOIN BACKWARD_CT bc ON bc.PATENT_ID = bp.PATENT_ID
        LEFT JOIN FORWARD_CT  fc ON fc.PATENT_ID = bp.PATENT_ID
ORDER BY bp.PATENT_ID;