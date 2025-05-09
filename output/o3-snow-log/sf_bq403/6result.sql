WITH unified AS (
    /* 2012 filings – tax period stored as TEXT, so take the first 4 chars */
    SELECT
        SUBSTR("tax_pd", 1, 4)::NUMBER           AS "year",
        "totrevenue",
        "totfuncexpns"
    FROM IRS_990.IRS_990."IRS_990_2012"

    UNION ALL

    /* 2013 filings – tax period stored as NUMBER, YYMM; convert to year */
    SELECT
        FLOOR("tax_pd" / 100)                    AS "year",
        "totrevenue",
        "totfuncexpns"
    FROM IRS_990.IRS_990."IRS_990_2013"

    UNION ALL

    /* 2014 filings */
    SELECT
        FLOOR("tax_pd" / 100)                    AS "year",
        "totrevenue",
        "totfuncexpns"
    FROM IRS_990.IRS_990."IRS_990_2014"

    UNION ALL

    /* 2015 filings */
    SELECT
        FLOOR("tax_pd" / 100)                    AS "year",
        "totrevenue",
        "totfuncexpns"
    FROM IRS_990.IRS_990."IRS_990_2015"

    UNION ALL

    /* 2016 filings */
    SELECT
        FLOOR("tax_pd" / 100)                    AS "year",
        "totrevenue",
        "totfuncexpns"
    FROM IRS_990.IRS_990."IRS_990_2016"

    UNION ALL

    /* 2017 filings */
    SELECT
        FLOOR("tax_pd" / 100)                    AS "year",
        "totrevenue",
        "totfuncexpns"
    FROM IRS_990.IRS_990."IRS_990_2017"
),
yearly_stats AS (
    SELECT
        "year",
        APPROX_PERCENTILE("totrevenue",   0.5)   AS "median_revenue",
        APPROX_PERCENTILE("totfuncexpns", 0.5)   AS "median_expenses"
    FROM unified
    WHERE "year" BETWEEN 2012 AND 2017           -- focus on the six target years
          AND "totrevenue"   IS NOT NULL
          AND "totfuncexpns" IS NOT NULL
    GROUP BY "year"
),
with_diffs AS (
    SELECT
        "year",
        ABS("median_revenue" - "median_expenses") AS "abs_median_diff"
    FROM yearly_stats
)
SELECT
    "year",
    "abs_median_diff"
FROM with_diffs
ORDER BY "abs_median_diff" ASC
LIMIT 3;