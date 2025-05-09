SELECT DATEDIFF(year, ft."first_term_start", TO_DATE(d."date", 'YYYY-MM-DD')) AS "Years_Elapsed",
       COUNT(DISTINCT l."id_bioguide") AS "Number_of_Distinct_Legislators"
FROM CITY_LEGISLATION.CITY_LEGISLATION.LEGISLATORS l
JOIN CITY_LEGISLATION.CITY_LEGISLATION.LEGISLATORS_TERMS t
    ON l."id_bioguide" = t."id_bioguide"
JOIN (
    SELECT "id_bioguide", MIN(TO_DATE("term_start", 'YYYY-MM-DD')) AS "first_term_start"
    FROM CITY_LEGISLATION.CITY_LEGISLATION.LEGISLATORS_TERMS
    GROUP BY "id_bioguide"
) ft ON l."id_bioguide" = ft."id_bioguide"
JOIN CITY_LEGISLATION.CITY_LEGISLATION.LEGISLATION_DATE_DIM d
    ON EXTRACT(month FROM TO_DATE(d."date", 'YYYY-MM-DD')) = 12 
       AND EXTRACT(day FROM TO_DATE(d."date", 'YYYY-MM-DD')) = 31
WHERE l."gender" = 'M'
    AND t."state" = 'LA'
    AND TO_DATE(d."date", 'YYYY-MM-DD') BETWEEN TO_DATE(t."term_start", 'YYYY-MM-DD') AND TO_DATE(t."term_end", 'YYYY-MM-DD')
    AND DATEDIFF(year, ft."first_term_start", TO_DATE(d."date", 'YYYY-MM-DD')) > 30
    AND DATEDIFF(year, ft."first_term_start", TO_DATE(d."date", 'YYYY-MM-DD')) < 50
GROUP BY "Years_Elapsed"
ORDER BY "Years_Elapsed"