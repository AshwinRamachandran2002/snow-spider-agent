WITH patents AS (
    SELECT
        "publication_number",
        FLOOR("filing_date" / 10000) AS filing_year,
        ARRAY_SIZE("inventor") AS num_inventors,
        CONCAT(
            ((FLOOR((FLOOR("filing_date" / 10000) - 1960) / 5) * 5 + 1960))::VARCHAR,
            '-',
            ((FLOOR((FLOOR("filing_date" / 10000) - 1960) / 5) * 5 + 1960 + 4))::VARCHAR
        ) AS "Year"
    FROM
        PATENTS.PATENTS.PUBLICATIONS
    WHERE
        "filing_date" BETWEEN 19600101 AND 20201231
        AND "inventor" IS NOT NULL
        AND ARRAY_SIZE("inventor") > 0
)

SELECT
    "Year",
    COUNT(DISTINCT "publication_number") AS "Number_of_Patent_Publications",
    ROUND(AVG(num_inventors), 4) AS "Average_Number_of_Inventors_Per_Patent"
FROM
    patents
GROUP BY
    "Year"
ORDER BY
    "Year";