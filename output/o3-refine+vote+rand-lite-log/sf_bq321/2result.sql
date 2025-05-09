SELECT COUNT(DISTINCT "StudyInstanceUID") AS "unique_StudyInstanceUIDs"
FROM IDC.IDC_V17.DICOM_PIVOT
WHERE "collection_id" = 'qin_prostate_repeatability'
  AND (
        UPPER("SeriesDescription") ILIKE '%DWI%'                       -- Diffusion‑weighted imaging
     OR UPPER("SeriesDescription") ILIKE '%T2 WEIGHTED AXIAL SEG%'     -- T2‑weighted axial segmentations
     OR UPPER("SeriesDescription") ILIKE '%T2 WEIGHTED AXIAL%'         -- T2‑weighted axial
     OR UPPER("SeriesDescription") ILIKE '%APPARENT DIFFUSION COEFFICIENT%' -- ADC
  );