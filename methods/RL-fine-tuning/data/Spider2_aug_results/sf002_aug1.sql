-- Task: As of December 31, 2022, list the active banks with assets exceeding $10 billion. Provide the names of these banks.
SELECT ent.name
FROM FINANCE__ECONOMICS.CYBERSYN.financial_institution_timeseries AS ts
INNER JOIN FINANCE__ECONOMICS.CYBERSYN.financial_institution_entities AS ent ON ts.id_rssd = ent.id_rssd
WHERE ts.variable = 'ASSET'
  AND ts.date = '2022-12-31'
  AND ts.value > 1E10
  AND ent.is_active = True
LIMIT 100;