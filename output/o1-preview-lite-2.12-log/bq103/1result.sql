SELECT
  COUNT(DISTINCT start_position) AS Number_of_variants,
  SUM(alt.AC) AS Total_Allele_Count,
  SUM(AN) AS Total_Number_of_Alleles,
  ROUND(COUNT(DISTINCT start_position) / (55064852 - 55039447), 4) AS Mutation_Density
FROM
  `bigquery-public-data.gnomAD.v3_genomes__chr1`,
  UNNEST(alternate_bases) AS alt
WHERE
  start_position BETWEEN 55039447 AND 55064852;