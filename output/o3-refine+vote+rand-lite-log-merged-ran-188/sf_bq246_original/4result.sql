/* ──────────────────────────────────────────────────────────────────────────
   Patents in CPC group G06F that have:
     • ≥1 backward citation within 1 year before application date,
     • ≥1 forward citation within 1 year after application date,
   and returns the patent with the greatest number of such backward citations,
   plus its forward‑citation count within 3 years after application.
   All date strings are converted with TRY_TO_DATE to skip malformed values. 
   ──────────────────────────────────────────────────────────────────────────*/
WITH
/* ---------- US application dates (first filing) ------------------------- */
"APP_DATES" AS (
    SELECT
        "patent_id",
        MIN("app_date") AS "app_date"
    FROM (
        SELECT
            "patent_id",
            TRY_TO_DATE("date") AS "app_date"
        FROM PATENTSVIEW.PATENTSVIEW.APPLICATION
        WHERE "country" = 'US'
    )
    WHERE "app_date" IS NOT NULL
    GROUP BY "patent_id"
),
/* ---------- CPC category filter ----------------------------------------- */
"CPC_FILTER" AS (
    SELECT DISTINCT
        "patent_id"
    FROM PATENTSVIEW.PATENTSVIEW.CPC_CURRENT
    WHERE "group_id" = 'G06F'            -- target CPC group(s)
),
/* ---------- Clean citation dates ---------------------------------------- */
"CIT" AS (
    SELECT
        "patent_id",
        "citation_id",
        TRY_TO_DATE("date") AS "cit_date"
    FROM PATENTSVIEW.PATENTSVIEW.USPATENTCITATION
    WHERE TRY_TO_DATE("date") IS NOT NULL
),
/* ---------- backward citations: 1 year before filing -------------------- */
"BACKWARD_1YR" AS (
    SELECT
        a."patent_id",
        COUNT(*) AS "back_cnt_1yr"
    FROM "APP_DATES" a
    JOIN "CIT"       c
         ON c."patent_id" = a."patent_id"               -- citing = focal patent
    WHERE c."cit_date"
          BETWEEN DATEADD(year, -1, a."app_date") AND a."app_date"
    GROUP BY a."patent_id"
),
/* ---------- forward citations: within 3 years after filing -------------- */
"FORWARD_3YR" AS (
    SELECT
        a."patent_id",
        COUNT(*) AS "fwd_cnt_3yr"
    FROM "APP_DATES" a
    JOIN "CIT"       c
         ON c."citation_id" = a."patent_id"             -- cited = focal patent
    WHERE c."cit_date"
          BETWEEN a."app_date" AND DATEADD(year, 3, a."app_date")
    GROUP BY a."patent_id"
),
/* ---------- forward citations: at least one within 1 year --------------- */
"FORWARD_1YR_EXIST" AS (
    SELECT
        a."patent_id",
        COUNT(*) AS "fwd_cnt_1yr"
    FROM "APP_DATES" a
    JOIN "CIT"       c
         ON c."citation_id" = a."patent_id"
    WHERE c."cit_date"
          BETWEEN a."app_date" AND DATEADD(year, 1, a."app_date")
    GROUP BY a."patent_id"
)
/* ---------- final selection --------------------------------------------- */
SELECT
    p."id"              AS "patent_id",
    b."back_cnt_1yr",
    f3."fwd_cnt_3yr"
FROM PATENTSVIEW.PATENTSVIEW.PATENT       p
JOIN "APP_DATES"          a  ON a."patent_id" = p."id"
JOIN "CPC_FILTER"         cf ON cf."patent_id" = p."id"
JOIN "BACKWARD_1YR"       b  ON b."patent_id" = p."id"
JOIN "FORWARD_3YR"        f3 ON f3."patent_id" = p."id"
JOIN "FORWARD_1YR_EXIST"  f1 ON f1."patent_id" = p."id"   -- ensures ≥1 fwd within 1 year
ORDER BY
    b."back_cnt_1yr" DESC NULLS LAST,
    p."id"           ASC
LIMIT 1;