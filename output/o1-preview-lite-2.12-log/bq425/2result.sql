SELECT
  sub.chembl_id AS Molecule_ChEMBL_ID,
  sub.pref_name AS Preferred_Name,
  sub.trade_name AS Trade_Name,
  sub.approval_date AS Approval_Date
FROM (
  SELECT
    m.chembl_id,
    m.pref_name,
    p.trade_name,
    p.approval_date,
    ROW_NUMBER() OVER (
      PARTITION BY m.chembl_id
      ORDER BY p.approval_date DESC
    ) AS rn
  FROM `bigquery-public-data.ebi_chembl.molecule_dictionary_23` AS m
  JOIN `bigquery-public-data.ebi_chembl.formulations_23` AS f
    ON m.molregno = f.molregno
  JOIN `bigquery-public-data.ebi_chembl.products_23` AS p
    ON f.product_id = p.product_id
  WHERE (LOWER(p.applicant_full_name) LIKE '%sanofi%' AND LOWER(p.applicant_full_name) LIKE '%aventis%')
     OR (LOWER(p.innovator_company) LIKE '%sanofi%' AND LOWER(p.innovator_company) LIKE '%aventis%')
) AS sub
WHERE sub.rn = 1
ORDER BY Molecule_ChEMBL_ID;