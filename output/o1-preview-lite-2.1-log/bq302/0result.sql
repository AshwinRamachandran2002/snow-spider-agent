SELECT
  Month,
  Proportion
FROM (
  SELECT
    FORMAT_DATE('%b-%Y', DATE_TRUNC(creation_date, MONTH)) AS Month,
    DATE_TRUNC(creation_date, MONTH) AS MonthDate,
    ROUND(
      SAFE_DIVIDE(
        SUM(CASE WHEN REGEXP_CONTAINS(tags, r'(^|[|])python([|]|$)') THEN 1 ELSE 0 END),
        COUNT(1)
      ),
      4
    ) AS Proportion
  FROM
    `bigquery-public-data.stackoverflow.posts_questions`
  WHERE
    creation_date BETWEEN '2022-01-01' AND '2022-12-31'
  GROUP BY
    MonthDate,
    Month
)
ORDER BY
  MonthDate;