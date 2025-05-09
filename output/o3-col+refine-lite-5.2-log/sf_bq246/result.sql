/*  Patents in CPC group G06F that                             
    ▸ have at least one backward citation within 1 yr before their application date  
    ▸ have at least one forward citation within 1 yr after their application date  
    ▸ return the total number of forward citations that fall within 3 yrs after the application date  
    The patent with the greatest number of backward‑within‑1‑year citations is shown.                */
WITH
/* ---------- backward citations within 1 year BEFORE application ---------- */
bwd AS (
    SELECT
        app."patent_id",
        COUNT(*) AS "backward_1yr"
    FROM PATENTSVIEW.PATENTSVIEW."APPLICATION"            app
    JOIN PATENTSVIEW.PATENTSVIEW."USPATENTCITATION"       cit
          ON cit."patent_id" = app."patent_id"            -- current patent cites “prev”
    JOIN PATENTSVIEW.PATENTSVIEW."APPLICATION"            prev
          ON prev."patent_id" = cit."citation_id"
    WHERE TRY_TO_DATE(app."date")  IS NOT NULL
      AND TRY_TO_DATE(prev."date") IS NOT NULL
      AND DATEDIFF(
              'day',
              TRY_TO_DATE(prev."date"),
              TRY_TO_DATE(app."date")
          ) BETWEEN 0 AND 365
    GROUP BY app."patent_id"
),
/* ---------- forward citations within 1 year AFTER application (filter) --- */
fwd1 AS (
    SELECT
        base."patent_id",
        COUNT(*) AS "forward_1yr"
    FROM PATENTSVIEW.PATENTSVIEW."APPLICATION"            base
    JOIN PATENTSVIEW.PATENTSVIEW."USPATENTCITATION"       f
          ON f."citation_id" = base."patent_id"           -- “child” cites base
    JOIN PATENTSVIEW.PATENTSVIEW."APPLICATION"            child
          ON child."patent_id" = f."patent_id"
    WHERE TRY_TO_DATE(base."date")  IS NOT NULL
      AND TRY_TO_DATE(child."date") IS NOT NULL
      AND DATEDIFF(
              'day',
              TRY_TO_DATE(base."date"),
              TRY_TO_DATE(child."date")
          ) BETWEEN 0 AND 365
    GROUP BY base."patent_id"
),
/* ---------- forward citations within 3 years AFTER application ----------- */
fwd3 AS (
    SELECT
        base."patent_id",
        COUNT(*) AS "forward_3yr"
    FROM PATENTSVIEW.PATENTSVIEW."APPLICATION"            base
    JOIN PATENTSVIEW.PATENTSVIEW."USPATENTCITATION"       f
          ON f."citation_id" = base."patent_id"
    JOIN PATENTSVIEW.PATENTSVIEW."APPLICATION"            child
          ON child."patent_id" = f."patent_id"
    WHERE TRY_TO_DATE(base."date")  IS NOT NULL
      AND TRY_TO_DATE(child."date") IS NOT NULL
      AND DATEDIFF(
              'day',
              TRY_TO_DATE(base."date"),
              TRY_TO_DATE(child."date")
          ) BETWEEN 0 AND 1095        -- 3 years
    GROUP BY base."patent_id"
)
/* ----------------------- assemble final set ------------------------------ */
SELECT
    b."patent_id",
    b."backward_1yr",
    f3."forward_3yr"
FROM bwd        b
JOIN fwd1       f1  ON f1."patent_id" = b."patent_id"
JOIN fwd3       f3  ON f3."patent_id" = b."patent_id"
JOIN PATENTSVIEW.PATENTSVIEW."CPC_CURRENT"  cpc
     ON cpc."patent_id" = b."patent_id"
WHERE cpc."group_id" = 'G06F'   -- specific CPC technology group
ORDER BY b."backward_1yr" DESC NULLS LAST,
         b."patent_id"
LIMIT 1;