# Source Data

## Original Data Format

The source dataset was originally provided as a Microsoft Excel workbook containing multiple worksheets. To establish a consistent and reproducible SQL Server import workflow, each Excel worksheet was exported as a separate CSV file before being loaded into the database.

The original Excel workbook is approximately 52 MB, while the exported CSV files total approximately 65 MB.

## Data Availability

The raw Excel and CSV files are not included in this repository to keep the portfolio project lightweight and easy to clone.

Users with authorized access to the original dataset can reproduce the database by exporting each Excel worksheet as a separate CSV file and importing the resulting files into SQL Server.

## Dataset Attribution

The dataset used in this project was originally provided for a final project in the Syntax Technologies Data Analytics bootcamp. The original Excel workbook and exported CSV files are not included or redistributed in this repository.

The SQL data-profiling and cleaning procedures, analytical queries, business insights, documentation, ERD, and repository presentation were independently developed and expanded for this portfolio project.

Because the original dataset is not publicly distributed, the exact analytical results cannot be reproduced without access to the source data. Result screenshots are included to demonstrate the completed analysis.

## Source Tables

The dataset contains the following source tables:

- `HMSales`
- `HMCalendar`
- `HMChannel`
- `HMCustomers`
- `HMProductCategory`
- `HMProductSubCategory`
- `HMProducts`
- `HMStores`
- `Countries by Continents`

## Import Notes

- Each Excel worksheet was exported as an individual CSV file.
- The CSV files were imported into Microsoft SQL Server.
- The CSV files were imported without defining physical primary-key or foreign-key constraints. Candidate keys and table relationships were validated logically during data profiling and dataset exploration.
- Table structures and column definitions are documented in `docs/01_Data_Dictionary.md`.
- Data-quality issues found after import are documented and validated in `SQL/02_Data_Profiling.sql`.
- Required corrections are implemented in `SQL/03_Data_Cleaning.sql`.
- The cleaning script should be executed only once on the original imported dataset.

## Reproduction Workflow for Authorized Users

1. Obtain authorized access to the original Excel workbook.
2. Export each worksheet as a separate CSV file.
3. Import each CSV file into SQL Server using the table names listed above.
4. Run `SQL/02_Data_Profiling.sql`.
5. Run `SQL/03_Data_Cleaning.sql` once.
6. Run `SQL/02_Data_Profiling.sql` again to validate the cleaned data.
7. Execute the analytical scripts in numerical order.
