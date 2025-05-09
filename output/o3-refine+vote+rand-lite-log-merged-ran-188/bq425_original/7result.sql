WITH company_res_stems AS (
  SELECT DISTINCT res_stem_id
  FROM `bigquery-public-data.ebi_chembl.research_companies_23`
  WHERE company = 'SanofiAventis'             -- exact match
),
company_molecules AS (
  SELECT DISTINCT molregno
  FROM `bigquery-public-data.ebi_chembl.molecule_synonyms_23`
  WHERE res_stem_id IN (SELECT res_stem_id FROM company_res_stems)
),
company_products AS (
  SELECT
    f.molregno,
    p.trade_name,
    p.approval_date
  FROM `bigquery-public-data.ebi_chembl.formulations_23` AS f
  JOIN `bigquery-public-data.ebi_chembl.products_23`      AS p
    ON p.product_id = f.product_id
  JOIN company_molecules AS cm
    ON cm.molregno = f.molregno
),
latest_per_molecule AS (
  SELECT
    molregno,
    trade_name,
    approval_date,
    ROW_NUMBER() OVER (
      PARTITION BY molregno
      ORDER BY approval_date DESC NULLS LAST
    ) AS rn
  FROM company_products
)
SELECT
  md.chembl_id  AS molecule_chembl_id,
  l.trade_name,
  l.approval_date AS latest_approval_date
FROM latest_per_molecule AS l
JOIN `bigquery-public-data.ebi_chembl.molecule_dictionary_23` AS md
  ON md.molregno = l.molregno
WHERE l.rn = 1
ORDER BY molecule_chembl_id;