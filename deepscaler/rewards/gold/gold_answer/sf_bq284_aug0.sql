-- Task: Provide a report that lists each category from the BBC News, including the total number of articles in each category, and the percentage (rounded to 4 decimal places) of those articles where the title or body contains the word "education" (case-insensitive).

SELECT
    "category",
    COUNT(*) AS "Total_Articles",
    ROUND(
        (SUM(CASE WHEN ("body" ILIKE '%education%' OR "title" ILIKE '%education%') THEN 1 ELSE 0 END) * 100.0) / COUNT(*),
        4
    ) AS "Percentage_Mentioning_Education"
FROM BBC.BBC_NEWS.FULLTEXT
GROUP BY "category";