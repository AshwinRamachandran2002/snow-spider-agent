--Description: Intended to analyse chr17:41 196 311-41 277 499 variants (genotype
--             counts, HWE χ², allele frequencies, etc.).  This cannot be run
--             because the table spider2-public-data.1000_genomes.variants is
--             not readable under the current credentials (403).  Emit a simple
--             diagnostic row instead.
SELECT
  'Variant-region analysis query skipped — no permission on spider2-public-data.1000_genomes.variants'
    AS variant_region_query_status