WITH first_conversion AS (
    /* 1) first “/detail” click or “/complete” conversion for every session */
    SELECT
        session,
        MIN(stamp) AS conv_stamp            -- first time either of the 2 paths appears
    FROM activity_log
    WHERE path LIKE '%/detail%' OR path LIKE '%/complete%'
    GROUP BY session
),
pre_event_counts AS (
    /* 2) how many events (with non‑empty search_type) occurred *before* that moment */
    SELECT
        fc.session,
        COUNT(*) AS pre_cnt
    FROM first_conversion fc
    JOIN activity_log al
           ON al.session = fc.session
          AND al.stamp   < fc.conv_stamp          -- only “before” events
          AND al.search_type IS NOT NULL
          AND al.search_type <> ''                -- non‑empty search_type only
    GROUP BY fc.session
),
min_cnt AS (
    /* 3) the minimum of such counts across all sessions */
    SELECT MIN(pre_cnt) AS min_pre_cnt
    FROM pre_event_counts
),
first_conv_info AS (
    /* 4) get the record that is the first “/detail” or “/complete” for each session */
    SELECT
        al.session,
        al.path,
        al.search_type
    FROM activity_log al
    JOIN first_conversion fc
         ON al.session = fc.session
        AND al.stamp   = fc.conv_stamp
)
SELECT
    pec.session,
    fci.path,
    fci.search_type
FROM pre_event_counts  pec
JOIN min_cnt           mc  ON pec.pre_cnt = mc.min_pre_cnt   -- only sessions with minimum
JOIN first_conv_info   fci ON pec.session = fci.session
ORDER BY pec.session;