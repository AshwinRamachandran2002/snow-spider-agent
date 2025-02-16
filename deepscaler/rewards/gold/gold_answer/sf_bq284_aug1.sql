-- Task: Can you provide a breakdown of the number of articles that mention "education" into different categories from the BBC News?
SELECT
    "category",
    COUNT(*) AS "Articles_Mentioning_Education"
FROM BBC.BBC_NEWS.FULLTEXT
WHERE "body" ILIKE '%education%' OR "title" ILIKE '%education%'
GROUP BY "category";