WITH best_per_interest AS (
    /* 1.  For every interest_id keep the record(s) with the
           highest composition value.  If the same max value
           occurs more than once, keep the earliest month/year */
    SELECT
        im."interest_id",
        im."month_year"      AS time,
        im."composition",
        ROW_NUMBER() OVER (PARTITION BY im."interest_id"
                           ORDER BY im."composition" DESC,
                                    im."_year"      ASC,
                                    im."_month"     ASC) AS rn
    FROM interest_metrics AS im
),
max_composition AS (
    /* 2.  Retain only the single row (rn = 1) for each interest */
    SELECT
        bp."interest_id",
        bp.time,
        bp."composition"
    FROM best_per_interest AS bp
    WHERE bp.rn = 1
),
with_names AS (
    /* 3.  Attach the human‑readable interest name */
    SELECT
        mc.time,
        imap."interest_name",
        mc."composition"
    FROM max_composition AS mc
    JOIN interest_map AS imap
      ON imap."id" = mc."interest_id"
),
ranked AS (
    /* 4.  Rank all interests by their max‑composition, both
           highest‑to‑lowest and lowest‑to‑highest */
    SELECT
        wn.*,
        ROW_NUMBER() OVER (ORDER BY wn."composition" DESC,
                                   wn."interest_name") AS desc_rank,
        ROW_NUMBER() OVER (ORDER BY wn."composition" ASC,
                                   wn."interest_name") AS asc_rank
    FROM with_names AS wn
),
top10 AS (
    SELECT time, interest_name, composition
    FROM ranked
    WHERE desc_rank <= 10          -- highest 10
),
bottom10 AS (
    SELECT time, interest_name, composition
    FROM ranked
    WHERE asc_rank  <= 10          -- lowest 10
)
/* 5.  Return the requested information */
SELECT *
FROM (
      SELECT 'Top'    AS category, time, interest_name, composition FROM top10
      UNION ALL
      SELECT 'Bottom' AS category, time, interest_name, composition FROM bottom10
)
ORDER BY category DESC,        -- 'Top' rows first, then 'Bottom'
         composition DESC;     -- within each section, best ordering