SELECT 
    "category" AS Category,
    COUNT(*) AS Total_Articles,
    ROUND(
        SUM(
            CASE 
                WHEN "body" ILIKE '%education%' THEN 1 ELSE 0 END
            ) * 100.0 / COUNT(*), 4
        ) AS Percentage_Mentioning_Education
FROM
    BBC.BBC_NEWS.FULLTEXT
GROUP BY
    "category";