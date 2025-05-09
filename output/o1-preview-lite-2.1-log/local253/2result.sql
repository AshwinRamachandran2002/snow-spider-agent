SELECT
    "Location",
    "CompanyName",
    AVG(
        CASE
            WHEN "Salary" LIKE '%/yr' THEN
                CAST(
                    REPLACE(REPLACE(REPLACE("Salary", '₹', ''), ',', ''), '/yr', '') AS REAL
                )
            WHEN "Salary" LIKE '%/mo' THEN
                CAST(
                    REPLACE(REPLACE(REPLACE("Salary", '₹', ''), ',', ''), '/mo', '') AS REAL
                ) * 12
            WHEN "Salary" LIKE '%/hr' THEN
                CAST(
                    REPLACE(REPLACE(REPLACE("Salary", '₹', ''), ',', ''), '/hr', '') AS REAL
                ) * 8 * 250
            ELSE NULL
        END
    ) AS "Average Salary in State",
    (
        SELECT AVG(
            CASE
                WHEN sd2."Salary" LIKE '%/yr' THEN
                    CAST(
                        REPLACE(REPLACE(REPLACE(sd2."Salary", '₹', ''), ',', ''), '/yr', '') AS REAL
                    )
                WHEN sd2."Salary" LIKE '%/mo' THEN
                    CAST(
                        REPLACE(REPLACE(REPLACE(sd2."Salary", '₹', ''), ',', ''), '/mo', '') AS REAL
                    ) * 12
                WHEN sd2."Salary" LIKE '%/hr' THEN
                    CAST(
                        REPLACE(REPLACE(REPLACE(sd2."Salary", '₹', ''), ',', ''), '/hr', '') AS REAL
                    ) * 8 * 250
                ELSE NULL
            END
        )
        FROM "SalaryDataset" sd2
        WHERE sd2."CompanyName" = sd."CompanyName"
    ) AS "Average Salary in Country"
FROM "SalaryDataset" sd
WHERE "Location" IN ('Mumbai', 'Pune', 'New Delhi', 'Hyderabad')
GROUP BY "Location", "CompanyName"
ORDER BY "Average Salary in State" DESC
LIMIT 5;