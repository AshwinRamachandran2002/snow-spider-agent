SELECT COUNT(DISTINCT "StudyInstanceUID") AS "unique_study_count"
FROM IDC.IDC_V17."DICOM_PIVOT"
WHERE "collection_id" = 'qin_prostate_repeatability'
  AND (
        "SeriesDescription" ILIKE 'DWI%'                        -- Diffusion‑weighted imaging
     OR "SeriesDescription" ILIKE 'T2 Weighted Axial%'          -- T2‑weighted axial
     OR "SeriesDescription" ILIKE 'Apparent Diffusion Coefficient%' -- ADC
     OR "SeriesDescription" ILIKE 'T2 Weighted Axial Segmentations%' -- T2 axial segmentations
      );