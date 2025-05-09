/* ---------------------------------------------------------------
   STEP-BY-STEP  CTEs
   ---------------------------------------------------------------
   1) state_daily     – daily NEW-case counts for every state
   2) state_top5      – five states with largest NEW-case jumps per day
   3) state_rank      – how often each state appears in a daily top-five
   4) fourth_state    – the state that ranks 4th overall
   5) county_daily    – daily NEW-case counts for every county *in* that state
   6) county_top5     – five counties with largest NEW-case jumps per day
   7) county_rank     – how often each county appears in a daily top-five
   ---------------------------------------------------------------
   FINAL SELECT       – returns one result-set that first lists the
                        full state ranking, followed by the top five
                        counties for the 4th-ranked state
------------------------------------------------------------------*/
WITH state_daily AS (         -- 1
    SELECT  "date",
            "state_name",
            "confirmed_cases"
              - LAG("confirmed_cases")
                OVER (PARTITION BY "state_name" ORDER BY "date") AS "new_cases"
    FROM COVID19_NYT.COVID19_NYT.US_STATES
    WHERE "date" BETWEEN '2020-03-01' AND '2020-05-31'
),
state_top5 AS (               -- 2
    SELECT  "date",
            "state_name",
            ROW_NUMBER() OVER (PARTITION BY "date"
                               ORDER BY "new_cases" DESC NULLS LAST) AS rn
    FROM state_daily
),
state_rank AS (               -- 3
    SELECT  "state_name",
            COUNT(*)                                       AS top5_hits,
            DENSE_RANK() OVER (ORDER BY COUNT(*) DESC)     AS state_overall_rank
    FROM state_top5
    WHERE rn <= 5
    GROUP BY "state_name"
),
fourth_state AS (             -- 4
    SELECT "state_name"
    FROM   state_rank
    WHERE  state_overall_rank = 4
),
county_daily AS (             -- 5
    SELECT  c."date",
            c."county",
            c."county_fips_code",
            c."confirmed_cases"
              - LAG(c."confirmed_cases")
                OVER (PARTITION BY c."county_fips_code" ORDER BY c."date") AS "new_cases"
    FROM COVID19_NYT.COVID19_NYT.US_COUNTIES c
    WHERE c."state_name" IN (SELECT "state_name" FROM fourth_state)
      AND c."date" BETWEEN '2020-03-01' AND '2020-05-31'
),
county_top5 AS (              -- 6
    SELECT  "date",
            "county",
            ROW_NUMBER() OVER (PARTITION BY "date"
                               ORDER BY "new_cases" DESC NULLS LAST) AS rn
    FROM county_daily
),
county_rank AS (              -- 7
    SELECT  "county",
            COUNT(*)                                AS top5_hits,
            RANK() OVER (ORDER BY COUNT(*) DESC)    AS county_rank_within_state
    FROM county_top5
    WHERE rn <= 5
    GROUP BY "county"
    ORDER BY top5_hits DESC, "county"
    LIMIT 5
)
/* ----------------------------------------------------------------
   FINAL OUTPUT
   ----------------------------------------------------------------
   order_seq = 1 → state results (complete ranking)
   order_seq = 2 → county results for the 4th-ranked state
------------------------------------------------------------------*/
SELECT  1                                 AS order_seq,
        'STATE'                           AS level,
        "state_name"                      AS name,
        top5_hits,
        state_overall_rank                AS rank_in_group
FROM    state_rank

UNION ALL

SELECT  2                                 AS order_seq,
        'COUNTY of ' || 
        (SELECT "state_name" FROM fourth_state)   AS level,
        "county"                         AS name,
        top5_hits,
        county_rank_within_state         AS rank_in_group
FROM    county_rank

ORDER BY order_seq, rank_in_group;