WITH molecule_approvals AS (
  SELECT
    m.`chembl_id` AS Molecule_ChEMBL_ID,
    m.`pref_name` AS Preferred_Name,
    p.`trade_name` AS Trade_Name,
    SAFE.PARSE_DATE('%Y-%m-%d', p.`approval_date`) AS Approval_Date,
    ROW_NUMBER() OVER (
      PARTITION BY m.`chembl_id`
      ORDER BY SAFE.PARSE_DATE('%Y-%m-%d', p.`approval_date`) DESC
    ) AS rn
  FROM
    `bigquery-public-data.ebi_chembl.molecule_dictionary_23` AS m
  JOIN
    `bigquery-public-data.ebi_chembl.formulations_23` AS f
    ON m.`molregno` = f.`molregno`
  JOIN
    `bigquery-public-data.ebi_chembl.products_23` AS p
    ON f.`product_id` = p.`product_id`
  WHERE
    LOWER(p.`applicant_full_name`) LIKE '%sanofi%'
)
SELECT
  Molecule_ChEMBL_ID,
  Preferred_Name,
  Trade_Name,
  Approval_Date
FROM
  molecule_approvals
WHERE
  rn = 1
ORDER BY
  Approval_Date DESC;