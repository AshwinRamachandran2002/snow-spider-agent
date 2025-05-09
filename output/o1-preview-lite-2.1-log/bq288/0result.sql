SELECT
  state AS State,
  COUNT(*) AS Total_Number_of_Banking_Institutions
FROM
  `bigquery-public-data.fdic_banks.institutions`
WHERE
  state = (
    SELECT
      state
    FROM (
      SELECT
        state,
        SUM(total_assets) AS sum_total_assets
      FROM
        `bigquery-public-data.fdic_banks.institutions`
      WHERE
        institution_name LIKE 'Bank%'
        AND established_date BETWEEN '1900-01-01' AND '2000-12-31'
        AND total_assets IS NOT NULL
      GROUP BY
        state
      ORDER BY
        sum_total_assets DESC
      LIMIT 1
    )
  )
GROUP BY
  state;