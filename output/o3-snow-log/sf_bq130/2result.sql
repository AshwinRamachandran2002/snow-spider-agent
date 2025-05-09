/* ----------------------------------------------------------
   1)  Daily Top-5 states by new-case increases
       (1 Mar 2020 – 31 May 2020) and how often each state
       appears in those daily Top-5 lists.
   2)  Identify the state that ranks 4-th in that count and
       show its five counties that most frequently appear in
       the DAILY Top-5 list for counties in the same period.
   ----------------------------------------------------------*/
WITH state_calc AS (          -- daily new cases per STATE
    SELECT  "date",
            "state_name",
            "confirmed_cases"
          - LAG("confirmed_cases") 
              OVER (PARTITION BY "state_name"
                    ORDER BY "date")                    AS new_cases
    FROM    COVID19_NYT.COVID19_NYT.US_STATES
    WHERE   "date" BETWEEN '2020-03-01' AND '2020-05-31'
),
state_daily_top5 AS (         -- keep the Top-5 states each day
    SELECT  "date",
            "state_name"
    FROM    state_calc
    WHERE   new_cases IS NOT NULL
      AND   new_cases > 0
    QUALIFY ROW_NUMBER() OVER (PARTITION BY "date"
                               ORDER BY new_cases DESC NULLS LAST) <= 5
),
state_ranking AS (            -- how often each state is in the daily Top-5
    SELECT  "state_name",
            COUNT(*) AS top5_hits
    FROM    state_daily_top5
    GROUP BY "state_name"
),
fourth_state AS (             -- the state that ranks 4-th overall
    SELECT  "state_name"
    FROM   ( SELECT "state_name",
                    top5_hits,
                    ROW_NUMBER() OVER (ORDER BY top5_hits DESC NULLS LAST) AS rn
             FROM   state_ranking )
    WHERE   rn = 4
),
/* ---------- County-level work, only for the 4-th ranked state ---------- */
county_calc AS (              -- daily new cases per COUNTY (target state)
    SELECT  c."date",
            c."state_name",
            c."county",
            c."county_fips_code",
            c."confirmed_cases"
          - LAG(c."confirmed_cases")
              OVER (PARTITION BY c."county_fips_code"
                    ORDER BY c."date")                  AS new_cases
    FROM    COVID19_NYT.COVID19_NYT.US_COUNTIES   c
    JOIN    fourth_state                          fs
           ON c."state_name" = fs."state_name"
    WHERE   c."date" BETWEEN '2020-03-01' AND '2020-05-31'
),
county_daily_top5 AS (        -- Top-5 counties (within that state) each day
    SELECT  "date",
            "county"
    FROM    county_calc
    WHERE   new_cases IS NOT NULL
      AND   new_cases > 0
    QUALIFY ROW_NUMBER() OVER (PARTITION BY "date"
                               ORDER BY new_cases DESC NULLS LAST) <= 5
),
county_ranking AS (           -- how often each county is in the daily Top-5
    SELECT  "county",
            COUNT(*) AS top5_hits
    FROM    county_daily_top5
    GROUP BY "county"
    ORDER BY top5_hits DESC NULLS LAST
    LIMIT   5                -- five most-frequent counties
)

/* ------------------- Final combined output ------------------- */
SELECT  'STATE_RANKING' AS section,
        r."state_name"  AS state_name,
        NULL            AS county,
        r.top5_hits     AS appearances
FROM    state_ranking r

UNION ALL

SELECT  'TOP_COUNTIES_OF_4TH_STATE' AS section,
        fs."state_name"             AS state_name,
        cr."county"                 AS county,
        cr.top5_hits                AS appearances
FROM    fourth_state   fs
CROSS JOIN county_ranking cr

ORDER BY section, appearances DESC NULLS LAST;