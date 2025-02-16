-- Task: Using data from ChEMBL Release 23, retrieve all distinct molecules (`molregno`) associated with the company 'SanofiAventis' as per the `research_companies_23` table. For each molecule, list the company name, trade name, and the most recent approval date from the `products_23` table. Ensure that the company field exactly matches 'SanofiAventis', and retain only the latest approval date per molecule by ordering the approval dates in descending order after parsing them as dates.
SELECT *
  FROM (
  SELECT
  molregno,
  comp.company,
  prod.trade_name,
  prod.approval_date,
  ROW_NUMBER() OVER(PARTITION BY molregno ORDER BY PARSE_DATE('%Y-%m-%d', prod.approval_date) DESC) rn
  FROM bigquery-public-data.ebi_chembl.compound_records_23 AS cmpd_rec
  JOIN bigquery-public-data.ebi_chembl.molecule_synonyms_23 AS ms USING (molregno)
  JOIN bigquery-public-data.ebi_chembl.research_companies_23 AS comp USING (res_stem_id)
  JOIN bigquery-public-data.ebi_chembl.formulations_23 AS form USING (molregno)
  JOIN bigquery-public-data.ebi_chembl.products_23 AS prod USING (product_id)
  ) as subq
 WHERE rn = 1 AND company = 'SanofiAventis'