WITH cpc_level5 AS
(
    SELECT "symbol" AS "cpc_code", "titleFull" AS "cpc_title"
    FROM PATENTS.PATENTS.CPC_DEFINITION
    WHERE "level" = 5
),
initial_data AS
(
    SELECT
        p."publication_number",
        p."application_number",
        TO_VARCHAR(TRY_TO_DATE(TO_CHAR(p."filing_date"), 'YYYYMMDD'), 'YYYY') AS "filing_year",
        SUBSTR(f.VALUE:"code"::STRING, 1, 4) AS "first_cpc_code_level5"
    FROM PATENTS.PATENTS.PUBLICATIONS p,
    LATERAL FLATTEN(input => p."cpc", outer => TRUE) f
    WHERE f.INDEX = 0
        AND p."application_number" IS NOT NULL
        AND p."application_number" <> ''
        AND p."filing_date" IS NOT NULL
        AND TRY_TO_DATE(TO_CHAR(p."filing_date"), 'YYYYMMDD') IS NOT NULL
        AND SUBSTR(f.VALUE:"code"::STRING, 1, 4) IS NOT NULL
),
filtered_data AS
(
    SELECT
        i."first_cpc_code_level5" AS "cpc_code",
        CAST(i."filing_year" AS INTEGER) AS "filing_year"
    FROM initial_data i
    INNER JOIN cpc_level5 cpc5
        ON i."first_cpc_code_level5" = cpc5."cpc_code"
),
patent_counts AS
(
    SELECT
        "cpc_code",
        "filing_year",
        COUNT(*) AS "patent_count"
    FROM filtered_data
    GROUP BY "cpc_code", "filing_year"
),
ordered_counts AS
(
    SELECT
        "cpc_code",
        "filing_year",
        "patent_count",
        ROW_NUMBER() OVER (PARTITION BY "cpc_code" ORDER BY "filing_year") AS rn
    FROM patent_counts
),
ema_recursive AS
(
    SELECT
        cpc."cpc_code",
        cpc."filing_year",
        cpc."patent_count",
        cpc."patent_count" AS ema,
        cpc.rn
    FROM ordered_counts cpc
    WHERE cpc.rn = 1

    UNION ALL

    SELECT
        cpc."cpc_code",
        cpc."filing_year",
        cpc."patent_count",
        0.2 * cpc."patent_count" + 0.8 * prev.ema AS ema,
        cpc.rn
    FROM ordered_counts cpc
    JOIN ema_recursive prev
        ON cpc."cpc_code" = prev."cpc_code" AND cpc.rn = prev.rn + 1
),
max_ema_per_cpc AS
(
    SELECT
        "cpc_code",
        MAX(ema) AS max_ema
    FROM ema_recursive
    GROUP BY "cpc_code"
),
best_year_per_cpc AS
(
    SELECT
        e."cpc_code",
        e."filing_year" AS "Best_Year",
        ROW_NUMBER() OVER (PARTITION BY e."cpc_code" ORDER BY e."filing_year") AS rn
    FROM ema_recursive e
    INNER JOIN max_ema_per_cpc m
        ON e."cpc_code" = m."cpc_code" AND e.ema = m.max_ema
),
best_year_per_cpc_unique AS
(
    SELECT "cpc_code", "Best_Year"
    FROM best_year_per_cpc
    WHERE rn = 1
)
SELECT
    cpc5."cpc_title" AS "CPC_Title",
    best_year_per_cpc_unique."Best_Year"
FROM best_year_per_cpc_unique
INNER JOIN cpc_level5 cpc5
    ON best_year_per_cpc_unique."cpc_code" = cpc5."cpc_code";