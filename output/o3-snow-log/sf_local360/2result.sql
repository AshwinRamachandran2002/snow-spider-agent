/* ------------------------------------------------------------
   ① 各 session で最初に /detail もしくは /complete に到達した
      タイムスタンプを取得
------------------------------------------------------------ */
WITH first_event AS (
    SELECT
        "session",
        MIN(TO_TIMESTAMP("stamp")) AS "first_detail_or_complete_stamp"
    FROM LOG.LOG.ACTIVITY_LOG
    WHERE LOWER("path") LIKE '%/detail%'      -- クリック
       OR LOWER("path") LIKE '%/complete%'    -- CV
    GROUP BY "session"
),

/* ------------------------------------------------------------
   ② ①より前に発生したイベントで search_type が空でないものを抽出
------------------------------------------------------------ */
pre_events AS (
    SELECT
        a."session",
        a."path",
        a."search_type"
    FROM LOG.LOG.ACTIVITY_LOG a
    JOIN first_event f
      ON a."session" = f."session"
    WHERE TO_TIMESTAMP(a."stamp") < f."first_detail_or_complete_stamp"
      AND a."search_type" <> ''
),

/* ------------------------------------------------------------
   ③ session ごとに ②の件数を集計
------------------------------------------------------------ */
cnt AS (
    SELECT
        "session",
        COUNT(*) AS "pre_event_cnt"
    FROM pre_events
    GROUP BY "session"
),

/* ------------------------------------------------------------
   ④ 最小件数を取得
------------------------------------------------------------ */
min_cnt AS (
    SELECT MIN("pre_event_cnt") AS "min_val" FROM cnt
)

/* ------------------------------------------------------------
   ⑤ 最小件数を持つ session の対象イベントを返す
------------------------------------------------------------ */
SELECT
    p."session",
    p."path",
    p."search_type"
FROM pre_events p
JOIN cnt      c ON p."session" = c."session"
JOIN min_cnt  m ON c."pre_event_cnt" = m."min_val"
ORDER BY
    p."session",
    p."path",
    p."search_type";