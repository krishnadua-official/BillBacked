# Sample Data — 20 Patients

Manually authored billing PDFs for BillBacked extractor testing.
Each patient folder has five `.pdf` documents.

## Document types (per patient)

| File | Description |
|------|-------------|
| `patient_billing_statement.pdf` | Summary bill from provider |
| `eob.pdf` | Insurance Explanation of Benefits (or equivalent) |
| `msn.pdf` | Medicare Summary Notice (often N/A or wrong upload) |
| `itemized_bill.pdf` | Line-level charges (UB-04, CMS-1500, or sparse) |
| `payment_receipt.pdf` | Proof of payment (may be missing or partial) |

## Patients

| Folder | Patient | Scenario | Completeness |
|--------|---------|----------|--------------|
| `patient-01-margaret-chen` | Margaret Chen, 68 | Medicare + Medigap hip replacement | Complete, professional |
| `patient-02-james-obrien` | James O'Brien, 72 | Medicare heart failure admission | Smudged account #; receipt is scan-style PDF |
| `patient-03-rosa-martinez` | Rosa Martinez, 34 | BCBS ER + surprise OON bills | Wrong MSN upload; no payments |
| `patient-04-david-kim` | David Kim, 45 | Aetna denied MRI | Missing NPI; empty MSN |
| `patient-05-patricia-williams` | Patricia Williams, 52 | Uninsured surgery, GFE dispute | No real EOB/MSN |
| `patient-06-robert-thompson` | Robert Thompson, 79 | Medicare DME CPAP | Complete |
| `patient-07-sarah-johnson` | Sarah Johnson, 29 | UHC maternity | Partial itemized (page 1 only) |
| `patient-08-michael-davis` | Michael Davis, 61 | Cigna PT — wrong MSN uploaded | 11/12 copay receipts |
| `patient-09-linda-garcia` | Linda Garcia, 55 | Medicare Advantage OON denial | Confusing MA + MSN |
| `patient-10-william-brown` | William Brown, 67 | Pharmacy only — wrong doc type | No hospital itemized |
| `patient-11-jennifer-lee` | Jennifer Lee, 38 | Kaiser integrated — no line items | Paid in full |
| `patient-12-thomas-wilson` | Thomas Wilson, 84 | SNF Medicare + Medicaid | MSN/bill mismatch |
| `patient-13-amanda-taylor` | Amanda Taylor, 41 | Anthem surprise anesthesia bill | NSA candidate |
| `patient-14-christopher-moore` | Christopher Moore, 22 | MassHealth FQHC | $0 balance |
| `patient-15-elizabeth-anderson` | Elizabeth Anderson, 70 | Dual Medicare/Medicaid | Private room upgrade |
| `patient-16-daniel-jackson` | Daniel Jackson, 48 | Uninsured ER, collections | Minimal docs; scan PDF |
| `patient-17-nancy-white` | Nancy White, 63 | BCBS duplicate CPT charge | EOB vs bill mismatch |
| `patient-18-kevin-harris` | Kevin Harris, 75 | Home health sparse records | Medigap lag |
| `patient-19-dorothy-martin` | Dorothy Martin, 68 | Tricare + Medicare cataract | TFL vs hospital mismatch |
| `patient-20-steven-clark` | Steven Clark, 31 | Oscar telehealth app export | Minimal modern format |

## PDF types

Most PDFs are **text-layer** documents (exercises the `text_pdf` extraction path).

Two are **scan-simulation** PDFs (image-only, no text layer — exercises OCR):

- `patient-02-james-obrien/payment_receipt.pdf`
- `patient-16-daniel-jackson/patient_billing_statement.pdf`

## Test extractor

```bash
python lib/extract_text.py "Sample Data/patient-01-margaret-chen/eob.pdf"
python lib/extract_text.py "Sample Data/patient-02-james-obrien/payment_receipt.pdf"
```
