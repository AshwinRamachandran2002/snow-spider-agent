/*  Return the U.S. patent (limited to CPC groups G06F or H04L) that
    has the highest number of backward citations made to patents whose
    application dates fall within the 1‑year window before its own
    application date, while also having at least one forward citation
    within 1 year and counting forward citations within 3 years.       */

WITH app_dates AS (                /* valid application dates only         */
    SELECT  "patent_id",
            TRY_TO_DATE("date") AS "app_date"   -- ignore malformed dates
    FROM    PATENTSVIEW.PATENTSVIEW."APPLICATION"
    WHERE   TRY_TO_DATE("date") IS NOT NULL
),
us_patents AS (                    /* U.S. patents                         */
    SELECT  "id" AS "patent_id"
    FROM    PATENTSVIEW.PATENTSVIEW."PATENT"
    WHERE   "country" = 'US'
),
cpc_focus AS (                     /* patents in the chosen CPC groups     */
    SELECT DISTINCT "patent_id"
    FROM   PATENTSVIEW.PATENTSVIEW."CPC_CURRENT"
    WHERE  "group_id" IN ('G06F', 'H04L')       -- adjust list if desired
),
focal AS (                         /* focal patents meeting all 3 filters  */
    SELECT  p."patent_id",
            a."app_date"
    FROM    us_patents p
    JOIN    cpc_focus  c ON c."patent_id" = p."patent_id"
    JOIN    app_dates  a ON a."patent_id" = p."patent_id"
),

/* -------- backward citations: cited app‑date within 1 year before focal --*/
backward AS (
    SELECT  f."patent_id",
            COUNT(DISTINCT bc."citation_id") AS "back_cnt"
    FROM    focal f
    JOIN    PATENTSVIEW.PATENTSVIEW."USPATENTCITATION" bc
           ON bc."patent_id" = f."patent_id"              -- focal cites
    JOIN    app_dates cited
           ON cited."patent_id" = bc."citation_id"
    WHERE   cited."app_date"
            BETWEEN DATEADD(year, -1, f."app_date") AND f."app_date"
    GROUP BY f."patent_id"
),

/* -------- forward citations: citing app‑date within 1 yr / 3 yrs ---------*/
forward AS (
    SELECT  f."patent_id",
            COUNT(DISTINCT CASE
                   WHEN ca."app_date" <= DATEADD(year, 1, f."app_date")
                   THEN fc."patent_id" END) AS "fwd_1yr",
            COUNT(DISTINCT CASE
                   WHEN ca."app_date" <= DATEADD(year, 3, f."app_date")
                   THEN fc."patent_id" END) AS "fwd_3yr"
    FROM    focal f
    JOIN    PATENTSVIEW.PATENTSVIEW."USPATENTCITATION" fc
           ON fc."citation_id" = f."patent_id"            -- focal is cited
    JOIN    app_dates ca
           ON ca."patent_id" = fc."patent_id"             -- citing patent date
    WHERE   ca."app_date" >= f."app_date"                 -- must be later
    GROUP BY f."patent_id"
),

/* -------- combine filters & pick winner ----------------------------------*/
combined AS (
    SELECT  f."patent_id",
            b."back_cnt",
            fw."fwd_1yr",
            fw."fwd_3yr"
    FROM    focal    f
    JOIN    backward b  ON b."patent_id" = f."patent_id"
    JOIN    forward  fw ON fw."patent_id" = f."patent_id"
    WHERE   b."back_cnt" > 0
      AND   fw."fwd_1yr" > 0
)

SELECT  "patent_id",
        "back_cnt" AS "backward_citations_within_1yr_before_app",
        "fwd_3yr"  AS "forward_citations_within_3yr_after_app"
FROM    combined
ORDER BY "back_cnt" DESC NULLS LAST, "patent_id"
LIMIT 1;