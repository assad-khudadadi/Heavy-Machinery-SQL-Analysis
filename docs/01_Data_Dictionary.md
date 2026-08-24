# Heavy Machinery Sales Analysis — Data Dictionary

## Project Overview

This data dictionary documents the structure, purpose, business keys,
relationships, and important attributes of the tables used in the
Heavy Machinery Sales Analysis project.

It serves as a reference for the data profiling, cleaning, validation,
and business analysis stages of the project.

## Data Model

The dataset follows a hybrid star and snowflake schema.

- `HMSales` is the central fact table.
- Customer, store, channel, and calendar tables connect directly to the fact table.
- Product information is organized through product, subcategory, and category tables.
- `Countries by Continents` is used as a geographic reference table during data cleaning.

### Fact Table

- `HMSales`

### Dimension Tables

- `HMCustomers`
- `HMProducts`
- `HMProductSubCategory`
- `HMProductCategory`
- `HMStores`
- `HMChannel`
- `HMCalendar`

### Reference Table

- `Countries by Continents`

## Key Definition Note

The source tables were imported without physical primary key or foreign key
constraints. Therefore, the keys documented in this file represent validated
business or candidate keys unless otherwise stated.


## Table: HMCalendar

**Table Type:** Dimension Table

**Description:**

`HMCalendar` contains date-related attributes used to support
time-based sales and delivery analysis. It enables grouping,
filtering, and chronological comparison across days, months,
quarters, and years.

**Validated Candidate Key:**

- `Date`

The `Date` column contains unique values and can identify each
calendar record. However, no physical primary key constraint was
created during the original data import.

**Important Attributes:**

- `Date`
- `Year`
- `Quarter`
- `MonthNo`
- `MonthName`
- `DayNo`
- `DayName`
- `YearMonth`
- `MonthDay`
- `IsWeekEnd`
- `Week`
- `DaySerialNo`
- `SortYM`

**Relationships:**

- `HMCalendar.Date` → `HMSales.TransactionDate`
- `HMCalendar.Date` → `HMSales.DeliveryDate`

A single calendar date can be associated with multiple sales
transactions and delivery records.

**Business Use:**

- Analyze annual, quarterly, and monthly sales trends
- Identify high-revenue periods
- Compare performance across complete sales years
- Support transaction-date and delivery-date analysis
- Sort year-month values chronologically

**Data Quality Notes:**

- The calendar covers January 2002 through December 2013.
- No missing `Date` values were identified during data profiling.
- `Quarter` was corrected from an incorrectly imported numeric
  type to character values from `Q1` through `Q4`.
- `SortYM` was corrected from an incorrectly imported date type
  to an integer in `YYYYMM` format.

**Related Analyses:**

- Q2 — Revenue trend and highest-revenue months
- Q5–Q6.1 — Store performance in 2006 and 2007
- Q10–Q10.1 — Channel performance during the latest five complete years
- Q11–Q11.2 — Profit analysis for the most profitable complete year
- Q12–Q12.1 — Highest customer-spending year by country
- Q13–Q14.1 — Employee performance in 2011


## Table: HMChannel

**Table Type:** Dimension Table

**Description:**

`HMChannel` contains the sales or promotional channel associated
with each transaction in the `HMSales` table. It enables comparison
of revenue, order volume, and quantity sold across different channels.

**Validated Candidate Key:**

- `ChannelKey`

The `ChannelKey` column contains unique values and can identify each
channel record. However, no physical primary key constraint was
created during the original data import.

**Important Attributes:**

- `ChannelKey`
- `Channel`

**Relationship:**

- `HMChannel.ChannelKey` → `HMSales.ChannelKey`

One channel can be associated with multiple sales records, while each
sales record is associated with one channel value.

**Business Use:**

- Compare total revenue across sales channels
- Measure each channel’s contribution to company revenue
- Compare order volume and quantity sold by channel
- Calculate average revenue per order
- Evaluate historical and recent channel performance
- Identify the highest-revenue channel within individual years

**Analysis Limitations:**

The dataset does not include marketing cost, campaign spending,
conversion rate, customer acquisition cost, or attribution details.
Therefore, channel performance in this project is evaluated using
sales outcomes and should not be interpreted as marketing
return on investment.

**Related Analyses:**

- Q9 — Highest-revenue sales channel across the full period
- Q9.1 — Revenue contribution and performance by sales channel
- Q10 — Highest-revenue channel during the latest five complete years
- Q10.1 — Highest-revenue channel in each of the latest five years

## Table: HMCustomers

**Table Type:** Dimension Table

**Description:**

`HMCustomers` contains descriptive information about customers,
including customer name, industry, payment method, country,
continent, and contact person.

It supports customer-level, industry-level, and geographic
sales analysis.

**Validated Candidate Key:**

- `CustomerKey`

The `CustomerKey` column contains unique values and can identify
each customer record. However, no physical primary key constraint
was created during the original data import.

**Important Attributes:**

- `CustomerKey`
- `CustomerName`
- `Industry`
- `Payment`
- `Country`
- `Continent`
- `ContactPerson`

**Relationship:**

- `HMCustomers.CustomerKey` → `HMSales.CustomerKey`

One customer can be associated with multiple sales records, while
each sales record contains one customer key.

**Business Use:**

- Identify the highest-spending customers
- Measure customer revenue contribution
- Evaluate customer revenue concentration
- Calculate average and median revenue per purchasing customer
- Profile high-value customers by industry and geography
- Compare revenue across customer industries
- Filter product performance by customer country
- Analyze customer spending and value by country

**Data Quality Notes:**

- Customer country names were standardized during data cleaning.
- Values such as `US`, `UK`, `UAE`, and `Holland` were replaced
  with their corresponding standard country names.
- Not every customer in the dimension table appears in `HMSales`.
  Customers without matching sales records are not included in
  purchasing-customer metrics.
- Geographic analysis uses the cleaned country and continent values.

**Analysis Limitation:**

Customer spending in this project is represented by sales revenue.
The dataset does not include customer acquisition cost, satisfaction,
retention, or other behavioral measures. Therefore, customer value
is evaluated only from recorded sales activity.

**Related Analyses:**

- Q3–Q3.5 — Customer spending and revenue distribution
- Q4 — Profile of the top 10 highest-spending customers
- Q4.1 — Customer revenue by industry
- Q7–Q8 — Product performance among United States customers
- Q12–Q12.1 — Customer spending and value by country

## Table: HMProductCategory

**Table Type:** Dimension Table

**Description:**

`HMProductCategory` contains the highest-level classifications
used to organize the heavy machinery product portfolio.

Each product category can contain multiple product subcategories.

**Validated Candidate Key:**

- `CategoryKey`

The `CategoryKey` column contains unique values and can identify
each product category. However, no physical primary key constraint
was created during the original data import.

**Important Attributes:**

- `CategoryKey`
- `CategoryName`

**Relationship:**

- `HMProductCategory.CategoryKey`
  → `HMProductSubCategory.CategoryKey`

One product category can contain multiple product subcategories.
The category table is indirectly related to `HMSales` through
`HMProductSubCategory` and `HMProducts`.

**Relationship Path:**

`HMProductCategory` → `HMProductSubCategory` → `HMProducts` → `HMSales`

**Business Use:**

- Organize products into high-level business groups
- Add category context to product-level analysis
- Compare product leaders across broader machinery categories
- Support category and subcategory profitability analysis
- Evaluate the composition of the product portfolio

**Data Quality Notes:**

- `CategoryKey` was checked for duplicate values during data profiling.
- No duplicate category keys were identified.
- Category relationships depend on matching `CategoryKey` values
  in `HMProductSubCategory`.

**Related Analyses:**

- Q7–Q7.1 — Top-selling product and revenue performance by subcategory
- Q8 — Detailed profile of top-selling products
- Q11.2 — Profit contribution by product subcategory and category

## Table: HMProducts

**Table Type:** Dimension Table

**Description:**

`HMProducts` contains descriptive information about the heavy
machinery products represented in the sales dataset.

It includes product classification, description, brand, type,
color, expected shipping days, and product status.

**Validated Candidate Key:**

- `ProductKey`

The `ProductKey` column contains unique values and can identify
each product record. However, no physical primary key constraint
was created during the original data import.

**Business Foreign Key:**

- `SubCategoryKey` → `HMProductSubCategory.SubCategoryKey`

The relationship was validated logically, but no physical foreign
key constraint was created during the original data import.

**Important Attributes:**

- `ProductKey`
- `ProductDescription`
- `SubCategoryKey`
- `Brand`
- `Type`
- `Color`
- `ShipDays`
- `Status`

**Relationships:**

- `HMProducts.ProductKey` → `HMSales.ProductKey`
- `HMProducts.SubCategoryKey`
  → `HMProductSubCategory.SubCategoryKey`

One product can be associated with multiple sales records, while
each product belongs to one product subcategory.

**Business Use:**

- Identify top-selling products
- Compare product sales volume and revenue
- Measure customer reach and order frequency by product
- Compare products within their respective subcategories
- Examine product brand, type, color, shipping days, and status
- Calculate product-level revenue, cost, profit, and profit margin
- Identify the highest-profit products during the most profitable year

**Data Quality Notes:**

- `ProductKey` was checked for duplicates during data profiling.
- No duplicate product keys were identified.
- All product records contain an `Active` status.
- The exact business definition and reference date of `Status`
  are not provided in the source documentation.

**Analysis Limitations:**

- `ShipDays` is treated as a product attribute and should not
  automatically be interpreted as actual delivery duration.
- The dataset does not contain inventory levels, supplier data,
  stock availability, or product discontinuation history.
- Because all products have an `Active` status, the effect of
  product status on performance cannot be evaluated.

**Related Analyses:**

- Q7 — Top-selling products by subcategory among United States customers
- Q7.1 — Revenue performance of top-selling products
- Q8 — Detailed profile of top-selling products
- Q11 — Most profitable year and highest-profit product
- Q11.1 — Top 10 profit-contributing products
- Q11.2 — Profit contribution by product subcategory


## Table: HMProductSubCategory

**Table Type:** Dimension Table

**Description:**

`HMProductSubCategory` contains the detailed product groups used
to classify heavy machinery products below the category level.

Each product subcategory belongs to one product category and can
contain multiple products.

**Validated Candidate Key:**

- `SubCategoryKey`

The `SubCategoryKey` column contains unique values and can identify
each product subcategory. However, no physical primary key constraint
was created during the original data import.

**Business Foreign Key:**

- `CategoryKey` → `HMProductCategory.CategoryKey`

The relationship was validated logically, but no physical foreign
key constraint was created during the original data import.

**Important Attributes:**

- `SubCategoryKey`
- `SubCategoryName`
- `CategoryKey`

**Relationships:**

- `HMProductSubCategory.CategoryKey`
  → `HMProductCategory.CategoryKey`
- `HMProductSubCategory.SubCategoryKey`
  → `HMProducts.SubCategoryKey`

One category can contain multiple subcategories, and one
subcategory can contain multiple products.

**Relationship Path to Sales:**

`HMProductSubCategory` → `HMProducts` → `HMSales`

**Business Use:**

- Group products into comparable product segments
- Rank products within their respective subcategories
- Reduce misleading comparisons between functionally different products
- Add subcategory context to product sales and revenue analysis
- Compare profit and profit margin across product subcategories
- Measure each subcategory’s contribution to annual profit

**Data Quality Notes:**

- `SubCategoryKey` was checked for duplicate values during data profiling.
- No duplicate subcategory keys were identified.
- Subcategory-to-category relationships depend on matching
  `CategoryKey` values in `HMProductCategory`.

**Analysis Limitation:**

Products within the same subcategory may still differ in price,
specification, brand, type, or customer use. Therefore, belonging
to the same subcategory improves comparability but does not make
all products completely equivalent.

**Related Analyses:**

- Q7 — Top-selling products within each subcategory
- Q7.1 — Revenue position of the sales-volume leaders
- Q8 — Characteristics of the top-selling products
- Q11.2 — Profit contribution by product subcategory

## Table: HMStores

**Table Type:** Dimension Table

**Description:**

`HMStores` contains descriptive and geographic information about
the store locations associated with sales transactions.

It includes each store’s city, country, continent, and store type.

**Validated Candidate Key:**

- `StoreID`

The `StoreID` column contains unique values and can identify each
store record. However, no physical primary key constraint was
created during the original data import.

**Important Attributes:**

- `StoreID`
- `CityName`
- `CountryName`
- `Continent`
- `StoreType`

**Relationship:**

- `HMStores.StoreID` → `HMSales.StoreID`

One store can be associated with multiple sales records, while
each sales record contains one store identifier.

**Business Use:**

- Calculate annual revenue by store
- Rank stores based on total revenue
- Identify consistently high-performing stores
- Compare store rankings and revenue across years
- Identify stores entering or exiting the annual top 10
- Add city, country, continent, and store-type context to store analysis

**Data Quality Notes:**

- `StoreID` was checked for duplicate values during data profiling.
- No duplicate store identifiers were identified.
- Country names were standardized during data cleaning.
- The 79 missing `Continent` values were populated using the
  `Countries by Continents` reference table.
- Post-cleaning validation found no remaining missing or empty
  continent values.
- Some stores in the dimension table do not appear in `HMSales`
  and are therefore excluded from sales-performance rankings.

**Analysis Limitations:**

The dataset does not include store size, staffing, operating cost,
opening date, local market size, or inventory availability.
Therefore, differences in store revenue cannot be attributed to
specific operational factors without additional data.

**Related Analyses:**

- Q5 — Top 10 stores by revenue in 2006 and 2007
- Q5.1 — Revenue contribution of the top 10 stores
- Q6 — Stores appearing in the top 10 in both years
- Q6.1 — Stores entering or exiting the top 10

## Table: HMSales

**Table Type:** Fact Table

**Description:**

`HMSales` is the central fact table of the Heavy Machinery Sales
dataset. It contains transaction-level product sales records and
connects customers, products, stores, sales channels, employees,
and dates.

**Grain:**

One row represents one product line within a sales invoice.

A single invoice can contain multiple products and therefore may
appear in more than one row.

**Validated Composite Candidate Key:**

- `Invoice`
- `ProductKey`

The combination of `Invoice` and `ProductKey` was validated as
unique in the available dataset. However, no physical composite
primary key constraint was created during the original data import.

**Business Foreign Keys:**

- `CustomerKey` → `HMCustomers.CustomerKey`
- `ProductKey` → `HMProducts.ProductKey`
- `StoreID` → `HMStores.StoreID`
- `ChannelKey` → `HMChannel.ChannelKey`
- `TransactionDate` → `HMCalendar.Date`
- `DeliveryDate` → `HMCalendar.Date`

These relationships are used logically throughout the analysis,
although physical foreign key constraints were not created during
the original data import.

**Important Attributes:**

- `Invoice`
- `TransactionDate`
- `DeliveryDate`
- `EmpKey`
- `ChannelKey`
- `StoreID`
- `ProductKey`
- `CustomerKey`
- `Qty`
- `Cost`
- `Price`
- `Revenue`

**Measures and Calculations:**

- Quantity Sold = `Qty`
- Unit Selling Price = `Price`
- Unit Cost = `Cost`
- Revenue = `Qty × Price`
- Total Cost = `Qty × Cost`
- Profit = `Qty × (Price - Cost)`
- Profit Margin (%) = `Profit ÷ Revenue × 100`

`Revenue` is available in the current database as a computed
column. Total Cost, Profit, and Profit Margin are calculated
within the analytical queries.

**Relationships:**

- One customer can be associated with multiple sales records.
- One product can appear in multiple sales records.
- One store can be associated with multiple sales records.
- One channel can be associated with multiple sales records.
- One calendar date can be associated with multiple transaction
  or delivery records.

**Business Use:**

- Analyze revenue, cost, profit, and quantity sold
- Measure customer spending and revenue concentration
- Evaluate store, product, channel, country, and employee performance
- Analyze annual and monthly sales trends
- Identify high-performing products and product subcategories
- Compare order volume with financial performance

**Data Quality Notes:**

- `Invoice` alone is not unique.
- The combination of `Invoice` and `ProductKey` returned no duplicates.
- `Qty`, `Price`, and `Cost` passed the implemented numeric validation rules.
- No records were found where `DeliveryDate` occurred before
  `TransactionDate`.
- Large revenue aggregations are converted to `bigint` in the
  analytical queries to reduce overflow risk.

**Analysis Limitations:**

- No employee dimension table is available; employees can only
  be identified by `EmpKey`.
- The available fields do not provide employee name, territory,
  role, or compensation information.
- Revenue represents recorded product sales and does not by
  itself measure marketing return, customer satisfaction, or
  store operating efficiency.
- The candidate and foreign key relationships are logically
  validated but are not enforced through database constraints.

**Related Analyses:**

- Q1 — Identification of the sales-table grain and candidate key
- Q2–Q2.3 — Time and revenue analysis
- Q3–Q4.1 — Customer and industry analysis
- Q5–Q6.1 — Store performance analysis
- Q7–Q8 — Product performance analysis
- Q9–Q10.1 — Sales-channel analysis
- Q11–Q11.2 — Profit analysis
- Q12–Q12.1 — Country-level customer analysis
- Q13–Q14.1 — Employee performance analysis

## Table: Countries by Continents

**Table Type:** Reference Table

**Description:**

`Countries by Continents` contains a standardized mapping between
country names and their corresponding continents.

It is used as a geographic reference during data cleaning and
validation rather than as a direct transactional dimension.

**Validated Candidate Key:**

- `Country`

The `Country` column was checked for duplicate values and can
identify each country record in the available reference table.
However, no physical primary key constraint was created during
the original data import.

**Important Attributes:**

- `Country`
- `Continent`

**Relationship Usage:**

- `Countries by Continents.Country`
  → `HMCustomers.Country`
- `Countries by Continents.Country`
  → `HMStores.CountryName`

These relationships are used during data cleaning and validation.
The reference table is not directly connected to `HMSales`.

**Business Use:**

- Standardize country names across source tables
- Identify non-matching or non-standard country values
- Populate missing continent values in `HMStores`
- Validate geographic consistency between customers, stores,
  countries, and continents
- Support reliable country- and continent-level analysis

**Data Quality Notes:**

- The first imported row incorrectly contained the original
  column headers as data.
- The imported columns were renamed to `Continent` and `Country`.
- The incorrectly imported header row was removed.
- `Country` was checked for duplicate values during data profiling.
- Non-standard country names in `HMCustomers` and `HMStores`
  were updated to match this reference table.
- The reference table was used to populate 79 missing continent
  values in `HMStores`.

**Country Name Standardization:**

| Original Value | Standardized Value |
|---|---|
| `Holland` | `Netherlands` |
| `NewZealand` | `New Zealand` |
| `SouthAfrica` | `South Africa` |
| `SouthKorea` | `South Korea` |
| `UAE` | `United Arab Emirates` |
| `UK` | `United Kingdom` |
| `US` | `United States` |

**Analysis Limitation:**

This table is used as a reference for geographic standardization.
It does not contain sales measures and should not be analyzed as
a transaction or customer dimension.

**Related Project Stages:**

- Data profiling — Duplicate and country-value validation
- Data cleaning — Country-name standardization
- Data cleaning — Population of missing store continents
- Business analysis — Support for consistent geographic reporting

