/*--------------------------------------------------------------
  Patents in CPC group “G06F%” that
    • have at least one backward-citation whose application date
      occurs ≤ 1 year before their own application date,
    • have at least one forward-citation received ≤ 1 year after
      their own application date,
    • and for the survivor set report the total number of
      forward-citations received within 3 years.
  Return the single patent with the greatest number of qualifying
  backward citations.
----------------------------------------------------------------*/
WITH app AS (        -- clean application dates
    SELECT
        "patent_id",
        TRY_TO_DATE("date") AS "app_date"
    FROM PATENTSVIEW.PATENTSVIEW.APPLICATION
    WHERE TRY_TO_DATE("date") IS NOT NULL
),

/* ----------  backward citations ≤ 1-year window  ---------- */
backward AS (
    SELECT
        c."patent_id",
        COUNT(*) AS "back_cnt"
    FROM PATENTSVIEW.PATENTSVIEW.USPATENTCITATION c
    JOIN app citing ON citing."patent_id"  = c."patent_id"     -- the patent doing the citing
    JOIN app cited  ON cited."patent_id"   = c."citation_id"   -- the patent being cited
    WHERE DATEDIFF('day', cited."app_date", citing."app_date") BETWEEN 0 AND 365
    GROUP BY c."patent_id"
),

/* ----------  forward citations ≤ 1-year window (filter)  ---------- */
forward_1yr AS (
    SELECT
        c."citation_id"            AS "patent_id",
        COUNT(*)                   AS "fwd_cnt_1yr"
    FROM PATENTSVIEW.PATENTSVIEW.USPATENTCITATION c
    JOIN app cited  ON cited."patent_id"  = c."citation_id"    -- the focal patent
    JOIN app citing ON citing."patent_id" = c."patent_id"      -- the later patent that cites it
    WHERE DATEDIFF('day', cited."app_date", citing."app_date") BETWEEN 0 AND 365
    GROUP BY c."citation_id"
),

/* ----------  forward citations ≤ 3-year window (report) ---------- */
forward_3yr AS (
    SELECT
        c."citation_id"            AS "patent_id",
        COUNT(*)                   AS "fwd_cnt_3yr"
    FROM PATENTSVIEW.PATENTSVIEW.USPATENTCITATION c
    JOIN app cited  ON cited."patent_id"  = c."citation_id"
    JOIN app citing ON citing."patent_id" = c."patent_id"
    WHERE DATEDIFF('day', cited."app_date", citing."app_date") BETWEEN 0 AND 365*3
    GROUP BY c."citation_id"
)

/* ----------  final selection & ranking  ---------- */
SELECT
    b."patent_id",
    b."back_cnt",
    f1."fwd_cnt_1yr",
    f3."fwd_cnt_3yr"
FROM backward      b
JOIN forward_1yr   f1  ON f1."patent_id" = b."patent_id"
JOIN forward_3yr   f3  ON f3."patent_id" = b."patent_id"
JOIN PATENTSVIEW.PATENTSVIEW.CPC_CURRENT cp
     ON cp."patent_id" = b."patent_id"
WHERE cp."group_id" ILIKE 'G06F%'          --  << adjust CPC filter as desired
ORDER BY b."back_cnt" DESC NULLS LAST
LIMIT 1;