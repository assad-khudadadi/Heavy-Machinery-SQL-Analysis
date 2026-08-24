/*==============================================================
  Heavy Machinery Sales Analysis
  File: 04_01_Dataset_Exploration.sql
  Section: Dataset Exploration and Key Identification
==============================================================

Purpose:
Explore the cleaned dataset, review its size and date coverage,
identify the main business entities, and determine the appropriate
unique key for the HMSales table.

Execution Order:
Run this script after completing:
- 02_Data_Profiling.sql
- 03_Data_Cleaning.sql

Important:
This script is read-only and does not modify the source data.
==============================================================*/

set nocount on;

/*==============================================================
  E1. Table Preview
  --------------------------------------------------------------
  Preview a small sample from each table to understand the
  available columns and general structure of the dataset.
==============================================================*/

select top (10) *
from dbo.HMSales;

select top (10) *
from dbo.HMCustomers;

select top (10) *
from dbo.HMProducts;

select top (10) *
from dbo.HMProductCategory;

select top (10) *
from dbo.HMProductSubcategory;

select top (10) *
from dbo.HMStores;

select top (10) *
from dbo.HMChannel;

select top (10) *
from dbo.HMCalendar;

select top (10) *
from dbo.[Countries by continents];

/*==============================================================
  E2. Dataset Size
  --------------------------------------------------------------
  Determine the number of records available in each table.
==============================================================*/

select
    TableName,
    RecordCount
from
(
    select
        1 as TableOrder,
        'HMSales' as TableName,
        count_big(*) as RecordCount
    from dbo.HMSales

    union all

    select 2, 'HMCustomers', count_big(*)
    from dbo.HMCustomers

    union all

    select 3, 'HMProducts', count_big(*)
    from dbo.HMProducts

    union all

    select 4, 'HMProductCategory', count_big(*)
    from dbo.HMProductCategory

    union all

    select 5, 'HMProductSubcategory', count_big(*)
    from dbo.HMProductSubcategory

    union all

    select 6, 'HMStores', count_big(*)
    from dbo.HMStores

    union all

    select 7, 'HMChannel', count_big(*)
    from dbo.HMChannel

    union all

    select 8, 'HMCalendar', count_big(*)
    from dbo.HMCalendar

    union all

    select 9, 'Countries by continents', count_big(*)
    from dbo.[Countries by continents]
) as DatasetSize
order by TableOrder;

/*==============================================================
  E3. Dataset Time Range
  --------------------------------------------------------------
  Identify the available time period covered by transaction
  and delivery dates in the sales table.
==============================================================*/

select
    'TransactionDate' as DateColumn,
    cast(min(TransactionDate) as date) as FirstDate,
    cast(max(TransactionDate) as date) as LastDate
from dbo.HMSales

union all

select
    'DeliveryDate',
    cast(min(DeliveryDate) as date),
    cast(max(DeliveryDate) as date)
from dbo.HMSales;

/*==============================================================
  E4. Active Business Entities
  --------------------------------------------------------------
  Count the distinct business entities represented in the
  HMSales table.
==============================================================*/

select
    count(distinct CustomerKey) as ActiveCustomers,
    count(distinct ProductKey)  as ActiveProducts,
    count(distinct StoreID)     as ActiveStores,
    count(distinct ChannelKey)  as ActiveChannels,
    count(distinct EmpKey)      as ActiveEmployees,
    count(distinct Invoice)     as TotalInvoices
from dbo.HMSales;

/*==============================================================
  E5. Dimension Coverage in Sales
  --------------------------------------------------------------
  Compare the total number of entities in the dimension tables
  with the number represented in HMSales.
==============================================================*/

;with EntityCoverage as
(
    select
        1 as EntityOrder,
        'Customers' as EntityName,
        count_big(*) as TotalEntities,
        (
            select count_big(distinct CustomerKey)
            from dbo.HMSales
        ) as ActiveEntities
    from dbo.HMCustomers

    union all

    select
        2,
        'Products',
        count_big(*),
        (
            select count_big(distinct ProductKey)
            from dbo.HMSales
        )
    from dbo.HMProducts

    union all

    select
        3,
        'Stores',
        count_big(*),
        (
            select count_big(distinct StoreID)
            from dbo.HMSales
        )
    from dbo.HMStores

    union all

    select
        4,
        'Channels',
        count_big(*),
        (
            select count_big(distinct ChannelKey)
            from dbo.HMSales
        )
    from dbo.HMChannel
)
select
    EntityName,
    TotalEntities,
    ActiveEntities,
    TotalEntities - ActiveEntities as InactiveEntities,
    cast(
        ActiveEntities * 100.0 / nullif(TotalEntities, 0)
        as decimal(5, 2)
    ) as CoveragePercent
from EntityCoverage
order by EntityOrder;

/*==============================================================
  Exploration Note
  --------------------------------------------------------------
  Some dimension records do not appear in HMSales. These records
  may represent inactive entities or incomplete source data.

  Their business status should be confirmed with stakeholders
  before they are formally classified as inactive.
==============================================================*/


/*==============================================================
  Q1. Identify the Unique Key of HMSales
  --------------------------------------------------------------
  Determine whether Invoice alone, or a combination of columns,
  can uniquely identify each sales record.
==============================================================*/

-- Compare the total number of rows with distinct invoices.
select
    count_big(*) as TotalRows,
    count_big(distinct Invoice) as DistinctInvoices,
    count_big(*) - count_big(distinct Invoice)
        as AdditionalProductLines
from dbo.HMSales;


-- Display invoices containing more than one product line.
select
    Invoice,
    count_big(*) as ProductLineCount
from dbo.HMSales
group by Invoice
having count_big(*) > 1
order by ProductLineCount desc, Invoice;


-- Test Invoice and ProductKey as a candidate composite key.
select
    Invoice,
    ProductKey,
    count_big(*) as DuplicateCount
from dbo.HMSales
group by
    Invoice,
    ProductKey
having count_big(*) > 1;


/*==============================================================
  Q1 Result
  --------------------------------------------------------------
  Invoice alone is not unique because some invoices contain
  more than one product line.

  The combination of Invoice and ProductKey produces no duplicate
  combinations and can therefore be used as a candidate composite
  key for HMSales.
==============================================================*/

/*==============================================================
  Result Summary
  --------------------------------------------------------------

  Dataset Size:
  - HMSales contains 806,485 sales records.
  - The dataset includes 4,528 customers, 243 products,
    87 stores, 10 sales channels, and 4,383 calendar dates.
  - Product reference data includes 6 categories and
    21 subcategories.
  - The country reference table contains 196 countries.

  Time Coverage:
  - Transaction dates range from 2002-01-01 to 2013-01-02.
  - Delivery dates range from 2002-01-05 to 2013-02-01.

  Entity Coverage:
  - 3,939 of 4,528 customers appear in HMSales, representing
    86.99% customer coverage.
  - 589 customers do not appear in the sales records.
  - All 243 products and all 10 channels appear in HMSales.
  - 83 of 87 stores appear in HMSales, representing 95.40%
    store coverage.
  - Four stores do not appear in the sales records.
  - The sales table includes 15 distinct employees.

  Unique-Key Analysis:
  - HMSales contains 806,485 rows and 806,311 distinct invoices.
  - The difference of 174 represents additional product lines
    beyond one row per distinct invoice; it does not represent
    174 duplicate invoices.
  - Some invoices contain multiple product lines. The largest,
    invoice E1514517, contains 16 product lines.
  - No duplicate Invoice and ProductKey combinations were found.
  - Therefore, Invoice and ProductKey can be treated as a
    candidate composite key for the current dataset.

  Business Interpretation:
  - Products and sales channels have complete representation
    in HMSales.
  - Customers and stores that do not appear in HMSales may be
    inactive or may reflect incomplete source data. Their status
    should be confirmed with business stakeholders before making
    a final classification.
==============================================================*/

/*==============================================================
  End of 04_01_Dataset_Exploration.sql
==============================================================*/

set nocount off;