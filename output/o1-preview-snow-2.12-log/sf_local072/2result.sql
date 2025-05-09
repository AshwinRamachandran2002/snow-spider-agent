WITH country_dates AS (
    SELECT
        "country_code_2",
        TO_DATE("insert_date") AS insert_date
    FROM
        "CITY_LEGISLATION"."CITY_LEGISLATION"."CITIES"
    WHERE
        "insert_date" LIKE '2022-01-%'
),
country_insert_days AS (
    SELECT
        "country_code_2",
        COUNT(DISTINCT insert_date) AS num_insert_days
    FROM
        country_dates
    GROUP BY
        "country_code_2"
),
target_country AS (
    SELECT
        "country_code_2"
    FROM
        country_insert_days
    WHERE
        num_insert_days = 9
),
dates_for_country AS (
    SELECT DISTINCT
        insert_date
    FROM
        country_dates
    WHERE
        "country_code_2" = (SELECT "country_code_2" FROM target_country)
),
dates_ordered AS (
    SELECT
        insert_date,
        ROW_NUMBER() OVER (ORDER BY insert_date) AS rn
    FROM
        dates_for_country
),
grouping AS (
    SELECT
        insert_date,
        rn,
        DATEADD('day', -rn, insert_date) AS grp
    FROM
        dates_ordered
),
grouped_sequences AS (
    SELECT
        COUNT(*) AS seq_len,
        MIN(insert_date) AS start_date,
        MAX(insert_date) AS end_date
    FROM
        grouping
    GROUP BY
        grp
),
longest_sequence AS (
    SELECT
        seq_len,
        start_date,
        end_date
    FROM
        grouped_sequences
    ORDER BY
        seq_len DESC NULLS LAST
    LIMIT 1
),
total_entries AS (
    SELECT
        COUNT(*)::FLOAT AS total_entries
    FROM
        "CITY_LEGISLATION"."CITY_LEGISLATION"."CITIES"
    WHERE
        "country_code_2" = (SELECT "country_code_2" FROM target_country)
        AND TO_DATE("insert_date") BETWEEN (SELECT start_date FROM longest_sequence) AND (SELECT end_date FROM longest_sequence)
),
capital_entries AS (
    SELECT
        COUNT(*)::FLOAT AS capital_entries
    FROM
        "CITY_LEGISLATION"."CITY_LEGISLATION"."CITIES"
    WHERE
        "country_code_2" = (SELECT "country_code_2" FROM target_country)
        AND "capital" = 1
        AND TO_DATE("insert_date") BETWEEN (SELECT start_date FROM longest_sequence) AND (SELECT end_date FROM longest_sequence)
)
SELECT
    UPPER(target_country."country_code_2") AS "COUNTRY_CODE_2",
    longest_sequence.seq_len AS "LONGEST_SEQ_LEN",
    TO_VARCHAR(longest_sequence.start_date, 'YYYY-MM-DD') AS "SEQ_START_DATE",
    TO_VARCHAR(longest_sequence.end_date, 'YYYY-MM-DD') AS "SEQ_END_DATE",
    total_entries.total_entries AS "TOTAL_ENTRIES",
    capital_entries.capital_entries AS "CAPITAL_ENTRIES",
    TO_CHAR(ROUND(capital_entries.capital_entries / total_entries.total_entries, 4), '0.0000') AS "PROPORTION_FROM_CAPITAL"
FROM
    target_country
CROSS JOIN
    longest_sequence
CROSS JOIN
    total_entries
CROSS JOIN
    capital_entries;