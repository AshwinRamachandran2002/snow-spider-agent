-- Task: Retrieve up to 100 molecules associated with the company 'SanofiAventis', listing their trade names and approval dates.

SELECT
  molregno,
  comp.company,
  prod.trade_name,
  prod.approval_date
FROM bigquery-public-data.ebi_chembl.compound_records_23 AS cmpd_rec
JOIN bigquery-public-data.ebi_chembl.molecule_synonyms_23 AS ms USING (molregno)
JOIN bigquery-public-data.ebi_chembl.research_companies_23 AS comp USING (res_stem_id)
JOIN bigquery-public-data.ebi_chembl.formulations_23 AS form USING (molregno)
JOIN bigquery-public-data.ebi_chembl.products_23 AS prod USING (product_id)
WHERE comp.company = 'SanofiAventis'
LIMIT 100