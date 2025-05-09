/* -----------------------------------------------------------------
   1) Rank STATES by how many times they appear in the daily TOP-5
      new-case list (01-Mar-2020 – 31-May-2020).

   2) Identify the 4-th ranked state, then rank its COUNTIES by how
      many times they appear in that state’s daily TOP-5 list during
      the same period.  Show the TOP-5 counties.

   Final output columns:
      section  – 1 = state results, 2 = county results
      rank     – rank within the section
      name     – state or county name
      frequency– how many times it appeared in a daily TOP-5 list
-----------------------------------------------------------------*/

WITH /* ----------  DAILY STATE-LEVEL NEW CASES  ---------- */
state_daily AS (
    SELECT
        "date",
        "state_name",
        COALESCE(
            "confirmed_cases"
          - LAG("confirmed_cases") OVER (PARTITION BY "state_name"
                                         ORDER BY "date"),
            0
        ) AS new_cases
    FROM COVID19_NYT.COVID19_NYT.US_STATES
    WHERE "date" BETWEEN '2020-03-01' AND '2020-05-31'
),

/* ----------  RANK STATES BY NEW CASES EACH DAY  ---------- */
state_ranked AS (
    SELECT
        "date",
        "state_name",
        new_cases,
        ROW_NUMBER() OVER (PARTITION BY "date"
                           ORDER BY new_cases DESC) AS rnk
    FROM state_daily
),

/* ----------  COUNT HOW OFTEN EACH STATE IS IN DAILY TOP-5  ---------- */
state_top5_counts AS (
    SELECT
        "state_name",
        COUNT(*) AS top5_count
    FROM state_ranked
    WHERE rnk <= 5
    GROUP BY "state_name"
),

/* ----------  OVERALL STATE RANKING  ---------- */
state_ranking AS (
    SELECT
        "state_name",
        top5_count,
        ROW_NUMBER() OVER (ORDER BY top5_count DESC) AS overall_rank
    FROM state_top5_counts
),

/* ----------  IDENTIFY THE 4-TH RANKED STATE  ---------- */
fourth_state AS (
    SELECT "state_name"
    FROM   state_ranking
    WHERE  overall_rank = 4
),

/* ----------  DAILY COUNTY-LEVEL NEW CASES (4-TH STATE)  ---------- */
county_daily AS (
    SELECT
        u."date",
        u."county",
        COALESCE(
            u."confirmed_cases"
          - LAG(u."confirmed_cases") OVER (PARTITION BY u."county_fips_code"
                                           ORDER BY u."date"),
            0
        ) AS new_cases
    FROM COVID19_NYT.COVID19_NYT.US_COUNTIES u
    WHERE u."state_name" IN (SELECT "state_name" FROM fourth_state)
      AND u."date" BETWEEN '2020-03-01' AND '2020-05-31'
),

/* ----------  RANK COUNTIES (WITHIN THAT STATE) EACH DAY  ---------- */
county_ranked AS (
    SELECT
        "date",
        "county",
        new_cases,
        ROW_NUMBER() OVER (PARTITION BY "date"
                           ORDER BY new_cases DESC) AS rnk
    FROM county_daily
),

/* ----------  COUNT HOW OFTEN EACH COUNTY IS IN DAILY TOP-5  ---------- */
county_top5_counts AS (
    SELECT
        "county",
        COUNT(*) AS top5_count
    FROM county_ranked
    WHERE rnk <= 5
    GROUP BY "county"
),

/* ----------  TOP-5 COUNTIES BY THAT FREQUENCY  ---------- */
county_top5_final AS (
    SELECT
        "county",
        top5_count,
        ROW_NUMBER() OVER (ORDER BY top5_count DESC) AS county_rank
    FROM county_top5_counts
    ORDER BY top5_count DESC
    LIMIT 5
)

/* ----------  COMBINE RESULTS FOR OUTPUT  ---------- */
SELECT
    1           AS section,
    overall_rank AS rank,
    "state_name" AS name,
    top5_count   AS frequency
FROM state_ranking

UNION ALL

SELECT
    2            AS section,
    county_rank  AS rank,
    "county"     AS name,
    top5_count   AS frequency
FROM county_top5_final

ORDER BY section, rank;