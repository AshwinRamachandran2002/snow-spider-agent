SELECT `year` FROM (
    SELECT `year`, `month`, `day`
    FROM `bigquery-public-data.gbif.occurrences`
    WHERE LOWER(`scientificname`) LIKE '%sterna paradisaea%'
      AND `decimallatitude` > 40
      AND `month` > 1
    GROUP BY `year`, `month`, `day`
    HAVING COUNT(*) > 10
    ORDER BY `year` ASC, `month` ASC, `day` ASC
    LIMIT 1
) AS earliest_day;