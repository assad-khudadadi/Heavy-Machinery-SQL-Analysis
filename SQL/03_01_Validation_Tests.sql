/*==============================================================
 Heavy Machinery Sales Analysis - Validation Tests
==============================================================
Purpose:
Report one Pass/Fail and IssueCount per documented data rule.
Run in the imported project database after 03_Data_Cleaning.sql.
SQL Server 2017+ (same baseline as the profiling script).

Read-only source validation; only session-local temporary tables
are written. No database constraints are created or assumed.
Counts are rows except uniqueness counts (duplicate key groups)
and empty-table guards (0 or 1). Counts overlap; do not sum them.
NULL references are separate completeness tests, never orphans.
Country checks use native SQL equality/collation without trimming
or normalization; use profiling for blank strings and spaces.
Date joins use exact equality, without casting away time values.
Run against a stable dataset; separate queries do not guarantee a
single consistent snapshot while imports or updates are running.

A query error returns Fail with NULL IssueCount and ErrorMessage:
the test did not run, and must never be interpreted as zero issues.
A Pass describes current data only, not future enforcement.
==============================================================*/

set nocount on;

drop table if exists #ValidationTests;
drop table if exists #ValidationResults;

create table #ValidationTests
(
    TestID int primary key,
    TestName nvarchar(200),
    TestSQL nvarchar(max),
    CountUnit nvarchar(200)
);

create table #ValidationResults
(
    TestID int,
    TestName nvarchar(200),
    Status varchar(4),
    IssueCount bigint null,
    CountUnit nvarchar(200),
    ErrorMessage nvarchar(4000) null
);

/*==============================================================
  1. Explicit documented test inventory
==============================================================*/

insert into #ValidationTests (TestID, TestName, TestSQL, CountUnit)
values
    (1, N'HMSales has rows', N'select @IssueCount = case when exists (select 1 from dbo.[HMSales]) then 0 else 1 end;', N'Empty table (0 or 1)'),
    (2, N'HMCustomers has rows', N'select @IssueCount = case when exists (select 1 from dbo.[HMCustomers]) then 0 else 1 end;', N'Empty table (0 or 1)'),
    (3, N'HMProducts has rows', N'select @IssueCount = case when exists (select 1 from dbo.[HMProducts]) then 0 else 1 end;', N'Empty table (0 or 1)'),
    (4, N'HMProductCategory has rows', N'select @IssueCount = case when exists (select 1 from dbo.[HMProductCategory]) then 0 else 1 end;', N'Empty table (0 or 1)'),
    (5, N'HMProductSubCategory has rows', N'select @IssueCount = case when exists (select 1 from dbo.[HMProductSubCategory]) then 0 else 1 end;', N'Empty table (0 or 1)'),
    (6, N'HMChannel has rows', N'select @IssueCount = case when exists (select 1 from dbo.[HMChannel]) then 0 else 1 end;', N'Empty table (0 or 1)'),
    (7, N'HMStores has rows', N'select @IssueCount = case when exists (select 1 from dbo.[HMStores]) then 0 else 1 end;', N'Empty table (0 or 1)'),
    (8, N'HMCalendar has rows', N'select @IssueCount = case when exists (select 1 from dbo.[HMCalendar]) then 0 else 1 end;', N'Empty table (0 or 1)'),
    (9, N'Countries by Continents has rows', N'select @IssueCount = case when exists (select 1 from dbo.[Countries by Continents]) then 0 else 1 end;', N'Empty table (0 or 1)'),
    (10, N'HMCustomers.CustomerKey missing', N'select @IssueCount = count_big(*) from dbo.[HMCustomers] where [CustomerKey] is null;', N'Rows with NULL candidate key'),
    (11, N'HMCustomers.CustomerKey uniqueness', N'select @IssueCount = count_big(*) from (select [CustomerKey] from dbo.[HMCustomers] where [CustomerKey] is not null group by [CustomerKey] having count_big(*) > 1) as d;', N'Duplicate non-NULL key groups'),
    (12, N'HMProducts.ProductKey missing', N'select @IssueCount = count_big(*) from dbo.[HMProducts] where [ProductKey] is null;', N'Rows with NULL candidate key'),
    (13, N'HMProducts.ProductKey uniqueness', N'select @IssueCount = count_big(*) from (select [ProductKey] from dbo.[HMProducts] where [ProductKey] is not null group by [ProductKey] having count_big(*) > 1) as d;', N'Duplicate non-NULL key groups'),
    (14, N'HMProductCategory.CategoryKey missing', N'select @IssueCount = count_big(*) from dbo.[HMProductCategory] where [CategoryKey] is null;', N'Rows with NULL candidate key'),
    (15, N'HMProductCategory.CategoryKey uniqueness', N'select @IssueCount = count_big(*) from (select [CategoryKey] from dbo.[HMProductCategory] where [CategoryKey] is not null group by [CategoryKey] having count_big(*) > 1) as d;', N'Duplicate non-NULL key groups'),
    (16, N'HMProductSubCategory.SubCategoryKey missing', N'select @IssueCount = count_big(*) from dbo.[HMProductSubCategory] where [SubCategoryKey] is null;', N'Rows with NULL candidate key'),
    (17, N'HMProductSubCategory.SubCategoryKey uniqueness', N'select @IssueCount = count_big(*) from (select [SubCategoryKey] from dbo.[HMProductSubCategory] where [SubCategoryKey] is not null group by [SubCategoryKey] having count_big(*) > 1) as d;', N'Duplicate non-NULL key groups'),
    (18, N'HMChannel.ChannelKey missing', N'select @IssueCount = count_big(*) from dbo.[HMChannel] where [ChannelKey] is null;', N'Rows with NULL candidate key'),
    (19, N'HMChannel.ChannelKey uniqueness', N'select @IssueCount = count_big(*) from (select [ChannelKey] from dbo.[HMChannel] where [ChannelKey] is not null group by [ChannelKey] having count_big(*) > 1) as d;', N'Duplicate non-NULL key groups'),
    (20, N'HMStores.StoreID missing', N'select @IssueCount = count_big(*) from dbo.[HMStores] where [StoreID] is null;', N'Rows with NULL candidate key'),
    (21, N'HMStores.StoreID uniqueness', N'select @IssueCount = count_big(*) from (select [StoreID] from dbo.[HMStores] where [StoreID] is not null group by [StoreID] having count_big(*) > 1) as d;', N'Duplicate non-NULL key groups'),
    (22, N'HMCalendar.Date missing', N'select @IssueCount = count_big(*) from dbo.[HMCalendar] where [Date] is null;', N'Rows with NULL candidate key'),
    (23, N'HMCalendar.Date uniqueness', N'select @IssueCount = count_big(*) from (select [Date] from dbo.[HMCalendar] where [Date] is not null group by [Date] having count_big(*) > 1) as d;', N'Duplicate non-NULL key groups'),
    (24, N'Countries by Continents.Country missing', N'select @IssueCount = count_big(*) from dbo.[Countries by Continents] where [Country] is null;', N'Rows with NULL candidate key'),
    (25, N'Countries by Continents.Country uniqueness', N'select @IssueCount = count_big(*) from (select [Country] from dbo.[Countries by Continents] where [Country] is not null group by [Country] having count_big(*) > 1) as d;', N'Duplicate non-NULL key groups'),
    (26, N'HMSales.CustomerKey missing reference', N'select @IssueCount = count_big(*) from dbo.[HMSales] where [CustomerKey] is null;', N'Rows with NULL reference; completeness check, not orphan'),
    (27, N'HMSales.CustomerKey -> HMCustomers.CustomerKey', N'select @IssueCount = count_big(*) from dbo.[HMSales] as c where c.[CustomerKey] is not null and not exists (select 1 from dbo.[HMCustomers] as p where p.[CustomerKey] = c.[CustomerKey]);', N'Non-NULL child rows without matching parent'),
    (28, N'HMSales.ProductKey missing reference', N'select @IssueCount = count_big(*) from dbo.[HMSales] where [ProductKey] is null;', N'Rows with NULL reference; completeness check, not orphan'),
    (29, N'HMSales.ProductKey -> HMProducts.ProductKey', N'select @IssueCount = count_big(*) from dbo.[HMSales] as c where c.[ProductKey] is not null and not exists (select 1 from dbo.[HMProducts] as p where p.[ProductKey] = c.[ProductKey]);', N'Non-NULL child rows without matching parent'),
    (30, N'HMSales.StoreID missing reference', N'select @IssueCount = count_big(*) from dbo.[HMSales] where [StoreID] is null;', N'Rows with NULL reference; completeness check, not orphan'),
    (31, N'HMSales.StoreID -> HMStores.StoreID', N'select @IssueCount = count_big(*) from dbo.[HMSales] as c where c.[StoreID] is not null and not exists (select 1 from dbo.[HMStores] as p where p.[StoreID] = c.[StoreID]);', N'Non-NULL child rows without matching parent'),
    (32, N'HMSales.ChannelKey missing reference', N'select @IssueCount = count_big(*) from dbo.[HMSales] where [ChannelKey] is null;', N'Rows with NULL reference; completeness check, not orphan'),
    (33, N'HMSales.ChannelKey -> HMChannel.ChannelKey', N'select @IssueCount = count_big(*) from dbo.[HMSales] as c where c.[ChannelKey] is not null and not exists (select 1 from dbo.[HMChannel] as p where p.[ChannelKey] = c.[ChannelKey]);', N'Non-NULL child rows without matching parent'),
    (34, N'HMSales.TransactionDate missing reference', N'select @IssueCount = count_big(*) from dbo.[HMSales] where [TransactionDate] is null;', N'Rows with NULL reference; completeness check, not orphan'),
    (35, N'HMSales.TransactionDate -> HMCalendar.Date', N'select @IssueCount = count_big(*) from dbo.[HMSales] as c where c.[TransactionDate] is not null and not exists (select 1 from dbo.[HMCalendar] as p where p.[Date] = c.[TransactionDate]);', N'Non-NULL child rows without matching parent'),
    (36, N'HMSales.DeliveryDate missing reference', N'select @IssueCount = count_big(*) from dbo.[HMSales] where [DeliveryDate] is null;', N'Rows with NULL reference; completeness check, not orphan'),
    (37, N'HMSales.DeliveryDate -> HMCalendar.Date', N'select @IssueCount = count_big(*) from dbo.[HMSales] as c where c.[DeliveryDate] is not null and not exists (select 1 from dbo.[HMCalendar] as p where p.[Date] = c.[DeliveryDate]);', N'Non-NULL child rows without matching parent'),
    (38, N'HMProducts.SubCategoryKey missing reference', N'select @IssueCount = count_big(*) from dbo.[HMProducts] where [SubCategoryKey] is null;', N'Rows with NULL reference; completeness check, not orphan'),
    (39, N'HMProducts.SubCategoryKey -> HMProductSubCategory.SubCategoryKey', N'select @IssueCount = count_big(*) from dbo.[HMProducts] as c where c.[SubCategoryKey] is not null and not exists (select 1 from dbo.[HMProductSubCategory] as p where p.[SubCategoryKey] = c.[SubCategoryKey]);', N'Non-NULL child rows without matching parent'),
    (40, N'HMProductSubCategory.CategoryKey missing reference', N'select @IssueCount = count_big(*) from dbo.[HMProductSubCategory] where [CategoryKey] is null;', N'Rows with NULL reference; completeness check, not orphan'),
    (41, N'HMProductSubCategory.CategoryKey -> HMProductCategory.CategoryKey', N'select @IssueCount = count_big(*) from dbo.[HMProductSubCategory] as c where c.[CategoryKey] is not null and not exists (select 1 from dbo.[HMProductCategory] as p where p.[CategoryKey] = c.[CategoryKey]);', N'Non-NULL child rows without matching parent'),
    (42, N'HMCustomers.Country missing reference', N'select @IssueCount = count_big(*) from dbo.[HMCustomers] where [Country] is null;', N'Rows with NULL reference; completeness check, not orphan'),
    (43, N'HMCustomers.Country -> Countries by Continents.Country', N'select @IssueCount = count_big(*) from dbo.[HMCustomers] as c where c.[Country] is not null and not exists (select 1 from dbo.[Countries by Continents] as p where p.[Country] = c.[Country]);', N'Non-NULL child rows without matching parent'),
    (44, N'HMStores.CountryName missing reference', N'select @IssueCount = count_big(*) from dbo.[HMStores] where [CountryName] is null;', N'Rows with NULL reference; completeness check, not orphan'),
    (45, N'HMStores.CountryName -> Countries by Continents.Country', N'select @IssueCount = count_big(*) from dbo.[HMStores] as c where c.[CountryName] is not null and not exists (select 1 from dbo.[Countries by Continents] as p where p.[Country] = c.[CountryName]);', N'Non-NULL child rows without matching parent'),
    (46, N'HMSales Invoice-ProductKey missing', N'select @IssueCount = count_big(*) from dbo.HMSales where Invoice is null or ProductKey is null;', N'Rows with incomplete composite key'),
    (47, N'HMSales Invoice-ProductKey duplicates', N'select @IssueCount = count_big(*) from (select Invoice, ProductKey from dbo.HMSales where Invoice is not null and ProductKey is not null group by Invoice, ProductKey having count_big(*) > 1) as d;', N'Duplicate complete composite-key groups'),
    (48, N'HMSales Qty missing', N'select @IssueCount = count_big(*) from dbo.HMSales where [Qty] is null;', N'Rows with NULL numeric value'),
    (49, N'HMSales Qty <= 0', N'select @IssueCount = count_big(*) from dbo.HMSales where [Qty] <= 0;', N'Rows violating documented numeric rule'),
    (50, N'HMSales Price missing', N'select @IssueCount = count_big(*) from dbo.HMSales where [Price] is null;', N'Rows with NULL numeric value'),
    (51, N'HMSales Price <= 0', N'select @IssueCount = count_big(*) from dbo.HMSales where [Price] <= 0;', N'Rows violating documented numeric rule'),
    (52, N'HMSales Cost missing', N'select @IssueCount = count_big(*) from dbo.HMSales where [Cost] is null;', N'Rows with NULL numeric value'),
    (53, N'HMSales Cost < 0', N'select @IssueCount = count_big(*) from dbo.HMSales where [Cost] < 0;', N'Rows violating documented numeric rule'),
    (54, N'HMSales delivery before transaction', N'select @IssueCount = count_big(*) from dbo.HMSales where DeliveryDate < TransactionDate;', N'Rows with DeliveryDate < TransactionDate; NULLs checked separately');

/*==============================================================
  2. Execute independently; preserve errors instead of false Pass
==============================================================*/

declare @TestID int = 1,
        @TestCount int = (select count(*) from #ValidationTests),
        @TestName nvarchar(200),
        @TestSQL nvarchar(max),
        @CountUnit nvarchar(200),
        @IssueCount bigint;

while @TestID <= @TestCount
begin
    select @TestName = TestName, @TestSQL = TestSQL,
           @CountUnit = CountUnit
    from #ValidationTests where TestID = @TestID;
    set @IssueCount = null;

    begin try
        exec sys.sp_executesql @TestSQL,
            N'@IssueCount bigint output', @IssueCount output;
        insert into #ValidationResults
        values (@TestID, @TestName,
                case when @IssueCount = 0 then 'Pass' else 'Fail' end,
                @IssueCount, @CountUnit, null);
    end try
    begin catch
        insert into #ValidationResults
        values (@TestID, @TestName, 'Fail', null, @CountUnit,
                error_message());
    end catch;

    set @TestID = @TestID + 1;
end;

select TestID, TestName, Status, IssueCount, CountUnit, ErrorMessage
from #ValidationResults
order by TestID;

/*==============================================================
  3. Separate unproven properties (not data-test failures)
==============================================================*/

select Property, Assessment, Reason
from (values
    (N'Future PK/FK enforcement', N'Not proven',
     N'Current data checks cannot enforce later writes; source tables lack physical PK/FK constraints.'),
    (N'EmpKey referential integrity', N'Not testable',
     N'No employee dimension or documented parent key is available.'),
    (N'Required versus optional references', N'Not documented',
     N'NULL checks report completeness issues; business approval is needed to define optional references.'),
    (N'Permanent Invoice-ProductKey business grain', N'Not proven',
     N'Uniqueness in this dataset does not establish whether repeated product lines are allowed in future invoices.'),
    (N'Country matching semantics', N'Not documented',
     N'Checks use database equality/collation; case, accents, aliases and whitespace rules need explicit business documentation.')
) as limitations (Property, Assessment, Reason);

/*==============================================================
  End of 03_01_Validation_Tests.sql
==============================================================*/

set nocount off;
